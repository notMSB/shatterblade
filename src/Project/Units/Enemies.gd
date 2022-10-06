extends Node2D

enum l {day, night, dungeon} #locations

const MAXENCOUNTERSIZE = 4
var strongestEnemy = 3

onready var enemyList = {
	"Bat": {"stats": [15], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"rewards": ["wing"], "locations": [l.night], "difficulty": 1},
	"Bird": {"stats": [20], "specials": ["Dive Bomb", "Triple Hit"], 
		"rewards": ["talon"], "locations": [l.day], "difficulty": 3},
	"Flower": {"stats": [15], "passives": {"Counter": 1}, "specials": ["Growth"], 
		"rewards": ["sap"], "locations": [l.dungeon], "difficulty": 1},
	"Rat": {"stats": [10], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"rewards": ["fur"], "locations": [l.day], "difficulty": 1},
	"Scorpion": {"stats": [25], "specials": ["Piercing Sting", "Crusher Claw"], 
		"rewards": ["blade"], "locations": [l.dungeon], "difficulty": 1},
	"Skeleton": {"stats": [30], "specials": ["Power Attack", "Coldsteel"], 
		"rewards": ["bone"], "locations": [l.night], "difficulty": 3},
	"Snake": {"stats": [15], "passives": {"Venomous": 0}, "specials": ["Constrict"], 
		"rewards": ["venom"], "locations": [l.day], "difficulty": 2},
	"Wolf": {"stats": [25], "specials": ["Take Down", "Frostfang"], 
		"rewards": ["fang"], "locations": [l.night], "difficulty": 2},
}

func generate_encounter(rating, isDay):
	var location = l.day if isDay else l.night
	var validEnemies = []
	var encounter = []
	for enemy in enemyList:
		if enemyList[enemy]["locations"].has(location):
			validEnemies.append(enemy)
	if rating > MAXENCOUNTERSIZE * strongestEnemy: rating = MAXENCOUNTERSIZE * strongestEnemy
	while rating > 0:
		if validEnemies.size() > 1: validEnemies = evaluate_list(validEnemies, rating, MAXENCOUNTERSIZE - encounter.size())
		var nextEnemy = validEnemies[randi() % validEnemies.size()]
		encounter.append(nextEnemy)
		rating -= enemyList[nextEnemy]["difficulty"]
	return encounter

func evaluate_list(enemies, remainingRating, remainingSpaces): #makes sure an enemy cannot be chosen in a way that allows the encounter to no longer matches the rating
	var weakestAllowable = max(1, remainingRating - strongestEnemy * (remainingSpaces-1))
	for enemy in enemies:
		if enemyList[enemy]["difficulty"] < weakestAllowable or enemyList[enemy]["difficulty"] > remainingRating:
			enemies.erase(enemy)
	return enemies
