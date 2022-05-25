extends Node2D

#components
enum c {wing, fang, talon, sap, venom, fur, blade, bone, wood}

var products = {
	c.wing: {c.wing: "X", c.fang: "Vampire", c.talon: "Dive Bomb", c.sap: "Dodge",
			c.venom: "Venoshock", c.fur: "Hide", c.blade: "Triple Hit", c.bone: "Flex",
			c.wood: "X"},
	
	c.fang: {c.fang: "X", c.talon: "Take Down", c.sap: "Constrict", c.venom: "Poison Strike",
			c.fur: "Cleave", c.blade: "Power Attack", c.bone: "Frostfang", c.wood:"X"},
	
	c.talon: {c.talon: "X", c.sap: "Eye Poke", c.venom: "Taunt", c.fur: "Quick Attack",
			c.blade: "Crusher Claw", c.bone: "Turtle Up", c.wood:"X"},
	
	c.sap: {c.sap: "X", c.venom: "Growth", c.fur: "Protect", c.blade: "Pierce",
			c.bone: "Bonemerang", c.wood:"X"},
	
	c.venom: {c.venom: "X", c.fur: "Restore", c.blade: "Piercing Sting", c.bone: "Plague",
			c.wood: "X"},
	
	c.fur: {c.fur: "X", c.blade: "Sucker Punch", c.bone: "Careful Strike", c.wood: "X"},
	
	c.blade: {c.blade: "X", c.bone: "Coldsteel", c.wood: "X"},
	
	c.bone: {c.bone: "X", c.wood: "X"},
	
	c.wood: {c.wood: "X"}
}

func test():
	sort_then_combine(c.blade, c.fur)

func sort_then_combine(one, two):
	if one <= two:
		return combine(one, two)
	else:
		return combine(two, one)

func combine(one, two):
	return products[one][two]
	
