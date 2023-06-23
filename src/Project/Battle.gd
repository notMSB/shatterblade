extends Node2D

export (PackedScene) var Player
export (PackedScene) var Enemy
export (PackedScene) var LogEntry

onready var Moves = get_node("/root/Game/Data/Moves")
onready var StatusManager = get_node("/root/Game/Data/StatusManager")
onready var Enemies = get_node("/root/Game/Data/Enemies")
onready var Formations = get_node("/root/Game/Data/Formations")
onready var Boons = get_node("/root/Game/Data/Boons")
onready var Animations = get_node("/root/Game/Data/Animations")

var Map

var useAnimations = true
enum scope {single, players, enemies, all}

var enemyNum = 0
var deadEnemies = 0
var previewDeadEnemies = 0

const apIncrement = 20

signal turn_taken

var turnIndex = -1
var turnCount = 0

var currentUnit
var menuNode

var chosenMove
var moveName
var moveUser
var usedMoveBox
var moveTarget
var damageCalc
var damageBuff
var info
var hits
var hitBonus = 0
var logIndex = 0

var virtueCost = 5
var virtueUsed = false
var virtueMove = ""

var bossFight = false
var gameOver = false
var battleDone = true
var previewBattleDone = false
var autoPreview = true
var lockPreview = false
var levelLock = false
var doubleXP = false
var canSee = true
var enemyBonus = false
var currentLevel = 0

var executionOrder = [] #box, move, user, target
enum e {box, move, user, target}
var targetType

enum a {xpGain, useDeducted, hitBonus, damageBuff, turnStart, battleStart}

var drag = false
var undrag = null

func _ready(): #Generate units and add to turn order
	Moves.Battle = self
	StatusManager.Battle = self
	#if !get_parent().mapMode: battleDone = false
	targetType = Moves.targetType
	randomize() #funny rng

func setup_virtue():
	$Virtue.setup_virtue()
	match Boons.chosen:
		Boons.v.j: virtueMove = "Justice"
		Boons.v.s: virtueMove = "Strength"
		Boons.v.t: virtueMove = "Temperance"

func check_undrag(box): #when the mouse leaves a box
	if box == usedMoveBox: undrag = box

func check_drag(targetButton): #dragging a box onto a button
	if drag: 
		targetButton._on_Button_pressed()
		undrag = null
		drag = false
		#Input.set_custom_mouse_cursor(null)

func _process(_delta):
	if visible and Input.is_action_just_released("left_click"): 
		drag = false
		if undrag != null: 
			if undrag == usedMoveBox: undrag._on_Button_pressed()
			undrag = null
		#Input.set_custom_mouse_cursor(null)

func setup_party():
	$BattleUI.set_holder()
	for i in global.storedParty.size():
		var createdUnit = setup_player(i)
		StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
	for unit in $Units.get_children():
		$BattleUI.setup_display(unit)

func setup_player(index, setDisplay = false):
	var createdUnit = Player.instance()
	if global.storedParty.size() <= index:
		createdUnit.make_stats(40)
	else:
		createdUnit = global.storedParty[index]
	createdUnit.name = str("P", String(index))
	createdUnit.battleName = str("P", String(index))
	if setDisplay:
		StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
		$BattleUI.setup_display(createdUnit, 0)
	return createdUnit

func create_enemies(enemyDifficulty, opponents):
	var createdUnit
	var enemy
	var i = 0
	if get_parent().hardMode and get_parent().mapMode: enemyDifficulty += 1
	for opponent in opponents:
		createdUnit = Enemy.instance()
		enemy = Enemies.enemyList[opponent]
		
		if enemyBonus: createdUnit.make_stats(enemy["stats"][enemyDifficulty] + currentLevel)
		else: createdUnit.make_stats(enemy["stats"][enemyDifficulty])
		createdUnit.identity = opponent
		createdUnit.spriteBase = enemy["sprite"]
		createdUnit.battleName = str(createdUnit.identity, " ", String(i))
		createdUnit.displayName = createdUnit.battleName
		if enemy.has("passives"): createdUnit.passives = enemy["passives"]
		if enemy.has("specials"): 
			createdUnit.moves = enemy["specials"]
			createdUnit.allMoves.append_array(createdUnit.moves)
		StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
		$BattleUI.setup_display(createdUnit, opponents.size())
		set_intent(createdUnit)
		if createdUnit.passives.size() > 0:
			for passive in createdUnit.passives:
				StatusManager.add_status(createdUnit, passive, createdUnit.passives[passive])
		i+=1
	enemyNum = opponents.size()
	yield(get_tree().create_timer(0), "timeout")

func set_map():
	Map = get_node("../Map")

func toggle_blind(toggle, checkPreview = true):
	for enemy in get_team(false):
		enemy.ui.get_node("Info").visible = toggle
		enemy.ui.get_node("MoveBox").visible = toggle
	if checkPreview:
		if autoPreview != toggle: _on_Preview_pressed()
		$Preview.visible = toggle
		$Peek.visible = !toggle

func welcome_back(newOpponents = null, currentArea = 0): #reusing an existing battle scene for a new battle
	if !Map: $Lock.visible = false
	virtueUsed = false
	$Pray.disabled = check_prayer()
	$BattleUI.toggle_trackers(true)
	turnCount = 0
	$BattleUI.enemyCount = 0
	battleDone = false
	previewBattleDone = false
	for unit in $Units.get_children():
		if !unit.isPlayer:
			unit.cease_to_exist()
		else:
			set_ui(unit, true)
	turnIndex = -1
	Boons.call_boon("start_battle", [get_partyHealth(), self])
	yield(create_enemies(currentArea, newOpponents), "completed")
	evaluate_aura(a.battleStart)
	if !canSee: toggle_blind(false)
	if autoPreview: toggle_previews(true)
	play_turn(false)

func set_ui(unit, setPassives = false):
	unit.strength = unit.startingStrength
	unit.ap = unit.baseAP
	unit.energy = unit.maxEnergy
	unit.statuses.clear()
	StatusManager.initialize_statuses(unit)
	unit.update_box_bars()
	unit.update_strength()
	if battleDone: unit.shield = 0
	if setPassives:
		unit.currentHealth = min(unit.currentHealth + unit.baseHealing, unit.maxHealth)
		for passive in unit.passives:
			if passive == "Status Soak": assess_status_soak(unit)
			else: StatusManager.add_status(unit, passive, unit.passives[passive])
	unit.update_hp()
	unit.update_status_ui()

func assess_status_soak(unit):
	var soaks = 0
	for i in unit.boxHolder.get_child_count():
		if i == 0 or i == 1:
			var box = unit.boxHolder.get_child(i)
			if box.moves[0] == "Grim Portrait" and box.currentUses > 0: soaks += box.currentUses
		else: break
	StatusManager.add_status(unit, "Status Soak", soaks)

func get_partyHealth():
	var total = 0
	for unit in global.storedParty:
		total += unit.currentHealth
	return total

func check_prayer():
	if Boons.favor < virtueCost or virtueUsed: return true
	else: return false

func evaluate_aura(activationTiming):
	if !Map: return 0
	if activationTiming == a.battleStart:
		if Map.currentBiome == Map.biomesList.mountain:
			for unit in $Units.get_children():
				StatusManager.add_status(unit, "Resist", 1)
	elif activationTiming == a.turnStart:
		if Map.currentBiome == Map.biomesList.forest:
			for unit in $Units.get_children():
				if unit.currentHealth == unit.maxHealth: 
					unit.shield += 5
					unit.update_hp()
	elif activationTiming == a.hitBonus:
		if Map.currentBiome == Map.biomesList.battlefield and chosenMove.has("hits"): if chosenMove["hits"] > 1: return 1
		return 0
	elif activationTiming == a.damageBuff:
		if Map.currentBiome == Map.biomesList.city:
			if chosenMove["target"] == Moves.targetType.enemy or chosenMove["target"] == Moves.targetType.ally or chosenMove["target"] == Moves.targetType.user: return 2
			else: return -2
		return 0
	elif activationTiming == a.useDeducted:
		if Map.currentBiome == Map.biomesList.graveyard: return 1
		else: return 0
	elif activationTiming == a.xpGain:
		if Map.currentBiome == Map.biomesList.graveyard: return 1
		else: return 0

func play_turn(notFirstTurn = true):
	if battleDone:
		if gameOver: return get_tree().change_scene("res://src/Project/Lose.tscn")
		var rewards = []
		for enemy in get_team(false):
			if Enemies.enemyList[enemy.identity].has("elite"): rewards.append("Health Potion")
		return done(rewards)
	turnIndex = (turnIndex + 1) % $Units.get_child_count() #Advance to next unit
	currentUnit = $Units.get_child(turnIndex)
	if turnIndex == 0: #Start of turn, take player actions
		if !$Preview.visible:
			canSee = false
			toggle_blind(false)
		if canSee:
			for enemy in get_team(false):
				enemy.ui.get_node("Info").visible = true
				enemy.ui.get_node("MoveBox").visible = true
		lockPreview = true
		usedMoveBox = null
		if notFirstTurn and get_parent().mapMode: get_node("../Map").subtract_time(1)
		turnCount+=1
		for unit in $Units.get_children():
			unit.update_strength(notFirstTurn)
			unit.isStunned = false
			if unit.isPlayer:
				if notFirstTurn:
					unit.shield = 0
					unit.update_hp()
				StatusManager.evaluate_statuses(unit, StatusManager.statusActivations.beforeTurn)
				StatusManager.countdown_turns(unit, true)
				unit.update_resource(apIncrement, Moves.moveType.special, true)
				unit.update_resource(unit.maxEnergy, Moves.moveType.trick, true)
				if unit.isStunned or unit.currentHealth <= 0:
					$BattleUI.toggle_moveboxes(unit.boxHolder, false, false, false, true)
				else:
					$BattleUI.toggle_moveboxes(unit.boxHolder, true, false, false, true)
		for unit in global.storedParty:
			for box in unit.boxHolder.get_children():
				var boxName = box.get_node("Name").text
				if box.currentUses > 0 and (boxName == "Reload" or boxName == "Catch") and !unit.isStunned and unit.currentHealth > 0: box._on_Button_pressed()
		Boons.call_boon("start_turn")
		evaluate_aura(a.turnStart)
		log_turn()
		logIndex = 0
		if autoPreview: yield(preview_turn(), "completed")
		lockPreview = false
		disable_battle_buttons(false)
		yield(self, "turn_taken")
		#print("might be able to eval status here")
	if currentUnit.isPlayer: #skip along
		StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	else: #Enemy turn
		if $BattleLog/Scroll/Control.get_child_count() > logIndex and $BattleLog/Scroll/Control.get_child(logIndex).logUser == currentUnit: focus_log()
		if currentUnit.currentHealth > 0: #if you're dead stop doing moves
			StatusManager.evaluate_statuses(currentUnit, StatusManager.statusActivations.beforeTurn)
			Boons.call_boon("post_status_eval", [currentUnit, currentUnit.real])
			StatusManager.countdown_turns(currentUnit, true)
			if currentUnit.currentHealth > 0 and !currentUnit.isStunned: #poison could kill
				currentUnit.shield = 0
				currentUnit.update_hp()
				moveUser = currentUnit
				moveTarget = currentUnit.storedTarget
				moveName = currentUnit.storedAction
				chosenMove = Moves.moveList[currentUnit.storedAction]
				yield(execute_move(), "completed")
				currentUnit.ui.get_node("Info").visible = false
				currentUnit.ui.get_node("MoveBox").visible = false
				if !battleDone: yield(set_intent(currentUnit), "completed")
				#currentUnit.update_info(currentUnit.storedTarget.name)
			StatusManager.countdown_turns(currentUnit, false)
		play_turn()

func set_action(unit):
	unit.storedAction = unit.allMoves[randi() % unit.allMoves.size()]

func set_intent(unit, target = false):
	if !target: set_action(unit)
	
	#Writing the intent out
	var actionInfo = Moves.moveList[unit.storedAction]
	var actionDamage
	if actionInfo.has("damage"):
		actionDamage = actionInfo["damage"] + unit.strength + unit.tempStrength
		if actionInfo.has("hits"):
			actionDamage = str(actionDamage, "x", actionInfo["hits"])
	#if actionInfo["target"] == targetType.ally:
		#$BattleUI.toggle_buttons(true, get_team(true))
	if actionInfo["target"] == targetType.allies:
		unit.storedTarget = "Allies"
	elif actionInfo["target"] == targetType.user: #Self target
		unit.storedTarget = unit
	elif actionInfo["target"] == targetType.enemies:
		unit.storedTarget = "Party"
	elif actionInfo["target"] == targetType.everyone:
		unit.storedTarget = "Everyone"
	else:
		if unit.targetlock: #Don't set a new one
			pass
		elif !target: #Random target
			var targets
			var extraTargets = []
			if actionInfo["target"] == targetType.enemy:
				targets = get_team(true, true)
				var stealth = []
				for target in targets:
					if StatusManager.find_status(target, "Stealth"):
						targets.erase(target)
						stealth.append(target)
					elif StatusManager.find_status(target, "Provoke"): #stealth overrides provoke
						extraTargets.append(target) #get another one in there
						extraTargets.append(target) #and another, why not
				targets.append_array(extraTargets)
				if targets.empty(): targets = stealth #stealthed units should only be targeted if there are no other valid targets
			else: #Ally
				targets = get_team(false, true)
			if targets.size() > 0: unit.storedTarget = targets[randi() % targets.size()]
		else:
			unit.storedTarget = target
	var targetText = unit.storedTarget
	if typeof(targetText) != TYPE_STRING:
		targetText = targetText.displayName
	if actionDamage: targetText = str(targetText, " (", actionDamage, ")")
	if unit.real:
		var dHolder = global.storedParty[0].ui.get_parent()
		dHolder.box_move(unit.ui.get_node("MoveBox"), unit.storedAction)
		unit.update_info(str(" -> ", targetText))
	yield(get_tree().create_timer(.25), "timeout")

func get_team(gettingPlayers, onlyAlive = false, real = true):
	var team = []
	var unitPool = $Units if real else $PreviewUnits
	for unit in unitPool.get_children():
		if (unit.isPlayer and gettingPlayers) or (!unit.isPlayer and !gettingPlayers):
			if (onlyAlive and unit.currentHealth > 0) or !onlyAlive:
				team.append(unit)
	return team

func evaluate_targets(move, user, box):
	if usedMoveBox: 
		usedMoveBox.change_rect_color(Color(.5,.1,.5,1))  #set any already selected box back to default color
	if box == usedMoveBox: 
		$BattleUI.toggle_buttons(false)
		usedMoveBox = null
	else:
		usedMoveBox = box
		chosenMove = Moves.moveList[move]
		moveName = move
		#$BattleUI.set_description(move, chosenMove, user)
		moveUser = user
		$BattleUI.toggle_buttons(false)
		if chosenMove["target"] == targetType.everyone or chosenMove["target"] == targetType.enemies or chosenMove["target"] == targetType.allies:
			target_chosen()
			usedMoveBox = null
			drag = false
			undrag = null
		elif chosenMove["target"] <= targetType.enemyTargets: #If an enemy is targeted
			$BattleUI.toggle_buttons(true, get_team(false))
		elif chosenMove["target"] <= targetType.allies: #If an ally is targeted
			$BattleUI.toggle_buttons(true, get_team(true))
		elif chosenMove["target"] == targetType.user or chosenMove["target"] == targetType.none: #Self/no target
			#$BattleUI.toggle_buttons(true, [moveUser])
			target_chosen(user.get_index())
			usedMoveBox = null
			drag = false
			undrag = null
		if usedMoveBox: usedMoveBox.change_rect_color(Color(.6,.6,.6,1)) #color indicating this is the selected box

func target_chosen(index = null):
	drag = false
	undrag = null
	moveTarget = $Units.get_child(index) if index != null else null
	executionOrder.append([usedMoveBox, chosenMove, moveUser, moveTarget])
	usedMoveBox.usageOrder = executionOrder.size()
	if chosenMove["target"] != targetType.none: $BattleUI.choose_movebox(usedMoveBox, moveTarget)
	else: $BattleUI.choose_movebox(usedMoveBox) #Choosing a box subtracts a resource, run a toggle afterwards
	moveUser.update_resource(usedMoveBox.resValue, chosenMove["type"], false)
	$BattleUI.toggle_moveboxes(usedMoveBox.get_parent(), chosenMove.has("quick"), true, true) #If quick, check the resources. Otherwise, turn off boxes as appropriate
	$BattleUI.toggle_buttons(false)
	usedMoveBox = null
	log_turn()
	if autoPreview and !lockPreview: yield(preview_turn(), "completed")

func disable_battle_buttons(toggle):
	$GoButton.disabled = toggle
	$Preview.disabled = toggle
	$Lock.disabled = toggle
	$Pray.disabled = true if toggle else check_prayer()
	$Map.disabled = toggle
	$Peek.disabled = toggle

func go_button_press():
	$BattleUI.toggle_buttons(false)
	$BattleUI.toggle_movebox_buttons(false)
	$BattleUI.clear_menus()
	disable_battle_buttons(true)
	remove_blind(false)
	for moveData in executionOrder: #box, move, user, target
		if moveData[e.user].virtue:
			moveName = virtueMove
			usedMoveBox = null
		else: 
			moveName = moveData[e.box].moves[moveData[e.box].moveIndex]
			usedMoveBox = moveData[e.box]
		chosenMove = moveData[e.move]
		moveUser = moveData[e.user]
		moveTarget = moveData[e.target]
		focus_log()
		if moveUser.currentHealth <= 0: continue
		yield(execute_move(), "completed")
		if battleDone: break
	executionOrder.clear()
	emit_signal("turn_taken")

func focus_log():
	if logIndex > 0: $BattleLog/Scroll/Control.get_child(logIndex - 1).recolor()
	$BattleLog/Scroll/Control.get_child(logIndex).focus()
	if logIndex > 4: $BattleLog/Scroll.scroll_horizontal = 240 * logIndex
	logIndex += 1

func cut_from_order(box):
	box.change_rect_color(Color(.5,.1,.5,1)) #set any already selected box back to default color
	if box.moveIndex == 0: box.get_node("Info").text = ""
	var userCommitted = false
	var foundAction
	for action in executionOrder: #box, move, user, target
		if foundAction:
			action[e.box].usageOrder -= 1 #Update the order that happens after the cut action
			action[e.box].updateInfo()
		elif action[e.box] == box:
			foundAction = action
		if action[e.user] == box.user and !action[1].has("quick"): #If a non-quick is committed and a quick is cut, this bool has the quick turn off completely
			userCommitted = true
	executionOrder.erase(foundAction) #Erased from order
	
	if foundAction[e.move].has("resVal"): #Refund resources spent from that action
		foundAction[e.user].update_resource(box.resValue, foundAction[e.move]["type"], true)
	#Restoring UI involving quick actions: If a quick is cut, toggle only that. For non-quick, toggle everything on except for committed quicks
	if !foundAction[e.move].has("quick"): #non-quick case, cutting a committed action while retaining any chosen quicks
		box.buttonMode = true #Needed to properly reset it in the toggle 
		$BattleUI.toggle_moveboxes(foundAction[e.box].get_parent(), true, true, checkChannel(foundAction[e.user]))
	else: #quick case
		$BattleUI.toggle_single(box, !userCommitted)  #If the user is already committed (non-quick), disable the box. Otherwise enable it.
		if userCommitted: box.buttonMode = true #Needed or else the cut box stays disabled for the turn 
		$BattleUI.toggle_moveboxes(foundAction[e.box].get_parent(), !userCommitted, true, checkChannel(foundAction[e.user])) #Checks to re-enable other actions due to earlier refund
	log_turn()
	if autoPreview: yield(preview_turn(), "completed")
	

func checkChannel(unit): #Channels can only be used as the first action of a turn. This checks if the unit has an action in the queue already.
	for action in executionOrder:
		if action[2] == unit:
			return true
	return false

func create_preview_units():
	for unit in $PreviewUnits.get_children():
		$PreviewUnits.remove_child(unit)
		unit.queue_free()
	var previewUnit
	for unit in $Units.get_children():
		if unit.isPlayer: previewUnit = Player.instance()
		else: previewUnit = Enemy.instance()
		$PreviewUnits.add_child(previewUnit)
		previewUnit.clone_values(unit)
	yield(get_tree().create_timer(0), "timeout")

func convert_unit(target):
	if !is_instance_valid(target): return target
	if target == null: return target
	if typeof(target) == TYPE_STRING: return target
	if target.virtue: return target
	else: return $PreviewUnits.get_child(target.get_index())

func log_turn():
	var logIncrement = 240
	var totalLogs = 0
	for child in $BattleLog/Scroll/Control.get_children():
		$BattleLog/Scroll/Control.remove_child(child)
		child.queue_free()
	
	for i in executionOrder.size(): #box, move, user, target
		var entry = LogEntry.instance()
		$BattleLog/Scroll/Control.add_child(entry)
		if executionOrder[i][e.user].virtue: entry.assemble(executionOrder[i][e.user], null, virtueMove)
		else: entry.assemble(executionOrder[i][e.user], executionOrder[i][e.target], executionOrder[i][e.box].moves[executionOrder[i][e.box].moveIndex], executionOrder[i][e.box])
		entry.position.x = logIncrement * totalLogs
		totalLogs += 1
	
	for enemy in get_team(false, true):
			if enemy.currentHealth > 0 and !enemy.isStunned:
				var entry = LogEntry.instance()
				$BattleLog/Scroll/Control.add_child(entry)
				if !canSee: entry.assemble(enemy, null, "X")
				else: entry.assemble(enemy, enemy.storedTarget, enemy.storedAction)
				entry.position.x = logIncrement * totalLogs
				totalLogs += 1
	#$BattleLog/Scroll.update()
	$BattleLog/Scroll/Control.rect_min_size.x = max(720, totalLogs * logIncrement)
	if totalLogs == 4 and $BattleLog/Scroll/_h_scroll.rect_position.y > 100: $BattleLog/Scroll/_h_scroll.rect_position.y -= 130

func toggle_previews(toggle):
	for unit in $Units.get_children():
		unit.ui.get_node("BattleElements/PreviewRect").visible = toggle

func preview_turn():
	previewBattleDone = false
	previewDeadEnemies = deadEnemies
	yield(create_preview_units(), "completed")
	for unit in $PreviewUnits.get_children(): #needs to be done after all units are created
		unit.storedTarget = convert_unit(unit.storedTarget)
	Boons.call_boon("start_preview", [$PreviewUnits.get_children()])
	var fakeOrder = [] #box, move, user, target
	for i in executionOrder.size():
		fakeOrder.append([])
		for j in executionOrder[i].size():
			match j:
				0: fakeOrder[i].append(executionOrder[i][j])
				1: fakeOrder[i].append(executionOrder[i][j])
				2: fakeOrder[i].append(convert_unit(executionOrder[i][j]))
				3: fakeOrder[i].append(convert_unit(executionOrder[i][j]))
	for moveData in fakeOrder: #box, move, user, target
		if moveData[e.user].virtue:
			moveName = virtueMove
			usedMoveBox = null
		else: 
			moveName = moveData[e.box].moves[moveData[e.box].moveIndex]
			usedMoveBox = moveData[e.box]
		chosenMove = moveData[e.move]
		moveUser = moveData[e.user]
		moveTarget = moveData[e.target]
		yield(execute_move(false), "completed")
	if !previewBattleDone: #now for enemies
		usedMoveBox = null
		for enemy in get_team(false, true, false):
			StatusManager.evaluate_statuses(enemy, StatusManager.statusActivations.beforeTurn)
			if enemy.currentHealth > 0 and !enemy.isStunned:
				moveUser = enemy
				moveTarget = convert_unit(enemy.storedTarget)
				moveName = enemy.storedAction
				chosenMove = Moves.moveList[enemy.storedAction]
				yield(execute_move(false), "completed")
	for i in $Units.get_child_count():
		var unit = $Units.get_child(i)
		var previewUnit = $PreviewUnits.get_child(i)
		if unit.isPlayer and !previewBattleDone:
			StatusManager.evaluate_statuses(previewUnit, StatusManager.statusActivations.beforeTurn)
		unit.ui.position_preview_rect(previewUnit.currentHealth, previewUnit)
	usedMoveBox = null
	yield(get_tree().create_timer(.5), "timeout")

func execute_move(real = true):
	#Set up for multi target moves
	var timeoutVal = 0.5 if real else 0.0
	if real: previewBattleDone = false
	hitBonus = 0 + evaluate_aura(a.hitBonus)
	damageBuff = 0 + evaluate_aura(a.damageBuff)
	var targets = []
	var animScope
	if chosenMove["target"] == targetType.enemies:
		targets = get_team(!moveUser.isPlayer, true, real)
		animScope = scope.allies if !moveUser.isPlayer else scope.enemies
	elif chosenMove["target"] == targetType.everyone:
		targets = get_team(moveUser.isPlayer, true, real)
		targets.append_array(get_team(!moveUser.isPlayer, true, real))
		animScope = scope.all
	elif chosenMove["target"] == targetType.enemyTargets:
		var tempTargets = get_team(!moveUser.isPlayer, true, real)
		animScope = scope.allies if !moveUser.isPlayer else scope.enemies
		for unit in tempTargets:
			if typeof(unit.storedTarget) == typeof(moveTarget.storedTarget):
				if unit.storedTarget == moveTarget.storedTarget:
					targets.append(unit)
	elif chosenMove["target"] == targetType.allies:
		targets = get_team(moveUser.isPlayer, true, real)
		animScope = scope.players if moveUser.isPlayer else scope.enemies
	else: #single target
		targets = [moveTarget] 
		animScope = scope.single
		if moveTarget.currentHealth <= 0:
			yield(get_tree().create_timer(timeoutVal), "timeout")
			return
	
	if moveUser.isPlayer:
		hitBonus += Boons.call_boon("before_move", [moveUser, usedMoveBox, real, moveTarget, self])
		moveUser.storedTarget = moveTarget
		if usedMoveBox != null:
			if real: usedMoveBox.timesUsed += 1
			if chosenMove["type"] > Moves.moveType.basic and chosenMove["target"] != targetType.none and usedMoveBox.maxUses > 0: #durability does not go down for reloads and moves without a classtype
				var reduction = 1 + evaluate_aura(a.useDeducted)
				if StatusManager.find_status(moveUser, "Durability Redirect"): #This whole nest is dedicated to the stabilizer
					if real:
						for box in moveUser.boxHolder.get_children():
							if box.maxUses > 0 and !box.buttonMode: #buttonMode clause only relevant for multiple stabilizers on same character (why)
								
								if box.get_index() > 1: usedMoveBox.reduce_uses(reduction) #if it gets past the relic slots it can't be used
								if box.currentUses > 0:
									box.reduce_uses(reduction)
									break
								else: #if it's broken mid-turn
									continue
				else:
					if real: usedMoveBox.reduce_uses(reduction)
					Boons.call_boon("uses_reduced", [moveUser, usedMoveBox, usedMoveBox.currentUses, real, self])
			if real and (chosenMove["type"] == Moves.moveType.trick or chosenMove.has("cycle")):
				if !StatusManager.reduce_status(moveUser, "Autoload", 1): $BattleUI.advance_box_move(usedMoveBox)
	
	#Actual effects of move handled here
	if !chosenMove.has("hits"):
		hits = 1
	elif typeof(chosenMove["hits"]) == TYPE_STRING:
		hits = get_indexed(chosenMove["hits"])
		if typeof(hits) == TYPE_ARRAY: hits = hits.size() #One hit for every item in an array. Yes
	else: hits = chosenMove["hits"]
	hits+= hitBonus
	var bounceHits = true if chosenMove.has("barrage") else false
	var i = 0
	if chosenMove.has("timing") and chosenMove["timing"] == Moves.timings.before: #Some moves activate effects before the damage
		activate_effect()
	StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.moveUsed, [usedMoveBox])
	while i < hits: #repeat for every hit, while loop enables it to be modified on the fly by move effects from outside this file
		if battleDone or previewBattleDone or moveUser.currentHealth <= 0: break
		if bounceHits:
			var bounce = true if i > 0 else false
			#if chosenMove.has("condition") and !bounce: bounce = !chosenMove["condition"].call_func(targets[0])
			if bounce:
				var condition = chosenMove["condition"] if chosenMove.has("condition") else null
				var bounceTarget = null
				if chosenMove.has("bounceEveryone"): bounceTarget = get_next_team_unit(targets[0], real, condition, true)
				else: bounceTarget = get_next_team_unit(targets[0], real, condition)
				if bounceTarget != null: targets = [bounceTarget]
				else: break
		elif targets.size() == 1 and targets[0].currentHealth <= 0: break
		if real and useAnimations and !battleDone:
			var angle = 90
			var singleTarget = true if animScope == scope.single else false
			if singleTarget:
				$EffekseerEmitter2D.position = targets[0].ui.position
				#print(rad2deg(moveUser.ui.position.angle_to(targets[0].ui.position)))
				if moveUser.isPlayer: angle = -4*abs(rad2deg(moveUser.ui.position.angle_to(targets[0].ui.position)))
				#angle = 4*angle if moveUser.isPlayer else -4*angle
			else:
				match animScope:
					scope.players: $EffekseerEmitter2D.position = Vector2(650, 600)
					scope.enemies: $EffekseerEmitter2D.position = Vector2(650, 400)
					scope.all: $EffekseerEmitter2D.position = Vector2(650, 500)
			var animationName
			if chosenMove.has("animation"): animationName = chosenMove["animation"]
			else:
				if singleTarget: animationName = "Slash" if chosenMove.has("damage") or chosenMove.has("damaging") else "Hex"
				else: animationName = "AoESlash" if chosenMove.has("damage") or chosenMove.has("damaging") else "Heal"
			Animations.set_params($EffekseerEmitter2D, animationName, angle)
			$EffekseerEmitter2D.play()
			yield($EffekseerEmitter2D, "finished")
		var baseDamage = 0
		var tempDamage
		if chosenMove.has("damage"): #base damage calculaed outside the target loop to account for burn on multitarget moves
			baseDamage = chosenMove["damage"] + moveUser.strength + moveUser.tempStrength + damageBuff
			tempDamage = StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.usingAttack, [baseDamage])
			if tempDamage != null: baseDamage = tempDamage
		for target in targets: #repeat for every target	
			moveTarget = target
			if chosenMove.has("damage"): #Get base damage, evaluate target status to final damage, deal said damage, update UI
				damageCalc = baseDamage
				tempDamage = StatusManager.evaluate_statuses(target, StatusManager.statusActivations.gettingHit, [damageCalc]) 
				if tempDamage != null: damageCalc = tempDamage
				damageCalc = target.take_damage(damageCalc, false, moveName) #Returns the amount of damage dealt (for recoil reasons). Multihit moves recalculate damage.
				StatusManager.evaluate_statuses(target, StatusManager.statusActivations.afterHit, [damageCalc]) 
				if damageCalc == null: damageCalc = 0 #nulls out sometimes when battle won
				if damageCalc > 0: StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.successfulHit, [damageCalc])
			
			if chosenMove.has("healing"): #Get base damage, evaluate target status to final damage, deal said damage, update UI	
				target.heal(chosenMove["healing"])
			
			if chosenMove.has("status"): #Update target status if there is a status on the move
				if chosenMove.has("value"): #Value determines length of status effect
					if can_activate_effect(chosenMove, damageCalc): StatusManager.add_status(target, chosenMove["status"], chosenMove["value"])
				else: #Status lasts forever or until manually removed
					if can_activate_effect(chosenMove, damageCalc): StatusManager.add_status(target, chosenMove["status"])
			if target.currentHealth <= 0:
				if moveUser.isPlayer: #overkill only returns nonzero for a specific boon and level
					StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.gettingKill, [damageCalc]) 
					var overkill = Boons.call_boon("check_hit", [usedMoveBox, target.currentHealth, moveUser, real, self])
					if overkill > 0:
						var nextTarget = get_next_team_unit(target, real)
						if nextTarget: nextTarget.take_damage(overkill)
				if chosenMove.has("killeffect"): activate_effect("killeffect", "killargs")
			if can_activate_effect(chosenMove, damageCalc): 
				if !chosenMove.has("timing") or chosenMove["timing"] == Moves.timings.after: #Default timing is after damage
					activate_effect()
				if chosenMove.has("secondEffect"): 
					activate_effect("secondEffect", "secondArgs")
		yield(get_tree().create_timer(timeoutVal), "timeout")
		i+=1
	if moveUser.isPlayer:
		if usedMoveBox != null:
			Boons.call_boon("check_move", [usedMoveBox, moveTarget.currentHealth, moveUser, real])
	else:
		Boons.call_specific("check_move", [null, null, moveUser, real], "Lion")
	yield(get_tree().create_timer(0), "timeout") #needed to prevent a crash

func can_activate_effect(moveData, damage):
	if moveData.has("damage"):
		if damage == 0: return false
	else:
		if moveData.has("condition"):
			return moveData["condition"].call_func(moveTarget)
	return true

func get_next_team_unit(unit, real = true, condFunc = null, everyone = false): #gets the next player or enemy from an existing player or enemy's position
	var unitPool = $Units if real else $PreviewUnits
	var unitIndex = (unit.get_index() + 1) % unitPool.get_child_count()
	var checkUnit
	while unitIndex != unit.get_index(): #should stop by returning a unit but will always drop after a runthrough
		checkUnit = unitPool.get_child(unitIndex)
		if (everyone or (checkUnit.isPlayer == unit.isPlayer)) and checkUnit.currentHealth > 0: #needs to be on the same team and alive
			var canUseUnit = true
			if condFunc: canUseUnit = condFunc.call_func(checkUnit)
			if canUseUnit: return checkUnit
		unitIndex = (unitIndex + 1) % unitPool.get_child_count()
	var canUseUnit = true #if there are no units to bounce to, verify that the original target is OK
	if condFunc: canUseUnit = condFunc.call_func(unit)
	if canUseUnit: return unit
	return null #can't find anything valid

func activate_effect(effectName = "effect", argsName = "args"):
	if chosenMove.has(effectName) and chosenMove.has(argsName):
		var newArgs = []
		for argument in chosenMove[argsName]:
			if typeof(argument) == TYPE_OBJECT: #Functions are objects
				newArgs.append(argument.call_func(newArgs[0])) #Run the function on a previous arg, then append result as an arg
			elif typeof(argument) == TYPE_STRING: 
				if get_indexed(argument) != null: #Getting a variable from the Battle scene
					newArgs.append(get_indexed(argument))
				else: #The arg is just a string
					newArgs.append(argument)
			else: #an int
				newArgs.append(argument)
		chosenMove[effectName].call_funcv(newArgs) #Run the effect function on these arguments

func evaluate_completion(deadUnit):
	if deadUnit.real:
		if Map: 
			var xp = deadUnit.maxHealth + evaluate_aura(a.xpGain) * deadUnit.maxHealth
			if doubleXP: xp *= 2
			Map.increment_xp(xp, deadUnit)
			doubleXP = false
		deadEnemies += 1
		previewDeadEnemies += 1
		if deadEnemies >= enemyNum:
			battleDone = true
			#print("Battle Ready To Complete")
	else:
		previewDeadEnemies += 1
		if previewDeadEnemies >= enemyNum:
			previewBattleDone = true

func evaluate_game_over():
	var deadUnits = 0
	for unit in global.storedParty:
		if unit.currentHealth <= 0:
			deadUnits +=1
	if deadUnits == global.storedParty.size():
		battleDone = true
		gameOver = true

func evaluate_revives():
	for unit in global.storedParty:
		if unit.currentHealth <= 0:
			unit.currentHealth = 1
			unit.ui.visible = true
			unit.killedMove = ""
			unit.update_hp()

func done(rewards = []):
	#$BattleUI.toggle_trackers(false)
	if !get_parent().mapMode:
		return get_tree().reload_current_scene()
	else: #Map
		drag = false
		undrag = null
		Boons.call_boon("end_battle", [get_partyHealth(), self])
		for i in global.storedParty.size():
			var unit = global.storedParty[i]
			if unit.currentHealth > 0 and StatusManager.find_status(unit, "Passive Income"): rewards.append("Coin")
			unit.update_strength(true)
			set_ui(unit)
			$BattleUI.playerHolder.manage_and_color_boxes(unit, Map.inventoryWindow)
		if !rewards.empty(): Map.inventoryWindow.add_multi(rewards)
		Map.inventoryWindow.inventory_blackouts(false)
		#map.inventoryWindow.add_item(reward)
		toggle_previews(false)
		visible = false
		evaluate_revives()
		deadEnemies = 0
		previewDeadEnemies = 0
		$BattleUI.toggle_movebox_buttons(true)
		Map.set_quick_panels()
		Map.toggle_map_windows(true)
		if bossFight: 
			bossFight = false
			Map.boss_defeated()

func _on_Preview_pressed():
	$BattleUI.toggle_buttons(false)
	autoPreview = !autoPreview
	toggle_previews(autoPreview)
	var textSet = "ON" if autoPreview else "OFF"
	$Preview.text = "PREVIEW " + textSet
	if autoPreview: yield(preview_turn(), "completed")

func _on_Peek_pressed():
	Boons.call_boon("peek", [turnCount])
	remove_blind()

func remove_blind(checkPreview = true):
	toggle_blind(true, checkPreview)
	canSee = true
	log_turn()

func _on_Lock_pressed():
	levelLock = !levelLock
	var textSet = ""
	if levelLock:
		textSet += "UN"
		Map.get_node("XPBar").modulate = Color(1,.2,.2,1)
	else: Map.get_node("XPBar").modulate = Color(1,1,1,1)
	$Lock.text = textSet + "LOCK LEVEL"

func _on_Map_pressed():
	Map.inventoryWindow.player_blackouts(null, true)
	Map.get_node("BattleButton").visible = true
	Map.toggle_map_windows(true)
	visible = false

func _on_Pray_pressed():
	virtueUsed = !virtueUsed
	if virtueUsed:
		Boons.grant_favor(-1 * virtueCost)
		executionOrder.append([null, Moves.moveList[virtueMove], $Virtue, Moves.moveList[virtueMove]["target"]])
	else:
		Boons.grant_favor(virtueCost)
		for i in executionOrder.size():
			if executionOrder[i][e.user].virtue: 
				executionOrder.remove(i)
				break
	log_turn()
	if autoPreview and !lockPreview: yield(preview_turn(), "completed")
	
