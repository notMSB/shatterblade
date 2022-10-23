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
var info
var hits

var battleDone = true
var rewardUnit

var opponents = ["Rat"]

var targetsVisible = false

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
			createdUnit = Player.instance()
			if global.storedParty.size() <= i:
				createdUnit.make_stats(40)
			else:
				createdUnit = global.storedParty[i]
			createdUnit.name = str("P", String(i))
		else: #enemy
			createdUnit = Enemy.instance()
			if opponents.size() > i - partyNum:
				var enemy = Enemies.enemyList[opponents[i - partyNum]]
				createdUnit.callv("make_stats", enemy["stats"])
				createdUnit.identity = str(opponents[i - partyNum])
				createdUnit.name = str(createdUnit.identity, String(i))
				if enemy.has("passives"): createdUnit.passives = enemy["passives"]
				if enemy.has("specials"): 
					createdUnit.moves = enemy["specials"]
					createdUnit.allMoves.append_array(createdUnit.moves)
			else:
				createdUnit.callv("make_stats", [400])
				createdUnit.name = str("E", String(i))
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

func create_enemies():
	var createdUnit
	var enemy
	var i = 0
	for opponent in opponents:
		createdUnit = Enemy.instance()
		enemy = Enemies.enemyList[opponent]
		createdUnit.callv("make_stats", enemy["stats"])
		createdUnit.identity = opponent
		createdUnit.name = str(createdUnit.identity, String(i))
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

func welcome_back(newOpponents = null): #reusing an existing battle scene for a new battle
	turnCount = 0
	$BattleUI.toggle_trackers(true)
	$BattleUI.enemyCount = 0
	battleDone = false
	rewardUnit = null
	Boons.call_boon("start_battle", [get_partyHealth()])
	for unit in $Units.get_children():
		if !unit.isPlayer:
			unit.cease_to_exist()
		else:
			set_ui(unit, true)
	turnIndex = -1
	if newOpponents: opponents = newOpponents
	create_enemies()
	play_turn(false)

func set_ui(unit, setPassives = false):
	unit.strength = unit.startingStrength
	unit.ap = 0
	unit.energy = unit.maxEnergy
	unit.statuses.clear()
	StatusManager.initialize_statuses(unit)
	unit.update_box_bars()
	unit.update_strength(true)
	unit.shield = 0
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

func play_turn(resetShield = true):
	if battleDone:
		return done(Enemies.enemyList[rewardUnit.identity]["rewards"][0])
	turnIndex = (turnIndex + 1) % $Units.get_child_count() #Advance to next unit
	currentUnit = $Units.get_child(turnIndex)
	if turnIndex == 0: #Start of turn, take player actions
		if get_parent().mapMode: get_node("../Map").subtract_time(1)
		turnCount+=1
		for unit in $Units.get_children():
			unit.update_strength(true)
			unit.isStunned = false
			if resetShield: 
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
		Boons.call_boon("start_turn")
		yield(self, "turn_taken")
		#print("might be able to eval status here")
	if currentUnit.isPlayer: #skip along
		StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	else: #Enemy turn
		if currentUnit.currentHealth > 0: #if you're dead stop doing moves
			StatusManager.evaluate_statuses(currentUnit, StatusManager.statusActivations.beforeTurn)
			Boons.call_boon("post_status_eval", [currentUnit])
			if currentUnit.currentHealth > 0 and !currentUnit.isStunned: #poison could kill
				moveUser = currentUnit
				moveTarget = currentUnit.storedTarget
				moveName = currentUnit.storedAction
				chosenMove = Moves.moveList[currentUnit.storedAction]
				yield(execute_move(), "completed")
				yield(set_intent(currentUnit), "completed")
				#currentUnit.update_info(currentUnit.storedTarget.name)
				StatusManager.countdown_turns(currentUnit, false)
		play_turn()

func set_action(unit):
	unit.storedAction = unit.allMoves[randi() % unit.allMoves.size()]

func set_intent(unit, target = false):
	set_action(unit)
	
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
	else:
		if unit.targetlock: #Don't set a new one
			pass
		elif !target: #Random target
			var targets
			var extraTargets = []
			if actionInfo["target"] == targetType.enemy:
				targets = get_team(true, true)
				for target in targets:
					if StatusManager.find_status(target, "Provoke"):
						extraTargets.append(target) #get another one in there
						extraTargets.append(target) #and another, why not
				targets.append_array(extraTargets)
			else: #Ally
				targets = get_team(false, true)
			unit.storedTarget = targets[randi() % targets.size()]
		else:
			unit.storedTarget = target
	var targetText = unit.storedTarget
	if typeof(targetText) != TYPE_STRING:
		targetText = targetText.name
	if actionDamage: targetText = str(targetText, " (", actionDamage, ")")
	unit.update_info(str(unit.storedAction, " -> ", targetText))
	yield(get_tree().create_timer(.25), "timeout")

func get_team(gettingPlayers, onlyAlive = false):
	var team = []
	for unit in $Units.get_children():
		if (unit.isPlayer and gettingPlayers) or (!unit.isPlayer and !gettingPlayers):
			if (onlyAlive and unit.currentHealth > 0) or !onlyAlive:
				team.append(unit)
	return team

func evaluate_targets(move, user, box):
	usedMoveBox = box
	chosenMove = Moves.moveList[move]
	moveName = move
	$BattleUI.set_description(move, chosenMove, user)
	moveUser = user
	$BattleUI.toggle_buttons(false)
	if chosenMove["target"] <= targetType.enemyTargets: #If an enemy is targeted
		$BattleUI.toggle_buttons(true, get_team(false))
	elif chosenMove["target"] <= targetType.allies: #If an ally is targeted
		$BattleUI.toggle_buttons(true, get_team(true))
	elif chosenMove["target"] == targetType.user: #Self target
		$BattleUI.toggle_buttons(true, [moveUser])
	elif chosenMove["target"] == targetType.none: #No target, instant confirm (coded as self)
		target_chosen(user.get_index())
	

func target_chosen(index):
	moveTarget = $Units.get_child(index)
	executionOrder.append([usedMoveBox, chosenMove, moveUser, moveTarget])
	usedMoveBox.usageOrder = executionOrder.size()
	if chosenMove["target"] != targetType.none: $BattleUI.choose_movebox(usedMoveBox, moveTarget)
	else: $BattleUI.choose_movebox(usedMoveBox) #Choosing a box subtracts a resource, run a toggle afterwards
	moveUser.update_resource(usedMoveBox.resValue, chosenMove["type"], false)
	$BattleUI.toggle_moveboxes(usedMoveBox.get_parent(), chosenMove.has("quick"), true, true) #If quick, check the resources. Otherwise, turn off boxes as appropriate
	$BattleUI.toggle_buttons(false)
	$GoButton.visible = true

func go_button_press():
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
		

func checkChannel(unit): #Channels can only be used as the first action of a turn. This checks if the unit has an action in the queue already.
	for action in executionOrder:
		if action[2] == unit:
			return true
	return false

func execute_move():
	#Set up for multi target moves
	var hitBonus = 0
	var targets = []
	if chosenMove["target"] == targetType.enemies:
		targets = get_team(!moveUser.isPlayer, true)
	elif chosenMove["target"] == targetType.enemyTargets:
		var tempTargets = get_team(!moveUser.isPlayer, true)
		for unit in tempTargets:
			if unit.storedTarget == moveTarget.storedTarget:
				targets.append(unit)
	elif chosenMove["target"] == targetType.allies:
		targets = get_team(moveUser.isPlayer, true)
	else: #single target
		targets = [moveTarget] 
		if moveTarget.currentHealth <= 0:
			yield(get_tree().create_timer(.5), "timeout")
			return
	
	if moveUser.isPlayer:
		hitBonus = Boons.call_boon("before_move", [moveUser])
		moveUser.storedTarget = moveTarget
		usedMoveBox.timesUsed += 1
		if chosenMove["type"] > Moves.moveType.basic and chosenMove["target"] != targetType.none: #durability does not go down for reloads and moves without a classtype
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
	var bounceHits = true if chosenMove.has("bounce") else false
	var i = 0
	while i < hits: #repeat for every hit, while loop enables it to be modified on the fly by move effects from outside this file
		if targets.size() == 1 and targets[0].currentHealth <= 0: break
		if bounceHits and i > 0: 
			targets = [get_next_team_unit(targets[0])]
		for target in targets: #repeat for every target	
			if chosenMove.has("timing") and chosenMove["timing"] == Moves.timings.before: #Some moves activate effects before the damage
				activate_effect()
			if chosenMove.has("damage"): #Get base damage, evaluate target status to final damage, deal said damage, update UI
				damageCalc = chosenMove["damage"] + moveUser.strength + moveUser.tempStrength - moveTarget.defense
				var tempDamage
				#One status check for the user's attack modifiers and another for the target's defense modifiers
				tempDamage = StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.usingAttack, [damageCalc])
				if tempDamage != null: damageCalc = tempDamage #Sometimes the status doesn't return anything
				tempDamage = StatusManager.evaluate_statuses(moveTarget, StatusManager.statusActivations.gettingHit, [damageCalc]) 
				if tempDamage != null: damageCalc = tempDamage
				damageCalc = target.take_damage(damageCalc) #Returns the amount of damage dealt (for recoil reasons). Multihit moves recalculate damage.
			
			if chosenMove.has("healing"): #Get base damage, evaluate target status to final damage, deal said damage, update UI	
				target.heal(chosenMove["healing"])
			
			if chosenMove.has("status"): #Update target status if there is a status on the move
				if chosenMove.has("value"): #Value determines length of status effect
					StatusManager.add_status(target, chosenMove["status"], chosenMove["value"])
				else: #Status lasts forever or until manually removed
					StatusManager.add_status(target, chosenMove["status"])
				if chosenMove["status"] == "Provoke": #intent changing status is unique
					for cond in target.statuses[StatusManager.statusActivations.passive]:
						if cond["name"] == "Provoke" and cond["value"] >= 1:
							set_intent(target, moveUser) #just taunt for now
							StatusManager.remove_status(target, "Provoke")
			if !chosenMove.has("timing") or chosenMove["timing"] == Moves.timings.after: #Default timing is after damage
				activate_effect()
		yield(get_tree().create_timer(.5), "timeout")
		i+=1
	if moveUser.isPlayer: #overkill only returns nonzero for a specific boon and level
		if moveTarget.currentHealth <= 0:
			StatusManager.evaluate_statuses(moveUser, StatusManager.statusActivations.gettingKill, [damageCalc]) 
		var overkill = Boons.call_boon("check_move", [usedMoveBox, moveTarget.currentHealth, moveUser])
		if overkill > 0:
			var nextTarget = get_next_team_unit(moveTarget)
			if nextTarget: nextTarget.take_damage(overkill)
	#if hits == 0: yield(get_tree().create_timer(.25), "timeout") #needed to prevent a crash

func get_next_team_unit(unit): #gets the next player or enemy from an existing player or enemy's position
	var unitIndex = (unit.get_index() + 1) % $Units.get_child_count()
	var checkUnit
	while unitIndex != unit.get_index(): #should stop by returning a unit but will always drop after a runthrough
		checkUnit = $Units.get_child(unitIndex)
		if checkUnit.isPlayer == unit.isPlayer and checkUnit.currentHealth > 0: #needs to be on the same team and alive
			return checkUnit
		unitIndex = (unitIndex + 1) % $Units.get_child_count()
	return false #can't find anything valid

func activate_effect():
	if chosenMove.has("effect") and chosenMove.has("args"):
		var newArgs = []
		for argument in chosenMove["args"]:
			if typeof(argument) == TYPE_OBJECT: #Functions are objects
				newArgs.append(argument.call_func(newArgs[0])) #Run the function on a previous arg, then append result as an arg
			elif typeof(argument) == TYPE_STRING: 
				if get_indexed(argument) != null: #Getting a variable from the Battle scene
					newArgs.append(get_indexed(argument))
				else: #The arg is just a string
					newArgs.append(argument)
			else: #an int
				newArgs.append(argument)
		chosenMove["effect"].call_funcv(newArgs) #Run the effect function on these arguments

func evaluate_completion(deadUnit):
	if deadEnemies >= enemyNum:
		battleDone = true
		rewardUnit = deadUnit
		print("Battle Ready To Complete")

func done(reward):
	$BattleUI.toggle_trackers(false)
	if !get_parent().mapMode:
		return get_tree().reload_current_scene()
	else: #Map
		var map = get_node("../Map")
		Boons.call_boon("end_battle", [get_partyHealth()])
		for i in global.storedParty.size():
			set_ui(global.storedParty[i])
			$BattleUI.playerHolder.manage_and_color_boxes(global.storedParty[i], map.inventoryWindow.DEFAULTCOLOR)
		map.inventoryWindow.add_item(reward)
		visible = false
		$BattleUI.toggle_movebox_buttons(true)

func generate_rewards():
	var rewards = Enemies.enemyList[opponents[randi() % opponents.size()]]["rewards"] #Random enemy from the opponents list gives rewards
	var categories = [[0],[0]] #0 loot 1 learn
	var finalRewards = []
	
	for reward in rewards: #Need a loop for total weight and to set up one reward for each category
		if reward.has("loot"):
			categories[0].append(reward)
			categories[0][0] += reward["weight"]
		else:
			categories[1].append(reward)
			categories[1][0] += reward["weight"]
			
	for category in categories:
		var rewardValue = randi() % category[0]
		if category.size() == 2: #it works
			finalRewards.append(category[1])
		else:
			category.remove(0) #just having a good time out here really
			for reward in category:
				rewardValue -= reward["weight"]
				if rewardValue <= 0:
					finalRewards.append(reward)
					break
					
	#print(finalRewards)
	
	
	
