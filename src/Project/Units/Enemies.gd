extends Node2D

enum l {day, night, dungeon} #locations

onready var enemyList = {
	"Bat": {"stats": [15], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"rewards": ["wing"], "locations": [l.night], "difficulty": 3},
	"Bird": {"stats": [20], "specials": ["Dive Bomb", "Triple Hit"], 
		"rewards": ["talon"], "locations": [l.day], "difficulty": 3},
	"Flower": {"stats": [15], "passives": {"Counter": 1}, "specials": ["Growth"], 
		"rewards": ["sap"], "locations": [l.dungeon], "difficulty": 3},
	"Rat": {"stats": [10], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"rewards": ["fur"], "locations": [l.day], "difficulty": 1},
	"Scorpion": {"stats": [25], "specials": ["Piercing Sting", "Crusher Claw"], 
		"rewards": ["blade"], "locations": [l.dungeon], "difficulty": 3},
	"Skeleton": {"stats": [30], "specials": ["Power Attack", "Coldsteel"], 
		"rewards": ["bone"], "locations": [l.night], "difficulty": 3},
	"Snake": {"stats": [15], "passives": {"Venomous": 0}, "specials": ["Constrict"], 
		"rewards": ["venom"], "locations": [l.day], "difficulty": 2},
	"Wolf": {"stats": [25], "specials": ["Take Down", "Frostfang"], 
		"rewards": ["fang"], "locations": [l.night], "difficulty": 3},
}
