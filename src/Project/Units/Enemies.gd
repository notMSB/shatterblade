extends Node

var enemyList = {
	"Bat": {"stats": [15], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"rewards": ["wing", "fang"]},
	"Bird": {"stats": [20], "specials": ["Dive Bomb", "Triple Hit"], 
		"rewards": ["wing", "talon"]},
	"Flower": {"stats": [15], "passives": {"Counter": 1}, "specials": ["Growth"], 
		"rewards": ["sap", "venom"]},
	"Rat": {"stats": [10], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"rewards": ["fur", "fang"]},
	"Scorpion": {"stats": [25], "specials": ["Piercing Sting", "Crusher Claw"], 
		"rewards": ["blade", "venom"]},
	"Skeleton": {"stats": [30], "specials": ["Power Attack", "Coldsteel"], 
		"rewards": ["blade", "bone"]},
	"Snake": {"stats": [15], "passives": {"Venomous": 0}, "specials": ["Constrict"], 
		"rewards": ["fang", "venom"]},
	"Wolf": {"stats": [25], "specials": ["Take Down", "Frostfang"], 
		"rewards": ["fur", "fang"]},
}
