extends Node2D

export (PackedScene) var MoveBox

onready var Moves = $"../Moves"

const XSTART = 45
const YSTART = 25
const XINCREMENT = 80
const YINCREMENT = 60

#components
enum c {wing, fang, claw, sap, venom, fur, blade, bone, garbage, darkness, tentacle}

var products = {
	c.wing: {c.wing: "Speed Potion", c.fang: "Vampire", c.claw: "Dive Bomb", c.sap: "Dodge",
			 c.venom: "Venoshock", c.fur: "Hide", c.blade: "Triple Hit", c.bone: "Flex",
			 c.garbage: "Goblin Dodge", c.darkness: "Invisibility", c.tentacle: "X"},
	
	c.fang: {c.fang: "Throwing Knife", c.claw: "Take Down", c.sap: "Taste Test", c.venom: "Poison Strike",
			 c.fur: "Cleave", c.blade: "Power Attack", c.bone: "Frostfang", c.garbage: "Tasty Bite", 
			 c.darkness: "Feeding Frenzy", c.tentacle: "X"},
	
	c.claw: {c.claw: "Brass Knuckles", c.sap: "Eye Poke", c.venom: "Taunt", c.fur: "Quick Attack",
			  c.blade: "Crusher Claw", c.bone: "Turtle Up", c.garbage: "Back Rake", c.darkness: "Breaker Slash", c.tentacle: "X"},
	
	c.sap: {c.sap: "Health Potion", c.venom: "Growth", c.fur: "Protect", c.blade: "Pierce",
			c.bone: "Bonemerang", c.garbage: "Spit Shine", c.darkness: "Midnight Flare", c.tentacle: "X"},
	
	c.venom: {c.venom: "Poison Potion", c.fur: "Restore", c.blade: "Piercing Sting", c.bone: "Plague",
			  c.garbage: "Belch", c.darkness: "Mass Infection", c.tentacle: "Constrict"},
	
	c.fur: {c.fur: "Leather Buckler", c.blade: "Sucker Punch", c.bone: "Careful Strike", c.garbage: "Play Dead",
			c.darkness: "Defensive Pact", c.tentacle: "X"},
	
	c.blade: {c.blade: "Storm of Steel", c.bone: "Coldsteel", c.garbage: "Shiv", c.darkness: "Dark Spikes", c.tentacle: "X"},
	
	c.bone: {c.bone: "Bone Zone", c.garbage: "Bone Club", c.darkness: "Seeker Volley", c.tentacle: "X"},
	
	c.garbage: {c.garbage: "Concoction", c.darkness: "Dark Dive", c.tentacle: "X"},
	
	c.darkness: {c.darkness: "Dark Matter", c.tentacle: "X"},
	
	c.tentacle: {c.tentacle: "X"}
}

func generate_grids():
	generate_equipment()
	generate_relics()
	generate_scales()

func generate_equipment():
	setup_box("X", "EquipmentHolder", 0, 0)
	for i in c.size():
		setup_box(c.keys()[i], "EquipmentHolder", i+1, 0)
		setup_box(c.keys()[i], "EquipmentHolder", 0, i+1)
		for j in c.size():
			if i<=j:
				setup_box(products[i][j], "EquipmentHolder", i+1, j+1)
			else:
				setup_box(products[j][i], "EquipmentHolder", i+1, j+1)

func generate_relics():
	var i = 0
	for move in Moves.moveList:
		var moveData = Moves.moveList[move]
		if moveData.has("slot") and moveData["slot"] == Moves.equipType.relic:
			if !moveData.has("unequippable") and moveData.has("rarity"):
				setup_box(move, "RelicHolder", i, 0)
				i+=1

func generate_scales():
	setup_box("Rock", "ScalesHolder", 0, 0)
	setup_box("Stick", "ScalesHolder", 1, 0)

func setup_box(boxName, holderName, xMulti, yMulti):
	var box = MoveBox.instance()
	get_node(holderName).add_child(box)
	$DisplayHolder.box_move(box, boxName)
	box.position = Vector2(xMulti * XINCREMENT + XSTART, yMulti * YINCREMENT + YSTART)
	color_box(box, boxName)

func color_box(box, boxName):
	if Moves.moveList.has(boxName) and !box.get_node("Sprite").visible:
		var productType = Moves.moveList[boxName]["type"]
		box.moveType = productType
		if productType == Moves.moveType.special: box.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
		elif productType == Moves.moveType.trick: box.get_node("ColorRect").color = Color(.3,.7,.3,1) #G
		elif productType == Moves.moveType.magic: box.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
		elif productType == Moves.moveType.item:  box.get_node("ColorRect").color = Color(.9,.7, 0,1) #Y
		else: box.get_node("ColorRect").color = Color(.53,.3,.3,1) #Default

func test():
	break_down("Quick Attack")

func sort_then_combine(one, two):
	if one != null and two != null: #(if one and two:) doesn't work; the 0th component hits false
		if one <= two:
			return combine(one, two)
		else:
			return combine(two, one)
	return "X"

func combine(one, two):
	return products[one][two]

func break_down(moveName):
	if moveName == "X": return null
	for i in products.size():
		for j in products[i].size():
			if products[i][i+j] == moveName:
				#print(str(c.keys()[i]), "  ", c.keys()[i+j])
				return [c.keys()[i], c.keys()[i+j]]
	return [0,0]
