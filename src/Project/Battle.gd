extends Node2D

export (PackedScene) var Player
export (PackedScene) var Enemy

var partyNum = 1
var enemyNum = 1
var deadEnemies = 0

const apIncrement = 20
const STUNCODE = -1

signal turn_taken

var turnIndex = -1

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

var opponents = ["Skeleton"]

var targetsVisible = false

var executionOrder = [] #box, move, user, target
enum e {box, move, user, target}
var targetType

func _ready(): #Generate units and add to turn order
	if get_parent().name == "root": battleDone = false
	targetType = $Moves.targetType
	randomize() #funny rng
	if opponents.size() == 0: #Random formation
		opponents = $Formations.formationList[randi() %$Formations.formationList.size()]
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
				var enemy = $Enemies.enemyList[opponents[i - partyNum]]
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
		$StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
	for unit in $Units.get_children():
		$BattleUI.setup_display(unit, opponents.size())
		if !unit.isPlayer: #Set enemy intents
			set_intent(unit)
		if unit.isPlayer: 
			unit.update_strength()
		if unit.passives.size() > 0:
			for passive in unit.passives:
				$StatusManager.add_status(unit, passive, unit.passives[passive])
	
	#generate_rewards()
	
	if !battleDone: play_turn()

func create_enemies():
	var createdUnit = Enemy.instance()
	var enemy
	var i = 0
	for opponent in opponents:
		enemy = $Enemies.enemyList[opponent]
		createdUnit.callv("make_stats", enemy["stats"])
		createdUnit.identity = opponent
		createdUnit.name = str(createdUnit.identity, String(i))
		if enemy.has("passives"): createdUnit.passives = enemy["passives"]
		if enemy.has("specials"): 
			createdUnit.moves = enemy["specials"]
			createdUnit.allMoves.append_array(createdUnit.moves)
		$StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
		$BattleUI.setup_display(createdUnit, opponents.size())
		set_intent(createdUnit)
		if createdUnit.passives.size() > 0:
			for passive in createdUnit.passives:
				$StatusManager.add_status(createdUnit, passive, createdUnit.passives[passive])
		i+=1

func welcome_back(): #reusing an existing battle scene for a new battle
	$BattleUI.toggle_trackers(true)
	$BattleUI.enemyCount = 0
	battleDone = false
	for unit in $Units.get_children():
		if !unit.isPlayer:
			unit.cease_to_exist()
		else:
			unit.strength = 0
			unit.ap = 0
			unit.energy = unit.maxEnergy
			unit.statuses.clear()
			$StatusManager.initialize_statuses(unit)
			unit.update_box_bars()
			unit.update_status_ui()
			unit.update_strength()
	turnIndex = -1
	create_enemies()
	play_turn()

func play_turn():
	turnIndex = (turnIndex + 1) % $Units.get_child_count() #Advance to next unit
	currentUnit = $Units.get_child(turnIndex)
	
	if turnIndex == 0: #Start of turn, take player actions
		for unit in $Units.get_children():
			$StatusManager.countdown_turns(unit, true)
			if unit.isPlayer:
				unit.update_resource(apIncrement, $Moves.moveType.special, true)
				unit.update_resource(unit.maxEnergy, $Moves.moveType.trick, true)
				for display in $BattleUI.playerHolder.get_children():
					if display.get_node_or_null("MoveBoxes"):
						$BattleUI.toggle_moveboxes(display.get_node("MoveBoxes"), true)
		yield(self, "turn_taken")
		if battleDone: return
	if currentUnit.isPlayer: #skip along
		$StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	else: #Enemy turn
		if currentUnit.currentHealth > 0: #if you're dead stop doing moves
			moveUser = currentUnit
			moveTarget = currentUnit.storedTarget
			moveName = currentUnit.storedAction
			chosenMove = $Moves.moveList[currentUnit.storedAction]
			yield(execute_move(), "completed")
			yield(set_intent(currentUnit), "completed")
			#currentUnit.update_info(currentUnit.storedTarget.name)
			$StatusManager.countdown_turns(currentUnit, false)
		play_turn()

func set_action(unit):
	unit.storedAction = unit.allMoves[randi() % unit.allMoves.size()]

func set_intent(unit, target = false):
	set_action(unit)
	
	#Target
	var actionInfo = $Moves.moveList[unit.storedAction]
	var actionDamage
	if actionInfo.has("damage"):
		actionDamage = actionInfo["damage"] + unit.strength
		if actionInfo.has("hits"):
			actionDamage = str(actionDamage, "x", actionInfo["hits"])
	if actionInfo["target"] == targetType.ally:
		$BattleUI.toggle_buttons(true, get_team(true))
	elif actionInfo["target"] == targetType.allies:
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
			if actionInfo["target"] == targetType.enemy:
				targets = get_team(true, true)
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
	chosenMove = $Moves.moveList[move]
	moveName = move
	$BattleUI.set_description(move, chosenMove)
	moveUser = user
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
	if chosenMove["target"] != targetType.none: $BattleUI.choose_movebox(usedMoveBox, moveTarget) #
	else: $BattleUI.choose_movebox(usedMoveBox) #Choosing a box subtracts a resource, run a toggle afterwards
	moveUser.update_resource(chosenMove["resVal"], chosenMove["type"], false)
	$BattleUI.toggle_moveboxes(usedMoveBox.get_parent(), chosenMove.has("quick"), true, true) #If quick, check the resources. Otherwise, turn off boxes as appropriate
	$BattleUI.toggle_buttons(false)
	$GoButton.visible = true

func go_button_press():
	$BattleUI.clear_menus()
	$GoButton.visible = false
	for moveData in executionOrder: #box, move, user, target
		usedMoveBox = moveData[0]
		chosenMove = moveData[1]
		moveUser = moveData[2]
		moveTarget = moveData[3]
		yield(execute_move(), "completed")
		if battleDone: return
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
		foundAction[e.user].update_resource(foundAction[e.move]["resVal"], foundAction[e.move]["type"], true)
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
	if moveUser.isPlayer:
		moveUser.storedTarget = moveTarget
		if chosenMove["type"] == $Moves.moveType.trick or chosenMove.has("cycle"):
			$BattleUI.advance_box_move(usedMoveBox)
	
	#Set up for multi target moves
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
	
	#Actual effects of move handled here
	if !chosenMove.has("hits"):
		hits = 1
	elif typeof(chosenMove["hits"]) == TYPE_STRING:
		hits = get_indexed(chosenMove["hits"])
		if typeof(hits) == TYPE_ARRAY: hits = hits.size() #One hit for every item in an array. Yes
	else: hits = chosenMove["hits"]
	var i = 0
	while i < hits: #repeat for every hit, while loop enables it to be modified on the fly by move effects from outside this file
		for target in targets: #repeat for every target	
			if chosenMove.has("timing") and chosenMove["timing"] == $Moves.timings.before: #Some moves activate effects before the damage
				activate_effect()
			if chosenMove.has("damage"): #Get base damage, evaluate target status to final damage, deal said damage, update UI
				damageCalc = chosenMove["damage"] + moveUser.strength - moveTarget.defense
				var tempDamage
				#One status check for the user's attack modifiers and another for the target's defense modifiers
				tempDamage = $StatusManager.evaluate_statuses(moveUser, $StatusManager.statusActivations.usingAttack, [damageCalc])
				if tempDamage != null: damageCalc = tempDamage #Sometimes the status doesn't return anything
				tempDamage = $StatusManager.evaluate_statuses(moveTarget, $StatusManager.statusActivations.gettingHit, [damageCalc]) 
				if tempDamage != null: damageCalc = tempDamage
				damageCalc = target.take_damage(damageCalc) #Returns the amount of damage dealt (for recoil reasons). Multihit moves recalculate damage.
			
			if chosenMove.has("healing"): #Get base damage, evaluate target status to final damage, deal said damage, update UI	
				target.heal(chosenMove["healing"])
			
			if chosenMove.has("status"): #Update target status if there is a status on the move
				if chosenMove.has("value"): #Value determines length of status effect
					$StatusManager.add_status(target, chosenMove["status"], chosenMove["value"])
				else: #Status lasts forever or until manually removed
					$StatusManager.add_status(target, chosenMove["status"])
				if chosenMove["status"] == "Provoke": #intent changing status is unique
					for cond in target.statuses[$StatusManager.statusActivations.passive]:
						if cond["name"] == "Provoke" and cond["value"] >= $StatusManager.THRESHOLD:
							set_intent(target, moveUser) #just taunt for now
			if !chosenMove.has("timing") or chosenMove["timing"] == $Moves.timings.after: #Default timing is after damage
				activate_effect()
		yield(get_tree().create_timer(.5), "timeout")
		i+=1

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

func evaluate_completion():
	if deadEnemies >= enemyNum:
		battleDone = true
		done()

func done():
	$BattleUI.toggle_trackers(false)
	if get_parent().name == "root":
		return get_tree().change_scene("res://src/Project/Debug.tscn")
	else:
		visible = false

func generate_rewards():
	var rewards = $Enemies.enemyList[opponents[randi() % opponents.size()]]["rewards"] #Random enemy from the opponents list gives rewards
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
	
	
	
