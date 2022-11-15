extends Node2D

#components
enum c {wing, fang, talon, sap, venom, fur, blade, bone, garbage, darkness}

var products = {
	c.wing: {c.wing: "Speed Potion", c.fang: "Vampire", c.talon: "Dive Bomb", c.sap: "Dodge",
			 c.venom: "Venoshock", c.fur: "Hide", c.blade: "Triple Hit", c.bone: "Flex",
			 c.garbage: "Goblin Dodge", c.darkness: "Invisibility"},
	
	c.fang: {c.fang: "Throwing Knife", c.talon: "Take Down", c.sap: "Constrict", c.venom: "Poison Strike",
			 c.fur: "Cleave", c.blade: "Power Attack", c.bone: "Frostfang", c.garbage: "Tasty Bite", 
			 c.darkness: "Taste Test"},
	
	c.talon: {c.talon: "Brass Knuckles", c.sap: "Eye Poke", c.venom: "Taunt", c.fur: "Quick Attack",
			  c.blade: "Crusher Claw", c.bone: "Turtle Up", c.garbage: "Back Rake", c.darkness: "Breaker Slash"},
	
	c.sap: {c.sap: "Health Potion", c.venom: "Growth", c.fur: "Protect", c.blade: "Pierce",
			c.bone: "Bonemerang", c.garbage: "Spit Shine", c.darkness: "Midnight Flare"},
	
	c.venom: {c.venom: "Poison Potion", c.fur: "Restore", c.blade: "Piercing Sting", c.bone: "Plague",
			  c.garbage: "Belch", c.darkness: "Mass Infection"},
	
	c.fur: {c.fur: "Leather Buckler", c.blade: "Sucker Punch", c.bone: "Careful Strike", c.garbage: "Play Dead",
			c.darkness: "Defense Pact"},
	
	c.blade: {c.blade: "Storm of Steel", c.bone: "Coldsteel", c.garbage: "Shiv", c.darkness: "Dark Spikes"},
	
	c.bone: {c.bone: "Bone Zone", c.garbage: "Bone Club", c.darkness: "Seeker Volley"},
	
	c.garbage: {c.garbage: "Concoction", c.darkness: "Dark Dive"},
	
	c.darkness: {c.darkness: "Dark Matter"}
}

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
