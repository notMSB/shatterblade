extends Node2D

export (PackedScene) var Player
export (PackedScene) var ChoiceUI

const HPMultiplier = 4
const options = 3
const partySize = 4
const INCREMENT = 400
const POINTS_AVAILABLE = 15
const BASE_STAT = 5
const MOVES_AVAILABLE = 2

enum targetType {enemy, enemies, enemyTargets, ally, allies, user}

func _ready():
	randomize()
	create_options(options)

func create_options(number):
	for i in number:
		var createdUnit = Player.instance()
		rando_stats(createdUnit, POINTS_AVAILABLE, BASE_STAT)
		rando_weapon(createdUnit)
		rando_moves(createdUnit, MOVES_AVAILABLE)
		
		$TempParty.add_child(createdUnit)
		make_info(createdUnit, i)

func make_info(unit, index):
	var info = ""
	info += String(unit.maxHealth) + " " + String(unit.strength) + " " + String(unit.defense) + " " + String(unit.speed) + "\n" + unit.equipment["weapon"] + "\n"
	for special in unit.specials:
		info += "[" + special + "] "
	var choice = ChoiceUI.instance()
	choice.get_node("Info").text = info
	#choice.position.x = INCREMENT * index
	choice.position.y = INCREMENT * index / 2
	$Choices.add_child(choice)

func choose(index):
	global.storedParty.append($TempParty.get_child(index))
	for n in $Choices.get_children():
		$Choices.remove_child(n)
	for n in $TempParty.get_children():
		$TempParty.remove_child(n)
	if global.storedParty.size() < partySize:
		create_options(options)
	else:
		print(str("Party: ", global.storedParty))
		return get_tree().change_scene("res://src/Project/Battle.tscn")

func random_item(list):
	return list[randi() % list.size()]

func rando_stats(unit, points, base):
	unit.strength = base
	unit.speed = base
	unit.defense = base
	unit.maxHealth = base * HPMultiplier

	var rando
	for point in points:
		rando = randi() % 4
		if rando == 0: unit.strength += 1
		elif rando == 1: unit.speed += 1
		elif rando == 2: unit.defense += 1
		elif rando == 3: unit.maxHealth += HPMultiplier
	unit.currentHealth = unit.maxHealth

func rando_weapon(unit):
	var list = $Equipment.equipmentList
	var rando = []
	for weapon in list:
		if list[weapon]["type"] == "weapon" and list[weapon].has("weight"):
			for weight in list[weapon]["weight"]:
				rando.append(weapon)
	unit.equipment["weapon"] = random_item(rando)
	#print(unit.equipment["weapon"])
	
func rando_moves(unit, number):
	var list = $Moves.moveList
	var rando = []
	for move in list:
		if list[move].has("weight"): 
			for weight in list[move]["weight"]:
				rando.append(move)
	var randomMove
	for i in number:
		randomMove = random_item(rando)
		unit.specials.append(randomMove)
		for j in list[randomMove]["weight"]:
			rando.erase(randomMove)
