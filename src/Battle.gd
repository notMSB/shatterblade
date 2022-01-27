extends Node2D

export (PackedScene) var Player
export (PackedScene) var Enemy

const partyNum = 3
const enemyNum = 3
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
var info
var hits

var opponents = ["Bat", "Bat"]

var targetsVisible = false

enum targetType {enemy, enemies, enemyTargets, ally, allies, user}

func _ready(): #Generate units and add to turn order
	randomize() #funny rng
	for i in partyNum + enemyNum:
		var createdUnit
		if i < partyNum: #player
			createdUnit = Player.instance()
			if global.storedParty.size() <= i:
				createdUnit.make_stats(1, 5, 5, 6)
			else:
				createdUnit = global.storedParty[i]
			createdUnit.name = str("P", String(i))
		else: #enemy
			createdUnit = Enemy.instance()
			if opponents.size() > i - partyNum:
				var enemy = $Enemies.enemyList[opponents[i - partyNum]]
				createdUnit.callv("make_stats", enemy["stats"])
				createdUnit.name = str(opponents[i - partyNum], String(i))
			else:
				createdUnit.callv("make_stats", [400, 10, 5, 5])
				createdUnit.name = str("E", String(i))
		$StatusManager.initialize_statuses(createdUnit)
		$Order.add_child(createdUnit)
	var units = $Order.get_children()
	units.sort_custom(self, 'sort_battlers')
	var i = 0
	for unit in units:
		unit.raise()
		$BattleUI.setup_display(unit, i)
		if !unit.isPlayer: #Set enemy intents
			set_intent(unit)
		if unit.isPlayer: process_equipment(unit) #Gotta do this after the UI is set
		i += 1
	play_turn()

func play_turn():
	if !chosenMove or !chosenMove.has("quick"): turnIndex = (turnIndex + 1) % $Order.get_child_count() #Advance to next unit if a non-quick action is used
	currentUnit = $Order.get_child(turnIndex)
	
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
		chosenMove = $Moves.moveList["Attack"]
		yield(execute_move(), "completed")
		set_intent(currentUnit)
		#currentUnit.update_info(currentUnit.storedTarget.name)
		$StatusManager.countdown_turns(currentUnit, false)
		play_turn()

func set_intent(unit, target = false):
	if !target: #Random target
		var targets = get_team(true, true)
		unit.storedTarget = targets[randi() % targets.size()]
	else:
		unit.storedTarget = target
	unit.update_info(unit.storedTarget.name)

func get_team(gettingPlayers, onlyAlive = false):
	var team = []
	for unit in $Order.get_children():
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
	moveTarget = $Order.get_child(index)
	execute_move()
	
	
func execute_move():
	if $BattleUI.targetsVisible:
		$BattleUI.toggle_buttons(false)
	$BattleUI.clear_menus()
	
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
		targets = get_team(false, true)
	elif chosenMove["target"] == targetType.enemyTargets:
		var tempTargets = get_team(false, true)
		for unit in tempTargets:
			if unit.storedTarget == moveTarget.storedTarget:
				targets.append(unit)
	elif chosenMove["target"] == targetType.allies:
		targets = get_team(true, true)
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
			if chosenMove.has("damage"): #Get base damage, evaluate target status to final damage, deal said damage, update UI	
				var damageCalc =  chosenMove["damage"] + moveUser.strength - moveTarget.defense
				#One status check for the user's attack modifiers and another for the target's defense modifiers
				damageCalc = $StatusManager.evaluate_statuses(moveUser, $StatusManager.statusActivations.usingAttack, [damageCalc]) 
				damageCalc = $StatusManager.evaluate_statuses(moveTarget, $StatusManager.statusActivations.gettingHit, [damageCalc]) 
				target.take_damage(damageCalc)
			
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
							
			if chosenMove.has("effect") and chosenMove.has("args"):
				var newArgs = []
				for argument in chosenMove["args"]:
					if typeof(argument) == TYPE_OBJECT:
						newArgs.append(argument.call_func(newArgs[0]))
					elif typeof(argument) == TYPE_STRING: 
						if get_indexed(argument):
							newArgs.append(get_indexed(argument))
						else:
							newArgs.append(argument)
					else:
						newArgs.append(argument)
				chosenMove["effect"].call_funcv(newArgs)
			i+=1
		yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("turn_taken")
