extends Node

var enemyList = {
	"Bat": {"stats": [15, 6, 10], "passives": {"Dodgy": 1}, "specials": ["Vampire"], "rewards": [
		{"name": "Vampire", "type": "specials", "weight": 50},
		{"name": "Dodge", "type": "specials", "weight": 50}, 
		{"name": "Dodgy", "type": "passives", "weight": 5},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Bird": {"stats": [20, 8, 7], "specials": ["Dive Bomb", "Triple Hit"], "rewards": [
		{"name": "Dive Bomb", "type": "specials", "weight": 50}, 
		{"name": "Triple Hit", "type": "specials", "weight": 50},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Flower": {"stats": [15, 7, 1], "passives": {"Counter": 1}, "specials": ["Growth"], "rewards": [
		{"name": "Growth", "type": "specials", "weight": 50},
		{"name": "Sucker Punch", "type": "specials", "weight": 50}, 
		{"name": "Counter", "type": "passives", "weight": 5},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Rat": {"stats": [10, 5, 8], "passives": {"Dodgy": 1}, "specials": ["Plague"], "rewards": [
		{"name": "Plague", "type": "specials", "weight": 50},
		{"name": "Hide", "type": "specials", "weight": 50}, 
		{"name": "Dodgy", "type": "passives", "weight": 5},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Scorpion": {"stats": [25, 8, 6], "specials": ["Piercing Sting", "Crusher Claw"], "rewards": [
		{"name": "Piercing Sting", "type": "specials", "weight": 50}, 
		{"name": "Crusher Claw", "type": "specials", "weight": 50},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Skeleton": {"stats": [30, 7, 4], "specials": ["Power Attack", "Coldsteel"], "rewards": [
		{"name": "Power Attack", "type": "specials", "weight": 50}, 
		{"name": "Coldsteel", "type": "specials", "weight": 50},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Snake": {"stats": [15, 8, 6], "passives": {"Venomous": 0}, "specials": ["Constrict"], "rewards": [
		{"name": "Constrict", "type": "specials", "weight": 50},
		{"name": "Poison Strike", "type": "specials", "weight": 50}, 
		{"name": "Venomous", "type": "passives", "weight": 5},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
	"Wolf": {"stats": [25, 10, 7], "specials": ["Take Down", "Frostfang"], "rewards": [
		{"name": "Take Down", "type": "specials", "weight": 50}, 
		{"name": "Frostfang", "type": "specials", "weight": 50},
		{"name": "Money", "loot": true, "amount": 5, "weight": 50}
	]},
}
