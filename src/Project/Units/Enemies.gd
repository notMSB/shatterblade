extends Node2D

enum l {day, night, dungeon} #locations

const MAXENCOUNTERSIZE = 4
var strongestEnemy = 3

onready var enemyList = {
	"Bat": {"stats": [5], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"rewards": ["wing"], "locations": [l.day], "difficulty": 1},
	"Bird": {"stats": [15], "specials": ["Dive Bomb", "Triple Hit"], 
		"rewards": ["talon"], "locations": [l.day], "difficulty": 3},
	"Flower": {"stats": [12], "passives": {"Thorns": 1}, "specials": ["Growth"], 
		"rewards": ["sap"], "locations": [l.dungeon], "difficulty": 1},
	"Rat": {"stats": [6], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"rewards": ["fur"], "locations": [l.night], "difficulty": 1},
	"Scorpion": {"stats": [17], "specials": ["Piercing Sting", "Crusher Claw"], 
		"rewards": ["blade"], "locations": [l.dungeon], "difficulty": 2},
	"Skeleton": {"stats": [21], "specials": ["Power Attack", "Coldsteel"], 
		"rewards": ["bone"], "locations": [l.night], "difficulty": 3},
	"Snake": {"stats": [11], "passives": {"Venomous": 0}, "specials": ["Constrict"], 
		"rewards": ["venom"], "locations": [l.day], "difficulty": 2},
	"Wolf": {"stats": [16], "specials": ["Take Down", "Frostfang"], 
		"rewards": ["fang"], "locations": [l.night], "difficulty": 2},
}

func get_dungeon_mascot():
	var dungeonEnemies = []
	for enemy in enemyList:
		if enemyList[enemy]["locations"].has(l.dungeon):
			dungeonEnemies.append(enemy)
	return dungeonEnemies[randi() % dungeonEnemies.size()]

func generate_encounter(rating, isDay, dungeonEnemy = null): #dungeon will bring its own list of valid enemies
	var location = l.day if isDay else l.night
	var encounter = []
	var validEnemies = []
	if dungeonEnemy: validEnemies.append(dungeonEnemy)
	for enemy in enemyList:
		if enemyList[enemy]["locations"].has(location):
			if !(dungeonEnemy and enemyList[enemy]["difficulty"] == enemyList[dungeonEnemy]["difficulty"]):
				validEnemies.append(enemy)
	if rating < 1: rating = 1
	elif rating > MAXENCOUNTERSIZE * strongestEnemy: rating = MAXENCOUNTERSIZE * strongestEnemy
	while rating > 0:
		if validEnemies.size() > 1: validEnemies = evaluate_list(validEnemies, rating, MAXENCOUNTERSIZE - encounter.size())
		#print(validEnemies)
		var nextEnemy = validEnemies[randi() % validEnemies.size()]
		encounter.append(nextEnemy)
		rating -= enemyList[nextEnemy]["difficulty"]
	return encounter

func evaluate_list(enemies, remainingRating, remainingSpaces): #makes sure an enemy cannot be chosen in a way that allows the encounter to no longer matches the rating
	var weakestAllowable = max(1, remainingRating - strongestEnemy * (remainingSpaces-1))
	var erasers = []
	for enemy in enemies:
		if enemyList[enemy]["difficulty"] < weakestAllowable or enemyList[enemy]["difficulty"] > remainingRating:
			erasers.append(enemy)
	for enemy in erasers:
		enemies.erase(enemy)
	return enemies
