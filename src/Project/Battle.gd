extends Node2D

export (PackedScene) var Player
export (PackedScene) var Enemy

onready var Moves = get_node("../Data/Moves")
onready var StatusManager = get_node("../Data/StatusManager")
onready var Enemies = get_node("../Data/Enemies")
onready var Formations = get_node("../Data/Formations")
onready var Boons = get_node("../Data/Boons")

var partyNum = 1
var enemyNum = 1
var deadEnemies = 0
var previewDeadEnemies = 0

const apIncrement = 20

signal turn_taken

var turnIndex = -1
var turnCount = 0

var currentUnit
var menuNode

var descriptionNode

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

var gameOver = false
var battleDone = true
var previewBattleDone = false
var autoPreview = true
var rewardUnit

var opponents = ["Rat"]

var executionOrder = [] #box, move, user, target
enum e {box, move, user, target}
var targetType

func _ready(): #Generate units and add to turn order
	Moves.Battle = self
	StatusManager.Battle = self
	if !get_parent().mapMode: battleDone = false
	targetType = Moves.targetType
	randomize() #funny rng
	if opponents.size() == 0: #Random formation
		opponents = Formations.formationList[randi() % Formations.formationList.size()]
		enemyNum = opponents.size()
	if global.storedParty.size() > 0: partyNum = global.storedParty.size()
	var unitNum = partyNum
	if !battleDone: unitNum += enemyNum
	for i in unitNum:
		var createdUnit
		if i < partyNum: #player
			createdUnit = setup_player(i)
		else: #enemy
			createdUnit = Enemy.instance()
			if opponents.size() > i - partyNum:
				var enemy = Enemies.enemyList[opponents[i - partyNum]]
				if get_parent().hardMode: createdUnit.make_stats(enemy["stats"][1])
				else: createdUnit.make_stats(enemy["stats"][0])
				createdUnit.identity = str(opponents[i - partyNum])
				createdUnit.battleName = str(createdUnit.identity, String(i))
				if enemy.has("passives"): createdUnit.passives = enemy["passives"]
				if enemy.has("specials"): 
					createdUnit.moves = enemy["specials"]
					if get_parent().hardMode and enemy.has("hardSpecials"): createdUnit.moves.append_array(enemy["hardSpecials"])
					createdUnit.allMoves.append_array(createdUnit.moves)
			else:
				createdUnit.make_stats(400)
				createdUnit.battleName = str("E", String(i))
		StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
	for unit in $Units.get_children():
		$BattleUI.setup_display(unit, opponents.size())
	
	if !battleDone:
		Boons.call_boon("start_battle", [get_partyHealth()])
		for unit in $Units.get_children():
			if !unit.isPlayer: #Set enemy intents
				set_intent(unit)
			if unit.isPlayer: 
				unit.update_strength(true)
			if unit.passives.size() > 0:
				for passive in unit.passives:
					StatusManager.add_status(unit, passive, unit.passives[passive])
		play_turn(false)
	if !get_parent().mapMode:
		descriptionNode = $BattleUI/Description
	else:
		descriptionNode = get_node("../Map/Description")
	$BattleUI/Description.visible = !get_parent().mapMode

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

func create_enemies():
	var createdUnit
	var enemy
	var i = 0
	for opponent in opponents:
		createdUnit = Enemy.instance()
		enemy = Enemies.enemyList[opponent]
		if get_parent().hardMode: createdUnit.make_stats(enemy["stats"][1])
		else: createdUnit.make_stats(enemy["stats"][0])
		createdUnit.identity = opponent
		createdUnit.spriteBase = enemy["sprite"]
		createdUnit.battleName = str(createdUnit.identity, String(i))
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

func welcome_back(newOpponents = null): #reusing an existing battle scene for a new battle
	$BattleUI.toggle_trackers(true)
	turnCount = 0
	$BattleUI.enemyCount = 0
	battleDone = false
	previewBattleDone = false
	rewardUnit = null
	Boons.call_boon("start_battle", [get_partyHealth()])
	for unit in $Units.get_children():
		if !unit.isPlayer:
			unit.cease_to_exist()
		else:
			set_ui(unit, true)
	turnIndex = -1
	if newOpponents: opponents = newOpponents
	yield(create_enemies(), "completed")
	if autoPreview: toggle_previews(true)
	play_turn(false)

func set_ui(unit, setPassives = false):
	unit.strength = unit.startingStrength
	unit.ap = 0
	unit.energy = unit.maxEnergy
	unit.statuses.clear()
	StatusManager.initialize_statuses(unit)
	unit.update_box_bars()
	unit.update_strength(true)
	if battleDone: unit.shield = 0
	unit.update_hp()
	if setPassives and unit.passives.size() > 0:
		for passive in unit.passives:
			StatusManager.add_status(unit, passive, unit.passives[passive])
	unit.update_status_ui()

func get_partyHealth():
	var total = 0
	for unit in global.storedParty:
		total += unit.currentHealth
	return total

func play_turn(notFirstTurn = true):
	if battleDone:
		if gameOver: return get_tree().change_scene("res://src/Project/Lose.tscn")
		var rewards = [Enemies.enemyList[rewardUnit.identity]["rewards"][0]]
		for enemy in get_team(false):
			if Enemies.enemyList[enemy.identity].has("elite"): rewards.append("Health Potion")
		return done(rewards)
	turnIndex = (turnIndex + 1) % $Units.get_child_count() #Advance to next unit
	currentUnit = $Units.get_child(turnIndex)
	if turnIndex == 0: #Start of turn, take player actions
		usedMoveBox = null
		if notFirstTurn and get_parent().mapMode: get_node("../Map").subtract_time(1)
		turnCount+=1
		for unit in $Units.get_children():
			unit.update_strength(true)
			unit.isStunned = false
			if notFirstTurn:
				unit.shield = 0
				unit.update_hp()
			if unit.isPlayer:
				StatusManager.evaluate_statuses(unit, StatusManager.statusActivations.beforeTurn)
				unit.update_resource(apIncrement, Moves.moveType.special, true)
				unit.update_resource(unit.maxEnergy, Moves.moveType.trick, true)
				if !unit.isStunned:
					$BattleUI.toggle_moveboxes(unit.boxHolder, true, false, false, true)
				else:
					$BattleUI.toggle_moveboxes(unit.boxHolder, false, false, false, true)
			StatusManager.countdown_turns(unit, true)
		for unit in global.storedParty:
			for box in unit.boxHolder.get_children():
				var boxName = box.get_node("Name").text
				if  boxName == "Reload" or boxName == "Catch": box._on_Button_pressed()
		Boons.call_boon("start_turn")
		if autoPreview: yield(preview_turn(), "completed")
		$GoButton.visible = true
		yield(self, "turn_taken")
		#print("might be able to eval status here")
	if currentUnit.isPlayer: #skip along
		StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	else: #Enemy turn
		if currentUnit.currentHealth > 0: #if you're dead stop doing moves
			StatusManager.evaluate_statuses(currentUnit, StatusManager.statusActivations.beforeTurn)
			Boons.call_boon("post_status_eval", [currentUnit, currentUnit.real])
			if currentUnit.currentHealth > 0 and !currentUnit.isStunned: #poison could kill
				moveUser = currentUnit
				moveTarget = currentUnit.storedTarget
				moveName = currentUnit.storedAction
				chosenMove = Moves.moveList[currentUnit.storedAction]
				yield(execute_move(), "completed")
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
		targetText = targetText.battleName
	if actionDamage: targetText = str(targetText, " (", actionDamage, ")")
	unit.update_info(str(unit.storedAction, " -> ", targetText))
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
		elif chosenMove["target"] <= targetType.enemyTargets: #If an enemy is targeted
			$BattleUI.toggle_buttons(true, get_team(false))
		elif chosenMove["target"] <= targetType.allies: #If an ally is targeted
			$BattleUI.toggle_buttons(true, get_team(true))
		elif chosenMove["target"] == targetType.user or chosenMove["target"] == targetType.none: #Self/no target
			#$BattleUI.toggle_buttons(true, [moveUser])
			target_chosen(user.get_index())
			usedMoveBox = null

func target_chosen(index = null):
	moveTarget = $Units.get_child(index) if index != null else null
	executionOrder.append([usedMoveBox, chosenMove, moveUser, moveTarget])
	usedMoveBox.usageOrder = executionOrder.size()
	if chosenMove["target"] != targetType.none: $BattleUI.choose_movebox(usedMoveBox, moveTarget)
	else: $BattleUI.choose_movebox(usedMoveBox) #Choosing a box subtracts a resource, run a toggle afterwards
	moveUser.update_resource(usedMoveBox.resValue, chosenMove["type"], false)
	$BattleUI.toggle_moveboxes(usedMoveBox.get_parent(), chosenMove.has("quick"), true, true) #If quick, check the resources. Otherwise, turn off boxes as appropriate
	$BattleUI.toggle_buttons(false)
	if autoPreview: yield(preview_turn(), "completed")

func go_button_press():
	$BattleUI.toggle_buttons(false)
	$BattleUI.toggle_movebox_buttons(false)
	$BattleUI.clear_menus()
	$GoButton.visible = false
	for moveData in executionOrder: #box, move, user, target
		usedMoveBox = moveData[0]
		chosenMove = moveData[1]
		moveUser = moveData[2]
		moveTarget = moveData[3]
		yield(execute_move(), "completed")
		if battleDone: break
	executionOrder.clear()
	emit_signal("turn_taken")

func cut_from_order(box):
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
		$BattleUI.toggle_moveboxes(foundAction[e.box].get_parent(), true, true, checkChannel(foundAction[2]))
	else: #quick case
		$BattleUI.toggle_single(box, !userCommitted)  #If the user is already committed (non-quick), disable the box. Otherwise enable it.
		if userCommitted: box.buttonMode = true #Needed or else the cut box stays disabled for the turn 
		$BattleUI.toggle_moveboxes(foundAction[0].get_parent(), !userCommitted, true, checkChannel(foundAction[2])) #Checks to re-enable other actions due to earlier refund
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
	if !is_instance_valid(target): return null
	elif target == null: return target
	elif typeof(target) == TYPE_STRING: return target
	else: return $PreviewUnits.get_child(target.get_index())

func toggle_previews(toggle):
	for unit in $Units.get_children():
		unit.ui.get_node("BattleElements/HPBar/PreviewRect").visible = toggle

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
		usedMoveBox = moveData[0]
		chosenMove = moveData[1]
		moveUser = moveData[2]
		moveTarget = moveData[3]
		yield(execute_move(false), "completed")
	if !previewBattleDone: #now for enemies
		usedMoveBox = null
		for enemy in get_team(false, true, false):
			StatusManager.evaluate_statuses(enemy, StatusManager.statusActivations.beforeTurn)
			if enemy.currentHealth > 0 and !enemy.isStunned: #poison could kill
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
		unit.ui.position_preview_rect(previewUnit.currentHealth, unit.isPlayer)
	yield(get_tree().create_timer(.5), "timeout")

func execute_move(real = true):
	#Set up for multi target moves
	var timeoutVal = 0.5 if real else 0.0
	if real: previewBattleDone = false
	hitBonus = 0
	var targets = []
	if chosenMove["target"] == targetType.enemies:
		targets = get_team(!moveUser.isPlayer, true, real)
	elif chosenMove["target"] == targetType.everyone:
		targets = get_team(moveUser.isPlayer, true, real)
		targets.append_array(get_team(!moveUser.isPlayer, true, real))
	elif chosenMove["target"] == targetType.enemyTargets:
		var tempTargets = get_team(!moveUser.isPlayer, true, real)
		for unit in tempTargets:
			if (typeof(unit.storedTarget) == TYPE_STRING and unit.storedTarget == "Party") or unit.storedTarget == moveTarget.storedTarget:
				targets.append(unit)
	elif chosenMove["target"] == targetType.allies:
		targets = get_team(moveUser.isPlayer, true, real)
	else: #single target
		targets = [moveTarget] 
		if moveTarget.currentHealth <= 0:
			yield(get_tree().create_timer(timeoutVal), "timeout")
			return
	
	if moveUser.isPlayer:
		hitBonus += Boons.call_boon("before_move", [moveUser, real])
		moveUser.storedTarget = moveTarget
		if usedMoveBox != null and real:
			usedMoveBox.timesUsed += 1
			if chosenMove["type"] > Moves.moveType.basic and chosenMove["target"] != targetType.none and usedMoveBox.maxUses > 0: #durability does not go down for reloads and moves without a classtype
				if StatusManager.find_status(moveUser, "Durability Redirect"): #This whole nest is dedicated to the stabilizer
					for box in moveUser.boxHolder.get_children():
						if box.maxUses > 0 and !box.buttonMode: #buttonMode clause only relevant for multiple stabilizers on same character (why)
							if box.get_index() > 1: usedMoveBox.reduce_uses(1) #if it gets past the relic slots it can't be used
							if box.currentUses > 0:
								box.reduce_uses(1)
								break
							else: #if it's broken mid-turn
								continue
				else:
					usedMoveBox.reduce_uses(1)
			if chosenMove["type"] == Moves.moveType.trick or chosenMove.has("cycle"):
				$BattleUI.advance_box_move(usedMoveBox)
	
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
	damageBuff = 0
	if chosenMove.has("timing") and chosenMove["timing"] == Moves.timings.before: #Some moves activate effects before the damage
		activate_effect()
	while i < hits: #repeat for every hit, while loop enables it to be modified on the fly by move effects from outside this file
		if battleDone or previewBattleDone: break
		if bounceHits:
			var bounce = true if i > 0 else false
			if chosenMove.has("condition") and !bounce: bounce = !chosenMove["condition"].call_func(targets[0])
			if bounce:
				var condition = chosenMove["condition"] if chosenMove.has("condition") else null
				var bounceTarget = null
				if chosenMove.has("bounceEveryone"): bounceTarget = get_next_team_unit(targets[0], real, null, true)
				else: bounceTarget = get_next_team_unit(targets[0], real, condition)
				if bounceTarget != null: targets = [bounceTarget]
		elif targets.size() == 1 and targets[0].currentHealth <= 0: break
		for target in targets: #repeat for every target	
			moveTarget = target
			if chosenMove.has("damage"): #Get base damage, evaluate target status to final damage, deal said damage, update UI
				damageCalc = chosenMove["damage"] + moveUser.strength + moveUser.tempStrength - target.defense + damageBuff
				var tempDamage
				#One status check for the user's attack modifiers and another for the target's defense modifiers
				tempDamage = StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.usingAttack, [damageCalc])
				if tempDamage != null: damageCalc = tempDamage #Sometimes the status doesn't return anything
				tempDamage = StatusManager.evaluate_statuses(target, StatusManager.statusActivations.gettingHit, [damageCalc]) 
				if tempDamage != null: damageCalc = tempDamage
				damageCalc = target.take_damage(damageCalc) #Returns the amount of damage dealt (for recoil reasons). Multihit moves recalculate damage.
			
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
					var overkill = Boons.call_boon("check_hit", [usedMoveBox, target.currentHealth, moveUser, real])
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
		Boons.call_specific("check_move", [null, null, moveUser], "Lion")
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
		deadEnemies += 1
		previewDeadEnemies += 1
		if deadEnemies >= enemyNum:
			battleDone = true
			rewardUnit = deadUnit
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
			unit.update_hp()

func done(rewards):
	#$BattleUI.toggle_trackers(false)
	if !get_parent().mapMode:
		return get_tree().reload_current_scene()
	else: #Map
		var map = get_node("../Map")
		Boons.call_boon("end_battle", [get_partyHealth()])
		for i in global.storedParty.size():
			set_ui(global.storedParty[i])
			$BattleUI.playerHolder.manage_and_color_boxes(global.storedParty[i], map.inventoryWindow)
		map.inventoryWindow.add_multi(rewards)
		#map.inventoryWindow.add_item(reward)
		toggle_previews(false)
		visible = false
		evaluate_revives()
		deadEnemies = 0
		previewDeadEnemies = 0
		$BattleUI.toggle_movebox_buttons(true)

func _on_Preview_pressed():
	$BattleUI.toggle_buttons(false)
	autoPreview = !autoPreview
	toggle_previews(autoPreview)
	var textSet = "ON" if autoPreview else "OFF"
	$Preview.text = "PREVIEW" + textSet
	if autoPreview: yield(preview_turn(), "completed")
