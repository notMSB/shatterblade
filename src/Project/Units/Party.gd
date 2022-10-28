extends Node2D

export (PackedScene) var Player
export (PackedScene) var ChoiceUI
export (PackedScene) var BoonSelect

onready var Moves = get_node("../Data/Moves")
onready var Boons = get_node("../Data/Boons")

const BASEHP = 40
const OPTIONS = 3
const PARTYSIZE = 2
const INCREMENT = 400
const MOVES_AVAILABLE = 2

var tempParty = []

func _ready():
	randomize()
	if global.storedParty.size() > 0: global.storedParty.clear()
	create_options(0)

func create_options(number):
	if number == 0: #boon select
		for i in 3:
			var textLabeled = false
			Boons.chosen = i
			var vBoons = Boons.get_virtue_boons()
			for j in vBoons.size():
				var newSelect = BoonSelect.instance()
				var boonName = vBoons[j]
				$Choices.add_child(newSelect)
				newSelect.name = boonName
				newSelect.get_node("Button").text = boonName
				if !textLabeled:
					newSelect.get_node("Price").text = Boons.set_text()
					newSelect.get_node("Price").set_position(Vector2(650, -25))
					textLabeled = true
				newSelect.position.x = (j * INCREMENT / 2) - 115
				newSelect.position.y = (i * INCREMENT / 1.5) + 50
	for i in number:
		var createdUnit = Player.instance()
		if i % 3 == 0: createdUnit.allowedType = Moves.moveType.special
		elif i % 3 == 1: createdUnit.allowedType = Moves.moveType.magic
		elif i % 3 == 2: createdUnit.allowedType = Moves.moveType.trick
		#createdUnit.allowedType = Moves.random_moveType()
		createdUnit.title = Moves.get_classname(createdUnit.allowedType)
		set_stats(createdUnit, BASEHP)
		rando_moves(createdUnit, MOVES_AVAILABLE)
		tempParty.append(createdUnit)
		make_info(createdUnit, i)

func select_pressed(boonSelect):
	var boonName = boonSelect.name
	Boons.chosen = Boons.boonList[boonName]["virtue"]
	Boons.playerBoons.append(boonName)
	Boons.create_boon(boonName)
	for n in $Choices.get_children():
		n.queue_free()
	create_options(OPTIONS)

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
		visible = false
		if get_parent().mapMode:
			get_parent().get_node("Map").add_new_member()

func random_item(list):
	return list[randi() % list.size()]

func set_stats(unit, hp):
	unit.maxHealth = hp
	unit.currentHealth = unit.maxHealth
	
func rando_moves(unit, number):
	var list = Moves.moveList
	var rando = [[],[]] #damaging, other
	for move in list: #populate rando with viable moves
		if list[move].has("type") and list[move].has("slot"): 
			if list[move]["slot"] == Moves.equipType.gear and list[move]["type"] == unit.allowedType and !list[move].has("cycle"): #cycle moves are not meant to be standalone moves
				if list[move].has("damage") or list[move].has("damaging"):
					rando[0].append(move)
				else:
					rando[1].append(move)
	var randoIndex
	var randomMove
	for i in number: #add number of moves from rando to unit's move list
		randoIndex = i % rando.size()
		randomMove = random_item(rando[randoIndex])
		unit.moves.append(randomMove)
		rando[randoIndex].erase(randomMove)
