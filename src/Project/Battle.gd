extends Node2D

export (PackedScene) var Player
export (PackedScene) var Enemy

const partyNum = 2
var enemyNum = 4
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
var moveTarget
var damageCalc
var info
var hits

var opponents = []

var targetsVisible = false

enum targetType {enemy, enemies, enemyTargets, ally, allies, user}

func _ready(): #Generate units and add to turn order
	randomize() #funny rng
	if opponents.size() == 0: #Random formation
		opponents = $Formations.formationList[randi() %$Formations.formationList.size()]
		enemyNum = opponents.size()
	for i in partyNum + enemyNum:
		var createdUnit
		if i < partyNum: #player
			createdUnit = Player.instance()
			if global.storedParty.size() <= i:
				createdUnit.make_stats(40, 5, 5, 18)
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
					createdUnit.specials = enemy["specials"]
					createdUnit.allMoves.append_array(createdUnit.specials)
			else:
				createdUnit.callv("make_stats", [400, 10, 5, 5])
				createdUnit.name = str("E", String(i))
		$StatusManager.initialize_statuses(createdUnit)
		$Units.add_child(createdUnit)
	var units = $Units.get_children()
	units.sort_custom(self, 'sort_battlers')
	var i = 0
	for unit in units:
		unit.raise()
		$BattleUI.setup_display(unit, i)
		if !unit.isPlayer: #Set enemy intents
			set_intent(unit)
		if unit.isPlayer: process_equipment(unit) #Gotta do this after the UI is set
		i += 1
		if unit.passives.size() > 0:
			for passive in unit.passives:
				$StatusManager.add_status(unit, passive, unit.passives[passive])
	
	generate_rewards()
	
	play_turn()

func play_turn():
	if !chosenMove or !chosenMove.has("quick"): turnIndex = (turnIndex + 1) % $Units.get_child_count() #Advance to next unit if a non-quick action is used
	currentUnit = $Units.get_child(turnIndex)
	
	if !chosenMove or !chosenMove.has("quick"): 
		info = $StatusManager.evaluate_statuses(currentUnit, $StatusManager.statusActivations.beforeTurn)
		$StatusManager.countdown_turns(currentUnit, true)
	
	$BattleUI.move_pointer(turnIndex)
	if currentUnit.currentHealth <= 0 or info == STUNCODE: #Dead or stunned
		$StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	elif currentUnit.isPlayer: #Player turn
		if !chosenMove or !chosenMove.has("quick"): currentUnit.update_ap(apIncrement)
		$BattleUI.open_commands()
		yield(self, "turn_taken")
		$StatusManager.countdown_turns(currentUnit, false)
		play_turn()
	else: #Enemy turn
		moveUser = currentUnit
		moveTarget = currentUnit.storedTarget
		chosenMove = $Moves.moveList[currentUnit.storedAction]
		yield(execute_move(), "completed")
		set_intent(currentUnit)
		#currentUnit.update_info(currentUnit.storedTarget.name)
		$StatusManager.countdown_turns(currentUnit, false)
		play_turn()

func set_action(unit):
	unit.storedAction = unit.allMoves[randi() % unit.allMoves.size()]

func set_intent(unit, target = false):
	set_action(unit)
	
	#Target
	var actionInfo = $Moves.moveList[unit.storedAction]
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
	unit.update_info(str(unit.storedAction, " -> ", targetText))

func get_team(gettingPlayers, onlyAlive = false):
	var team = []
	for unit in $Units.get_children():
		if (unit.isPlayer and gettingPlayers) or (!unit.isPlayer and !gettingPlayers):
			if (onlyAlive and unit.currentHealth > 0) or !onlyAlive:
				team.append(unit)
	return team

static func sort_battlers(a, b) -> bool:
	return a.speed > b.speed

func process_equipment(unit):
	for item in unit.equipment:
		if unit.equipment[item]: #if there is an item equipped in that slot
			var equip = $Equipment.equipmentList[unit.equipment[item]]
			if equip.has("strength"):
				unit.strength += equip["strength"]
			if equip.has("speed"):
				unit.speed += equip["speed"]
			if equip.has("defense"):
				unit.defense += equip["defense"]
			if equip.has("special"):
				unit.specials.append(equip["special"])
			if equip.has("spell"):
				unit.spells.append(equip["spell"])
			if equip.has("status"):
				$StatusManager.add_status(unit, equip["status"])

func evaluate_targets(move, user):
	chosenMove = menuNode.moveList[move]
	moveName = move
	$BattleUI.set_description(move, chosenMove)
	moveUser = user
	if chosenMove["target"] <= targetType.enemyTargets: #If an enemy is targeted
		$BattleUI.toggle_buttons(true, get_team(false))
	elif chosenMove["target"] <= targetType.allies: #If an ally is targeted
		$BattleUI.toggle_buttons(true, get_team(true))
	elif chosenMove["target"] == targetType.user: #Self target
		$BattleUI.toggle_buttons(true, [moveUser])
	

func target_chosen(index):
	moveTarget = $Units.get_child(index)
	execute_move()
	
	
func execute_move():
	if $BattleUI.targetsVisible:
		$BattleUI.toggle_buttons(false)
		$BattleUI.clear_menus()
		moveUser.storedTarget = moveTarget
	
	if chosenMove.has("cost") and moveUser.isPlayer: #Subtract AP
		if moveUser.ap < chosenMove["cost"]:
			emit_signal("turn_taken")
			return
		else:
			moveUser.update_ap(chosenMove["cost"] * -1)
	
	if chosenMove.has("level") and moveUser.isPlayer: #Subtract spell charge
		if moveUser.charges[chosenMove["level"]] <= 0:
			emit_signal("turn_taken")
			return
		else:
			moveUser.charges[chosenMove["level"]] -= 1
	
	if menuNode == $Items: #Subtract item and erase if 0
		moveUser.items[moveName] -= 1
		if moveUser.items[moveName] <= 0:
			moveUser.items.erase(moveName)
	
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
			i+=1
		yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("turn_taken")

func activate_effect():
	if chosenMove.has("effect") and chosenMove.has("args"):
		var newArgs = []
		for argument in chosenMove["args"]:
			if typeof(argument) == TYPE_OBJECT:
				newArgs.append(argument.call_func(newArgs[0]))
			elif typeof(argument) == TYPE_STRING: 
				if get_indexed(argument) != null:
					newArgs.append(get_indexed(argument))
				else:
					newArgs.append(argument)
			else:
				newArgs.append(argument)
		chosenMove["effect"].call_funcv(newArgs)

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
					
	print(finalRewards)
	
	
	
