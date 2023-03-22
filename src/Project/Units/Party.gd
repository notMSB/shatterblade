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

var totalBoons = 0

var chosenBoon = null
var tempParty = []

var partyMembers = {
	"Gerald": {"type": types.fighter, "stats": [40, 0], "moves": ["Grapple", "Power Attack"], "boon": "Scales"},
	"Ferald": {"type": types.fighter, "stats": [40, 0], "moves": ["Breaker Slash", "Dark Dive"], "boon": "Infinite"},
	"Yerald": {"type": types.fighter, "stats": [35, 5], "moves": ["Vampire", "Deep Cut"], "boon": "Column"},
	"Jerald": {"type": types.fighter, "stats": [30, 10], "moves": ["Take Down", "Dive Bomb"], "boon": "Crown"},
	"Werald": {"type": types.fighter, "stats": [30, 10], "moves": ["Cleave", "Spit Shine"], "boon": "Blind"},
	"Zerald": {"type": types.fighter, "stats": [25, 15], "moves": ["Pierce", "Protect"], "boon": "Tides"},
	"Berald": {"type": types.fighter, "stats": [25, 15], "moves": ["Goblin Dodge", "Careful Strike"], "boon": "Weak"},
	"Merald": {"type": types.fighter, "stats": [20, 20], "moves": ["Poison Strike", "Turtle Up"], "boon": "Lion"},
	
	"Steve": {"type": types.mage, "stats": [40, 100], "moves": ["Defensive Pact", "Submersion"], "boon": "Crown"},
	"Sbeve": {"type": types.mage, "stats": [35, 120], "moves": ["Soul Sample", "Dark Spikes"], "boon": "Sword"},
	"Strive": {"type": types.mage, "stats": [35, 120], "moves": ["Frostfang", "Firewall"], "boon": "Mask"},
	"Steed": {"type": types.mage, "stats": [30, 140], "moves": ["Venoshock", "Invisibility"], "boon": "Cup"},
	"Stove": {"type": types.mage, "stats": [25, 160], "moves": ["Seeker Volley", "Constrict"], "boon": "Wings"},
	"Sbephe": {"type": types.mage, "stats": [25, 160], "moves": ["Fireball", "Restore"], "boon": "Column"},
	"Sbbbbb": {"type": types.mage, "stats": [20, 180], "moves": ["Plague", "Hide"], "boon": "Lion"},
	"Stephe": {"type": types.mage, "stats": [20, 180], "moves": ["Growth", "Mass Infection"], "boon": "Blind"},
	
	"Jimmy": {"type": types.rogue, "stats": [40, 4], "moves": ["Below Blow", "Eye Poke"], "boon": "Scales"},
	"Bimmy": {"type": types.rogue, "stats": [35, 5], "moves": ["Brand", "Crusher Claw"], "boon": "Sword"},
	"Rimmy": {"type": types.rogue, "stats": [35, 5], "moves": ["Coldsteel", "Sideswipe"], "boon": "Cup"},
	"Timmy": {"type": types.rogue, "stats": [30, 6], "moves": ["Taunt", "Sucker Punch"], "boon": "Mask"},
	"Grimmy": {"type": types.rogue, "stats": [30, 6], "moves": ["Bonemerang", "Squalorbomb"], "boon": "Wings"},
	"Pimmy": {"type": types.rogue, "stats": [25, 7], "moves": ["Quick Attack", "Taste Test"], "boon": "Infinite"},
	"Slimmy": {"type": types.rogue, "stats": [25, 7], "moves": ["Firedance", "Flametongue"], "boon": "Tides"},
	"Mimmy": {"type": types.rogue, "stats": [20, 8], "moves": ["Shiv", "Back Rake"], "boon": "Weak"},
}

func _ready():
	#randomize()
	if global.storedParty.size() > 0:
		global.storedParty.clear()
	create_options()
	#$ColorRect/UI/MemberText.text = str("0/", PARTYSIZE, " Members Selected")

func create_options():
	for i in 3:
		var textLabeled = false
		Boons.chosen = i
		var vBoons = Boons.get_virtue_boons()
		for j in vBoons.size():
			totalBoons += 1
			var newSelect = BoonSelect.instance()
			newSelect.get_node("Button").set_scale(Vector2(.75,.75))
			var boonName = vBoons[j]
			newSelect.set_tooltip(Boons.generate_tooltip(boonName))
			$Choices.add_child(newSelect)
			newSelect.name = boonName
			newSelect.get_node("Button").text = boonName
			if !textLabeled:
				newSelect.get_node("Price").text = Boons.set_text()
				newSelect.get_node("Price").set_position(Vector2(605, -25))
				textLabeled = true
			var xPos = (i * INCREMENT) + (120 * j) - 465
			if j > 1: xPos -= 240
			newSelect.position.x = xPos
			newSelect.position.y = 30 if j <= 1 else 85
	var currentType = 0
	var currentMember = 0
	var pathStart = "Scrolls/"
	var pathEnd = "/ColorRect"
	get_node(pathStart + types.keys()[currentType] + pathEnd).rect_min_size.y = 28.3 * partyMembers.size() #it is what it is
	for member in partyMembers:
		if currentType != partyMembers[member]["type"]: 
			currentType = partyMembers[member]["type"]
			get_node(pathStart + types.keys()[currentType] + pathEnd).rect_min_size.y = 28.3 * partyMembers.size() #yeah we need to do this more
			currentMember = 0
		var choice = PartyChoice.instance()
		get_node(pathStart + types.keys()[currentType] + pathEnd).add_child(choice)
		setup_member(choice, member, currentType)
		choice.position.y = 85 * currentMember
		currentMember += 1
	for i in PARTYSIZE:
		var choice = PartyChoice.instance()
		$CurrentParty.add_child(choice)
		choice.position.y = 535
		choice.position.x = 300 + 415 * i
		choice.get_node("Button").disabled = true

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
			tempParty[0].chosen = false
			set_button_color(tempParty[0].get_node("Button"), partyMembers[tempParty[0].unitName]["type"])
			tempParty.pop_front()
		set_current_party()
		#$ColorRect/UI/MemberText.text = str(tempParty.size(), "/", PARTYSIZE, " Members Selected")
		check_start()

func set_current_party():
	for i in PARTYSIZE:
		var choice = $CurrentParty.get_child(i)
		choice.get_node("Text").visible = false
		set_button_color($CurrentParty.get_child(i).get_node("Button"), 3)
		$DisplayHolder.box_move(choice.get_node("Left"), "X")
		$DisplayHolder.box_move(choice.get_node("Right"), "X")
	for i in tempParty.size():
		$CurrentParty.get_child(i).get_node("Text").visible = true
		setup_member($CurrentParty.get_child(i), tempParty[i].unitName, partyMembers[tempParty[i].unitName]["type"])

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
	partyMembers.erase(choice.unitName)
	return unit

func select_pressed(boonSelect, reroll = false, autoTeam = true):
	if boonSelect.name == chosenBoon:
		if !reroll:
			set_button_color(boonSelect.get_node("Button"), types.none)
			chosenBoon = null
			#$ColorRect/UI/BoonText.text = "0/1 Boon Selected"
	else:
		if chosenBoon != null: set_button_color($Choices.get_node(chosenBoon).get_node("Button"), types.none)
		chosenBoon = boonSelect.name
		set_button_color(boonSelect.get_node("Button"), types.other)
		#$ColorRect/UI/BoonText.text = "1/1 Boon Selected"
	if chosenBoon and autoTeam:
		for scroll in $Scrolls.get_children():
			for choice in scroll.get_child(0).get_children():
				if partyMembers[choice.unitName]["boon"] == chosenBoon:
					choice._on_Button_pressed()
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
	$Scrolls.visible = false
	$CurrentParty.visible = false
	$ColorRect/UI.visible = false
	$ColorRect.margin_bottom = 460 #For between areas
	visible = false

func _on_Random_pressed():
	var reroll = false
	if chosenBoon and tempParty.size() == PARTYSIZE:
		reroll = true
		var i = tempParty.size() - 1
		while i >= 0:
			tempParty[i]._on_Button_pressed()
			i-=1
	if !chosenBoon or reroll:
		var randomBoon = randi() % totalBoons
		select_pressed($Choices.get_child(randomBoon), reroll, false)
	if tempParty.size() < PARTYSIZE:
		var availableMembers = []
		var i = 0
		while i < $Scrolls/fighter/ColorRect.get_child_count():
			if !tempParty.has($Scrolls/fighter/ColorRect.get_child(i)): availableMembers.append($Scrolls/fighter/ColorRect.get_child(i))
			i+=1
		i = 0
		while i < $Scrolls/mage/ColorRect.get_child_count():
			if !tempParty.has($Scrolls/mage/ColorRect.get_child(i)): availableMembers.append($Scrolls/mage/ColorRect.get_child(i))
			i+=1
		i = 0
		while i < $Scrolls/rogue/ColorRect.get_child_count():
			if !tempParty.has($Scrolls/rogue/ColorRect.get_child(i)): availableMembers.append($Scrolls/rogue/ColorRect.get_child(i))
			i+=1
		while tempParty.size() < PARTYSIZE:
			var rando = randi() % availableMembers.size()
			availableMembers[rando]._on_Button_pressed()
			availableMembers.remove(rando)

func _on_BoonRandom_pressed():
	var reroll = true if chosenBoon else false
	var randomBoon = randi() % totalBoons
	while $Choices.get_child(randomBoon).name == chosenBoon: #reroll if already chosen
		randomBoon = randi() % totalBoons
	select_pressed($Choices.get_child(randomBoon), reroll)
