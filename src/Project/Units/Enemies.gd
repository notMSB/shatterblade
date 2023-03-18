extends Node2D

enum l {day, night, dungeon, special} #locations
enum b {plains, forest, mountain, city, battlefield, graveyard, none} #biomes

const MAXENCOUNTERSIZE = 4

onready var enemyList = {
	"PGoblin": {"stats": [6, 11, 13, 15, 17], "specials": ["Shiv"],
		"biome": b.plains, "rewards": ["garbage"], "locations": [l.day], "difficulty": 1, "sprite": "Goblin"},
	"PRat": {"stats": [6, 8, 10, 12, 14], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"biome": b.plains, "rewards": ["fur"], "locations": [l.day], "difficulty": 2, "sprite": "Rat"},
	"PSnake": {"stats": [13, 17, 20, 22, 24], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.plains, "rewards": ["venom"], "locations": [l.day], "difficulty": 3, "sprite": "Snake"},
	"PBird": {"stats": [12, 17, 19, 22, 24], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.plains, "rewards": ["wing"], "locations": [l.night], "difficulty": 1, "sprite": "Bird"},
	"PSkeleton": {"stats": [21, 28, 30, 32, 34], "specials": ["Power Attack", "Coldsteel"], 
		"biome": b.plains, "rewards": ["bone"], "locations": [l.night], "difficulty": 2, "sprite": "Skeleton"},
	"BIG RAT": {"stats": [9, 15, 20, 24, 31], "passives": {"Dodgy": 5}, "specials": ["Careful Strike", "Mass Infection"], 
		"biome": b.plains, "rewards": ["fur"], "locations": [l.night], "difficulty": 3, "sprite": "Rat", "elite": true},
	
	"FFlower": {"stats": [8, 12, 16, 20, 24], "passives": {"Thorns": 1}, "specials": ["Growth"], "hardSpecials": ["Careful Strike"],
		"biome": b.forest, "rewards": ["sap"], "locations": [l.day], "difficulty": 1, "sprite": "Flower"},
	"FWolf": {"stats": [11, 14, 18, 24, 27], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.forest, "rewards": ["claw"], "locations": [l.day], "difficulty": 2, "sprite": "Wolf"},
	"FSkeleton": {"stats": [15, 19, 23, 27, 31], "specials": ["Power Attack", "Coldsteel"], 
		"biome": b.forest, "rewards": ["bone"], "locations": [l.day], "difficulty": 3, "sprite": "Skeleton"},
	"FRat": {"stats": [6, 10, 14, 18, 22], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"biome": b.forest, "rewards": ["fur"], "locations": [l.night], "difficulty": 1, "sprite": "Rat"},
	"FZombie": {"stats": [28, 33, 38, 43, 48], "specials": ["Feeding Frenzy"], "hardSpecials": ["Dark Spikes"],
		"biome": b.forest, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	"BIG WOLF": {"stats": [35, 41, 47, 53, 59], "specials": ["Take Down", "Crusher Claw"],
		"biome": b.forest, "rewards": ["claw"], "locations": [l.night], "difficulty": 3, "sprite": "Wolf", "elite": true},
	
	"MGoblin": {"stats": [6, 11, 14, 18, 22], "specials": ["Tasty Bite"], "hardSpecials": ["Dark Dive"],
		"biome": b.mountain, "rewards": ["garbage"], "locations": [l.day], "difficulty": 1, "sprite": "Goblin"},
	"MBird": {"stats": [15, 20, 25, 30, 35], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.mountain, "rewards": ["wing"], "locations": [l.day], "difficulty": 2, "sprite": "Bird"},
	"MWolf": {"stats": [18, 22, 26, 30, 34], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.mountain, "rewards": ["claw"], "locations": [l.day], "difficulty": 3, "sprite": "Wolf"},
	"MFlower": {"stats": [8, 12, 16, 20, 24], "passives": {"Thorns": 1}, "specials": ["Growth"], "hardSpecials": ["Careful Strike"],
		"biome": b.mountain, "rewards": ["sap"], "locations": [l.night], "difficulty": 1, "sprite": "Flower"},
	"MSnake": {"stats": [21, 26, 31, 36, 41], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.mountain, "rewards": ["venom"], "locations": [l.night], "difficulty": 2, "sprite": "Snake"},
	"BIG BIRD": {"stats": [32, 39, 46, 53, 60], "specials": ["Dive Bomb", "Dive Bomb"], "hardSpecials": ["Dive Bomb"],
		"biome": b.mountain, "rewards": ["wing"], "locations": [l.night], "difficulty": 3, "sprite": "Bird", "elite": true},
	
	"CBat": {"stats": [4, 8, 12, 16, 20], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"biome": b.city, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"CGoblin": {"stats": [12, 17, 22, 27, 32], "specials": ["Dark Dive", "Shiv", "Tasty Bite"],
		"biome": b.city, "rewards": ["garbage"], "locations": [l.day], "difficulty": 2, "sprite": "Goblin"},
	"CSkeleton": {"stats": [15, 21, 27, 33, 39], "specials": ["Power Attack", "Coldsteel"], 
		"biome": b.city, "rewards": ["bone"], "locations": [l.day], "difficulty": 3, "sprite": "Skeleton"},
	"CBird": {"stats": [15, 19, 23, 27, 31], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.city, "rewards": ["wing"], "locations": [l.night], "difficulty": 1, "sprite": "Bird"},
	"CZombie": {"stats": [22, 28, 34, 40, 46], "specials": ["Dark Spikes"], "hardSpecials": ["Mass Infection"],
		"biome": b.city, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	"Dacula": {"stats": [44, 51, 58, 65, 72], "specials": ["Vampire", "Power Attack", "Take Down"], "hardSpecials": ["Cleave"],
		"biome": b.city, "rewards": ["fang"], "locations": [l.night], "difficulty": 3, "sprite": "Vampire", "elite": true},
	
	"BBat": {"stats": [4, 8, 12, 16, 20], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"biome": b.battlefield, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"BRat": {"stats": [10, 14, 18, 22, 26], "passives": {"Venomous": 0}, "specials": ["Careful Strike"], "hardSpecials": ["Triple Hit"],
		"biome": b.battlefield, "rewards": ["fur"], "locations": [l.day], "difficulty": 2, "sprite": "Rat"},
	"BFlower": {"stats": [13, 18, 23, 28, 33], "passives": {"Thorns": 1}, "specials": ["Plague"], "hardSpecials": ["Mass Infection"],
		"biome": b.battlefield, "rewards": ["sap"], "locations": [l.day], "difficulty": 3, "sprite": "Flower"},
	"BGoblin": {"stats": [5, 10, 15, 20, 25], "passives": {"Dodgy": 1}, "specials": ["Dark Dive"], "hardSpecials": ["Dark Dive"],
		"biome": b.battlefield, "rewards": ["garbage"], "locations": [l.night], "difficulty": 1, "sprite": "Goblin"},
	"BZombie": {"stats": [28, 34, 40, 46, 52], "specials": ["Dark Dive"], "hardSpecials": ["Mass Infection"],
		"biome": b.battlefield, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	"BIG FLOWER": {"stats": [33, 39, 45, 51, 57], "passives": {"Thorns": 3}, "specials": ["Seeker Volley", "Careful Strike"],
		"biome": b.battlefield, "rewards": ["sap"], "locations": [l.night], "difficulty": 3, "sprite": "Flower", "elite": true},
	
	"GBat": {"stats": [7, 11, 15, 19, 23], "specials": ["Feeding Frenzy"], 
		"biome": b.graveyard, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"GSnake": {"stats": [11, 16, 21, 26, 31], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.graveyard, "rewards": ["venom"], "locations": [l.day], "difficulty": 2, "sprite": "Snake"},
	"GWolf": {"stats": [11, 17, 23, 29, 35], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.graveyard, "rewards": ["claw"], "locations": [l.day], "difficulty": 3, "sprite": "Wolf"},
	"GSkeleton": {"stats": [13, 19, 25, 31, 37], "specials": ["Careful Strike", "Seeker Volley"], 
		"biome": b.graveyard, "rewards": ["bone"], "locations": [l.night], "difficulty": 1, "sprite": "Skeleton"},
	"GZombie": {"stats": [22, 30, 38, 46, 54], "specials": ["Dark Spikes", "Feeding Frenzy"], "hardSpecials": ["Mass Infection"],
		"biome": b.graveyard, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	"BIG SNAKE": {"stats": [37, 46, 55, 64, 73], "passives": {"Venomous": 0}, "specials": ["Constrict", "Venoshock"], "hardSpecials": ["Triple Hit"],
		"biome": b.graveyard, "rewards": ["venom"], "locations": [l.night], "difficulty": 3, "sprite": "Snake", "elite": true},
	
	"Kraken": {"stats": [19, 27, 35, 43, 51], "specials": ["Eldritch Forces"], "hardSpecials": ["Meat Harvest"],
		"biome": b.none, "rewards": ["tentacle"], "locations": [l.dungeon], "difficulty": 3, "sprite": "Kraken"},
	"Phoenix": {"stats": [1, 1], "specials": [], "hardSpecials": [],
		"biome": b.none, "rewards": ["blade"], "locations": [l.special], "difficulty": 3, "sprite": "Phoenix"},
	"Scorpion": {"stats": [17, 22, 27, 32, 37], "specials": ["Crusher Claw"], "hardSpecials": ["Piercing Sting"],
		"biome": b.none, "rewards": ["blade"], "locations": [l.dungeon], "difficulty": 3, "sprite": "Scorpion"},
}

func generate_encounter(rating, isDay, biome, dungeonEnemy = null, seenElite = false): #dungeon will bring its own list of valid enemies
	var strongestEnemy = 3
	var location = l.day if isDay else l.night
	var encounter = []
	var validEnemies = []
	if dungeonEnemy: validEnemies.append(dungeonEnemy)
	for enemy in enemyList:
		if enemyList[enemy]["locations"].has(location) and enemyList[enemy]["biome"] == biome:
			if !(dungeonEnemy and enemyList[enemy]["difficulty"] == enemyList[dungeonEnemy]["difficulty"]):
				validEnemies.append(enemy)
	if rating < 1: rating = 1
	if seenElite: #only one elite per area
		for enemy in validEnemies:
			if enemyList[enemy].has("elite"):
				validEnemies.erase(enemy)
				strongestEnemy -= 1
				break
	elif rating > MAXENCOUNTERSIZE * strongestEnemy: rating = MAXENCOUNTERSIZE * strongestEnemy
	while rating > 0:
		if validEnemies.size() > 1: validEnemies = evaluate_list(validEnemies, rating, MAXENCOUNTERSIZE - encounter.size(), strongestEnemy)
		#print(validEnemies)
		var nextEnemy = validEnemies[randi() % validEnemies.size()]
		encounter.append(nextEnemy)
		if enemyList[nextEnemy].has("elite"): 
			validEnemies.erase(nextEnemy) #only one elite per encounter
			strongestEnemy -= 1
			var remainingSpaces = MAXENCOUNTERSIZE - encounter.size()
			if rating > remainingSpaces * strongestEnemy: rating = remainingSpaces * strongestEnemy #needed to prevent 5stacks
		rating -= enemyList[nextEnemy]["difficulty"]
	return encounter

func evaluate_list(enemies, remainingRating, remainingSpaces, strongestEnemy): #makes sure an enemy cannot be chosen in a way that allows the encounter to no longer matches the rating
	var weakestAllowable = max(1, remainingRating - strongestEnemy * (remainingSpaces-1))
	var erasers = []
	for enemy in enemies:
		if enemyList[enemy]["difficulty"] < weakestAllowable or enemyList[enemy]["difficulty"] > remainingRating:
			erasers.append(enemy)
	for enemy in erasers:
		enemies.erase(enemy)
	return enemies
