extends Node2D

#components
enum c {wing, fang, talon, sap, venom, fur, blade, bone}

var products = {
	c.wing: {c.wing: "X", c.fang: "Vampire", c.talon: "Dive Bomb", c.sap: "Dodge"
			,c.venom: "Venoshock", c.fur: "Hide", c.blade: "Triple Hit", c.bone: "Flex"},
	
	c.fang: {c.fang: "X", c.talon: "Take Down", c.sap: "Constrict"
			,c.venom: "Poison Strike", c.fur: "Cleave", c.blade: "Power Attack", c.bone: "Frostfang"},
	
	c.talon: {c.talon: "X", c.sap: "Eye Poke"
			,c.venom: "Taunt", c.fur: "Quick Attack", c.blade: "Crusher Claw", c.bone: "Turtle Up"},
	
	c.sap: {c.sap: "X", c.venom: "Growth", c.fur: "Protect", c.blade: "Pierce", c.bone: "Bonemerang"},
	
	c.venom: {c.venom: "X", c.fur: "Restore", c.blade: "Piercing Sting", c.bone: "Plague"},
	
	c.fur: {c.fur: "X", c.blade: "Sucker Punch", c.bone: "Careful Strike"},
	
	c.blade: {c.blade: "X", c.bone: "Coldsteel"},
	
	c.bone: {c.bone: "X"}
}

func test():
	sort_then_combine(c.blade, c.fur)

func sort_then_combine(one, two):
	if one <= two:
		combine(one, two)
	else:
		combine(two, one)

func combine(one, two):
	print(products[one][two])
	
