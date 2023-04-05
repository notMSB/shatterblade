extends Node2D

export (PackedScene) var MoveBox

onready var Moves = $"../Moves"

const XSTART = 41
const YSTART = 21
const XINCREMENT = 79
const YINCREMENT = 59

#components
enum c {wing, fang, claw, sap, venom, fur, bone, garbage, darkness, blade, tentacle, flame}

var products = {
	c.wing: {c.wing: "Speed Potion", c.fang: "Vampire", c.claw: "Dive Bomb", c.sap: "Dodge",
			 c.venom: "Venoshock", c.fur: "Hide", c.bone: "Flex", c.garbage: "Goblin Dodge", 
			 c.darkness: "Invisibility", c.blade: "Triple Hit", c.tentacle: "Sideswipe", c.flame: "Icarus"},
	
	c.fang: {c.fang: "Throwing Knife", c.claw: "Take Down", c.sap: "Taste Test", c.venom: "Poison Strike",
			 c.fur: "Cleave", c.bone: "Frostfang", c.garbage: "Tasty Bite", c.darkness: "Feeding Frenzy", 
			 c.blade: "Power Attack", c.tentacle: "Below Blow", c.flame: "Flametongue"},
	
	c.claw: {c.claw: "Brass Knuckles", c.sap: "Eye Poke", c.venom: "Taunt", c.fur: "Quick Attack", 
			 c.bone: "Turtle Up", c.garbage: "Back Rake", c.darkness: "Breaker Slash", c.blade: "Crusher Claw", 
			 c.tentacle: "Grapple", c.flame: "Brand"},
	
	c.sap: {c.sap: "Health Potion", c.venom: "Growth", c.fur: "Protect", c.bone: "Bonemerang", 
			c.garbage: "Spit Shine", c.darkness: "Soul Sample", c.blade: "Pierce", c.tentacle: "Cold Spring",
			c.flame: "Fireball"},
	
	c.venom: {c.venom: "Poison Potion", c.fur: "Restore", c.bone: "Plague", c.garbage: "Belch", 
			  c.darkness: "Mass Infection", c.blade: "Piercing Sting", c.tentacle: "Constrict", c.flame: "Squalorbomb"},
	
	c.fur: {c.fur: "Tower Shield", c.bone: "Careful Strike", c.garbage: "Play Dead", c.darkness: "Defensive Pact", 
			c.blade: "Sucker Punch", c.tentacle: "Bulwark", c.flame: "Firewall"},
	
	c.bone: {c.bone: "Bone Zone", c.garbage: "Bone Club", c.darkness: "Seeker Volley", c.blade: "Coldsteel", 
			 c.tentacle: "Submersion", c.flame: "Combust"},
	
	c.garbage: {c.garbage: "Concoction", c.darkness: "Dark Dive", c.blade: "Shiv",  c.tentacle: "Meat Harvest",
				c.flame: "Wildfire"},
	
	c.darkness: {c.darkness: "Dark Matter", c.blade: "Dark Spikes", c.tentacle: "Eldritch Forces", c.flame: "Midnight Flare"},
	
	c.blade: {c.blade: "Storm of Steel", c.tentacle: "Deep Cut", c.flame: "Firedance"},
	
	c.tentacle: {c.tentacle: "Tentacle Jar", c.flame: "Monument"},
	
	c.flame: {c.flame: "Ring of Fire"}
}

func generate_grids():
	generate_equipment()
	generate_relics()
	generate_scales()

func generate_equipment():
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 0, 0)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 14, 0)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 15, 0)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 13, 0)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 0, 13)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 0, 14)
	setup_box("X", "EquipmentHolder/CraftScroll/ColorRect", 0, 15)
	for i in c.size():
		setup_box(c.keys()[i], "EquipmentHolder/CraftScroll/ColorRect", i+1, 0)
		setup_box(c.keys()[i], "EquipmentHolder/CraftScroll/ColorRect", 0, i+1)
		for j in c.size():
			if i<=j:
				setup_box(products[i][j], "EquipmentHolder/CraftScroll/ColorRect", i+1, j+1)
			else:
				setup_box(products[j][i], "EquipmentHolder/CraftScroll/ColorRect", i+1, j+1)

func generate_relics():
	setup_box("X", "RelicHolder", 0, 0)
	var i = 1
	var j = 0
	for move in Moves.moveList:
		var moveData = Moves.moveList[move]
		if moveData.has("slot") and moveData["slot"] == Moves.equipType.relic:
			if !moveData.has("unequippable") and moveData.has("rarity"):
				setup_box(move, "RelicHolder", i, j)
				i+=1
				if i > 15:
					i = 0
					j+=1
	setup_box("Crown", "RelicHolder", 0, j+2)

func generate_scales():
	setup_box("Rock", "ScalesHolder", 0, 0)
	setup_box("Stick", "ScalesHolder", 1, 0)

func setup_box(boxName, holderName, xMulti, yMulti):
	var box = MoveBox.instance()
	get_node(holderName).add_child(box)
	$DisplayHolder.box_move(box, boxName)
	box.position = Vector2(xMulti * XINCREMENT + XSTART, yMulti * YINCREMENT + YSTART)
	color_box(box, boxName)
	box.get_node("Tooltip").position.y += 200

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
