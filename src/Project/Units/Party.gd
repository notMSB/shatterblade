extends Node2D

export (PackedScene) var Player
export (PackedScene) var ChoiceUI

onready var Moves = get_node("../Data/Moves")

const BASEHP = 40
const OPTIONS = 3
const PARTYSIZE = 4
const INCREMENT = 400
const MOVES_AVAILABLE = 2

var tempParty = []

func _ready():
	randomize()
	if global.storedParty.size() > 0: global.storedParty.clear()
	create_options(OPTIONS)

func create_options(number):
	for i in number:
		var createdUnit = Player.instance()
		createdUnit.allowedType = Moves.random_moveType()
		createdUnit.title = Moves.get_classname(createdUnit.allowedType)
		set_stats(createdUnit, BASEHP)
		rando_moves(createdUnit, MOVES_AVAILABLE)
		tempParty.append(createdUnit)
		make_info(createdUnit, i)

func make_info(unit, index):
	var info = ""
	info += str(unit.maxHealth, ", ", Moves.moveType.keys()[unit.allowedType], "\n")
	for move in unit.moves:
		info += "[" + move + "] "
	var choice = ChoiceUI.instance()
	choice.get_node("Info").text = info
	choice.position.x = INCREMENT
	choice.position.y = INCREMENT * index *.5 + INCREMENT*.25
	$Choices.add_child(choice)

func choose(index):
	global.storedParty.append(tempParty[index])
	for n in $Choices.get_children():
		n.queue_free()
	tempParty.clear()
	if global.storedParty.size() < PARTYSIZE:
		create_options(OPTIONS)
	else:
		return get_tree().reload_current_scene()

func random_item(list):
	return list[randi() % list.size()]

func set_stats(unit, hp):
	unit.maxHealth = hp
	unit.currentHealth = unit.maxHealth
	
func rando_moves(unit, number):
	var list = Moves.moveList
	var rando = []
	for move in list: #populate rando with viable moves
		if list[move].has("type"): 
			if list[move]["type"] == unit.allowedType:
				rando.append(move)
	var randomMove
	for i in number: #add number of moves from rando to unit's move list
		randomMove = random_item(rando)
		unit.moves.append(randomMove)
		rando.erase(randomMove)
