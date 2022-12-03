extends Node2D

export (PackedScene) var Player
export (PackedScene) var PartyChoice
export (PackedScene) var BoonSelect
export (PackedScene) var MapScene

onready var Moves = get_node("../Data/Moves")
onready var Boons = get_node("../Data/Boons")

onready var Game = get_parent()

const BASEHP = 40
const OPTIONS = 3
const PARTYSIZE = 2
const INCREMENT = 400
const MOVES_AVAILABLE = 2

enum types {fighter, mage, rogue, none, other}

var chosenBoon = null
var tempParty = []

var partyMembers = {
	"Gerald": {"type": types.fighter, "stats": [40, 0], "moves": ["Pierce", "Protect"]},
	"Jerald": {"type": types.fighter, "stats": [35, 5], "moves": ["Power Attack", "Turtle Up"]},
	"Werald": {"type": types.fighter, "stats": [30, 10], "moves": ["Cleave", "Careful Strike"]},
	"Merald": {"type": types.fighter, "stats": [25, 15], "moves": ["Poison Strike", "Feeding Frenzy"]},
	"Ferald": {"type": types.fighter, "stats": [20, 20], "moves": ["Dark Dive", "Spit Shine"]},
	
	"Steve": {"type": types.mage, "stats": [40, 100], "moves": ["Dark Spikes", "Growth"]},
	"Sbeve": {"type": types.mage, "stats": [35, 120], "moves": ["Seeker Volley", "Restore"]},
	"Stephe": {"type": types.mage, "stats": [30, 140], "moves": ["Constrict", "Venoshock"]},
	"Sbephe": {"type": types.mage, "stats": [25, 160], "moves": ["Plague", "Dodge"]},
	"Sbbbbb": {"type": types.mage, "stats": [20, 180], "moves": ["Frostfang", "Hide"]},
	
	"Jimmy": {"type": types.rogue, "stats": [40, 4], "moves": ["Coldsteel", "Eye Poke"]},
	"Bimmy": {"type": types.rogue, "stats": [35, 5], "moves": ["Piercing Sting", "Crusher Claw"]},
	"Timmy": {"type": types.rogue, "stats": [30, 6], "moves": ["Taunt", "Sucker Punch"]},
	"Pimmy": {"type": types.rogue, "stats": [25, 7], "moves": ["Quick Attack", "Taste Test"]},
	"Mimmy": {"type": types.rogue, "stats": [20, 8], "moves": ["Shiv", "Back Rake"]},
}

func _ready():
	#randomize()
	$DisplayHolder.Moves = Moves
	if global.storedParty.size() > 0:
		for member in global.storedParty:
			member.queue_free()
		global.storedParty.clear()
	create_options()

func create_options():
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
				newSelect.get_node("Price").set_position(Vector2(645, -25))
				textLabeled = true
			newSelect.position.x = (i * INCREMENT) + (150 * j) - 499
			newSelect.position.y = 65
	var currentType = 0
	var currentMember = 0
	for member in partyMembers:
		if currentType != partyMembers[member]["type"]: 
			currentType = partyMembers[member]["type"]
			currentMember = 0
		var choice = PartyChoice.instance()
		$Choices.add_child(choice)
		setup_member(choice, member, currentType)
		choice.position.y = 165 + 85 * currentMember
		choice.position.x = 98 + 400 * currentType
		currentMember += 1
		

func area_break():
	var currentType = 0
	var typeMembers = []
	for member in partyMembers:
		if currentType != partyMembers[member]["type"]: 
			setup_rando(typeMembers, currentType)
			currentType = partyMembers[member]["type"]
			typeMembers.clear()
		else:
			typeMembers.append(member)
	setup_rando(typeMembers, currentType) #one more time for after every element is looked at

func setup_rando(typeMembers, currentType):
	var choice = PartyChoice.instance()
	$Choices.add_child(choice)
	var randomMember = typeMembers[randi() % typeMembers.size()]
	setup_member(choice, randomMember, currentType)
	choice.position.y = 80 + 130 * currentType
	choice.position.x = 500

func setup_member(choice, member, currentType):
	var resStr = ""
	match currentType:
		types.fighter: resStr = " AP"
		types.mage: resStr = " Mana"
		types.rogue: resStr = " Energy"
	
	choice.unitName = member
	set_button_color(choice.get_node("Button"), currentType)
	choice.get_node("Text").text = str(member, " | ", partyMembers[member]["stats"][0], "HP | ", partyMembers[member]["stats"][1], resStr)
	$DisplayHolder.box_move(choice.get_node("Left"), partyMembers[member]["moves"][0])
	$DisplayHolder.box_move(choice.get_node("Right"), partyMembers[member]["moves"][1])

func choose_member(selection):
	if Game.mapMode:
		global.storedParty.append(create_unit(selection))
		visible = false
		Game.get_node("Map").add_new_member()
	else:
		selection.chosen = !selection.chosen
		if selection.chosen: 
			set_button_color(selection.get_node("Button"), types.other)
			tempParty.append(selection)
		else: 
			set_button_color(selection.get_node("Button"), partyMembers[selection.unitName]["type"])
			tempParty.erase(selection)
		if tempParty.size() > PARTYSIZE:
			set_button_color(tempParty[0].get_node("Button"), partyMembers[tempParty[0].unitName]["type"])
			tempParty.pop_front()
		$ColorRect/UI/MemberText.text = str(tempParty.size(), "/2 Members Selected")
		check_start()

func create_unit(choice):
	var unit = Player.instance()
	unit.displayName = choice.unitName
	unit.maxHealth = partyMembers[choice.unitName]["stats"][0]
	unit.currentHealth = unit.maxHealth
	unit.moves = partyMembers[choice.unitName]["moves"]
	match partyMembers[choice.unitName]["type"]:
		types.fighter: 
			unit.baseAP = partyMembers[choice.unitName]["stats"][1]
			unit.ap = unit.baseAP
			unit.allowedType = Moves.moveType.special
		types.mage: 
			unit.maxMana = partyMembers[choice.unitName]["stats"][1]
			unit.mana = unit.maxMana
			unit.allowedType = Moves.moveType.magic
		types.rogue: 
			unit.maxEnergy = partyMembers[choice.unitName]["stats"][1]
			unit.energy = unit.maxEnergy
			unit.allowedType = Moves.moveType.trick
	return unit

func select_pressed(boonSelect):
	if boonSelect.name == chosenBoon:
		set_button_color(boonSelect.get_node("Button"), types.none)
		chosenBoon = null
		$ColorRect/UI/BoonText.text = "0/1 Boon Selected"
	else:
		if chosenBoon != null: set_button_color($Choices.get_node(chosenBoon).get_node("Button"), types.none)
		chosenBoon = boonSelect.name
		set_button_color(boonSelect.get_node("Button"), types.other)
		$ColorRect/UI/BoonText.text = "1/1 Boon Selected"
	check_start()

func check_start():
	$ColorRect/UI/Start.disabled = false if tempParty.size() >= PARTYSIZE and chosenBoon else true

func set_button_color(button, type):
	match type:
		types.fighter: button.modulate = Color(.9,.3,.3,1) #R
		types.mage: button.modulate = Color(.3,.3,.9,1) #B
		types.rogue: button.modulate = Color(.3,.7,.3,1) #G
		types.none: button.modulate = Color("f9d8d8") #boonselect color
		types.other: button.modulate = Color(1,1,0,1) #Y

func make_info(unit, index):
	var info = ""
	info += str(unit.maxHealth, ", ", Moves.moveType.keys()[unit.allowedType], "\n")
	for move in unit.moves:
		info += "[" + move + "] "
	var choice = PartyChoice.instance()
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
		create_options()
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

func _on_Difficulty_pressed():
	Game.hardMode = !Game.hardMode
	if Game.hardMode: $ColorRect/UI/Difficulty/Mode.text = "Hard"
	else: $ColorRect/UI/Difficulty/Mode.text = "Normal"

func _on_Start_pressed(): #make units, put in global party, set boon
	Boons.chosen = Boons.boonList[chosenBoon]["virtue"]
	Boons.playerBoons.append(chosenBoon)
	Boons.create_boon(chosenBoon)
	for choice in tempParty:
		global.storedParty.append(create_unit(choice))
	for n in $Choices.get_children():
		n.queue_free()
	Game.mapMode = true
	Game.add_child(MapScene.instance())
	$ColorRect/UI.visible = false
	$ColorRect.margin_bottom = 460 #For between areas
	visible = false
	
