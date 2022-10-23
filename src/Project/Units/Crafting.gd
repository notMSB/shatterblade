extends Node2D

#components
enum c {wing, fang, talon, sap, venom, fur, blade, bone, wood}

var products = {
	c.wing: {c.wing: "Speed Potion", c.fang: "Vampire", c.talon: "Dive Bomb", c.sap: "Dodge",
			c.venom: "Venoshock", c.fur: "Hide", c.blade: "Triple Hit", c.bone: "Flex",
			c.wood: "X"},
	
	c.fang: {c.fang: "Throwing Knife", c.talon: "Take Down", c.sap: "Constrict", c.venom: "Poison Strike",
			c.fur: "Cleave", c.blade: "Power Attack", c.bone: "Frostfang", c.wood:"X"},
	
	c.talon: {c.talon: "Brass Knuckles", c.sap: "Eye Poke", c.venom: "Taunt", c.fur: "Quick Attack",
			c.blade: "Crusher Claw", c.bone: "Turtle Up", c.wood:"X"},
	
	c.sap: {c.sap: "Health Potion", c.venom: "Growth", c.fur: "Protect", c.blade: "Pierce",
			c.bone: "Bonemerang", c.wood:"X"},
	
	c.venom: {c.venom: "Poison Potion", c.fur: "Restore", c.blade: "Piercing Sting", c.bone: "Plague",
			c.wood: "X"},
	
	c.fur: {c.fur: "Leather Buckler", c.blade: "Sucker Punch", c.bone: "Careful Strike", c.wood: "X"},
	
	c.blade: {c.blade: "Storm of Steel", c.bone: "Coldsteel", c.wood: "Channel Power"},
	
	c.bone: {c.bone: "Bone Zone", c.wood: "X"},
	
	c.wood: {c.wood: "X"}
}

func test():
	break_down("Quick Attack")

func sort_then_combine(one, two):
	if one <= two:
		return combine(one, two)
	else:
		return combine(two, one)

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
