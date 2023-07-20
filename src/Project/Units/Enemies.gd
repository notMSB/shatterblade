extends Node2D

enum l {day, night, dungeon, special} #locations
enum b {plains, forest, mountain, city, battlefield, graveyard, none} #biomes

const MAXENCOUNTERSIZE = 4

onready var enemyList = {
	"PGoblin": {"stats": [6, 11, 20, 31, 44], "specials": ["Shiv"],
		"biome": b.plains, "rewards": ["garbage"], "locations": [l.day], "difficulty": 1, "sprite": "Goblin"},
	"PRat": {"stats": [4, 8, 16, 26, 35], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"biome": b.plains, "rewards": ["fur"], "locations": [l.day], "difficulty": 2, "sprite": "Rat"},
	"PSnake": {"stats": [13, 27, 36, 44, 50], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.plains, "rewards": ["venom"], "locations": [l.day], "difficulty": 3, "sprite": "Snake"},
	"PBird": {"stats": [12, 22, 34, 48, 56], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.plains, "rewards": ["wing"], "locations": [l.night], "difficulty": 1, "sprite": "Bird"},
	"PSkeleton": {"stats": [21, 32, 44, 58, 66], "specials": ["Power Attack", "Coldsteel"], 
		"biome": b.plains, "rewards": ["bone"], "locations": [l.night], "difficulty": 2, "sprite": "Skeleton"},
	
	"FFlower": {"stats": [5, 11, 25, 36, 50], "passives": {"Venomous": 0}, "specials": ["Soul Sample"], "hardSpecials": ["Careful Strike"],
		"biome": b.forest, "rewards": ["sap"], "locations": [l.day], "difficulty": 1, "sprite": "Flower"},
	"FWolf": {"stats": [11, 20, 32, 44, 57], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.forest, "rewards": ["claw"], "locations": [l.day], "difficulty": 2, "sprite": "Wolf"},
	"FSkeleton": {"stats": [18, 27, 36, 45, 654], "specials": ["Power Attack", "Careful Strike"], 
		"biome": b.forest, "rewards": ["bone"], "locations": [l.day], "difficulty": 3, "sprite": "Skeleton"},
	"FRat": {"stats": [4, 8, 16, 26, 35], "passives": {"Dodgy": 1}, "specials": ["Plague"], 
		"biome": b.forest, "rewards": ["fur"], "locations": [l.night], "difficulty": 1, "sprite": "Rat"},
	"FZombie": {"stats": [28, 38, 48, 58, 66], "specials": ["Dark Spikes"], "hardSpecials": ["Dark Dive"],
		"biome": b.forest, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	
	"MGoblin": {"stats": [6, 11, 20, 31, 44], "specials": ["Tasty Bite"], "hardSpecials": ["Dark Dive"],
		"biome": b.mountain, "rewards": ["garbage"], "locations": [l.day], "difficulty": 1, "sprite": "Goblin"},
	"MBird": {"stats": [15, 27, 39, 51, 66], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.mountain, "rewards": ["wing"], "locations": [l.day], "difficulty": 2, "sprite": "Bird"},
	"MWolf": {"stats": [21, 32, 44, 58, 66], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.mountain, "rewards": ["claw"], "locations": [l.day], "difficulty": 3, "sprite": "Wolf"},
	"MFlower": {"stats": [13, 20, 32, 44, 57], "passives": {"Thorns": 2}, "specials": ["Growth"], "hardSpecials": ["Careful Strike"],
		"biome": b.mountain, "rewards": ["sap"], "locations": [l.night], "difficulty": 1, "sprite": "Flower"},
	"MSnake": {"stats": [21, 32, 44, 58, 66], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.mountain, "rewards": ["venom"], "locations": [l.night], "difficulty": 2, "sprite": "Snake"},
	
	"CBat": {"stats": [6, 9, 14, 20, 27], "passives": {"Dodgy": 1}, "specials": ["Vampire"], 
		"biome": b.city, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"CGoblin": {"stats": [11, 20, 32, 44, 57], "specials": ["Dark Dive", "Feeding Frenzy"],
		"biome": b.city, "rewards": ["garbage"], "locations": [l.day], "difficulty": 2, "sprite": "Goblin"},
	"CSkeleton": {"stats": [15, 27, 39, 51, 66], "specials": ["Power Attack", "Coldsteel"], 
		"biome": b.city, "rewards": ["bone"], "locations": [l.day], "difficulty": 3, "sprite": "Skeleton"},
	"CBird": {"stats": [15, 27, 39, 51, 66], "specials": ["Triple Hit"], "hardSpecials": ["Dive Bomb"],
		"biome": b.city, "rewards": ["wing"], "locations": [l.night], "difficulty": 1, "sprite": "Bird"},
	"CZombie": {"stats": [22, 28, 34, 40, 46], "specials": ["Meat Harvest"], "hardSpecials": ["Dark Dive"],
		"biome": b.city, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	
	"BBat": {"stats": [6, 9, 14, 20, 27], "passives": {"Dodgy": 1}, "specials": ["Triple Hit"], 
		"biome": b.battlefield, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"BRat": {"stats": [11, 20, 32, 44, 57], "passives": {"Venomous": 0}, "specials": ["Careful Strike"], "hardSpecials": ["Triple Hit"],
		"biome": b.battlefield, "rewards": ["fur"], "locations": [l.day], "difficulty": 2, "sprite": "Rat"},
	"BFlower": {"stats": [15, 27, 39, 51, 66], "passives": {"Venomous": 0}, "specials": ["Seeker Volley"], "hardSpecials": ["Soul Sample"],
		"biome": b.battlefield, "rewards": ["sap"], "locations": [l.day], "difficulty": 3, "sprite": "Flower"},
	"BGoblin": {"stats": [6, 11, 20, 31, 44], "passives": {"Dodgy": 1}, "specials": ["Coldsteel"], "hardSpecials": ["Wildfire"],
		"biome": b.battlefield, "rewards": ["garbage"], "locations": [l.night], "difficulty": 1, "sprite": "Goblin"},
	"BZombie": {"stats": [28, 34, 40, 46, 52], "specials": ["Eldritch Forces"], "hardSpecials": ["Dark Spikes"],
		"biome": b.battlefield, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	
	"GBat": {"stats": [6, 11, 17, 24, 42], "specials": ["Feeding Frenzy"], 
		"biome": b.graveyard, "rewards": ["fang"], "locations": [l.day], "difficulty": 1, "sprite": "Bat"},
	"GSnake": {"stats": [11, 20, 32, 44, 57], "passives": {"Venomous": 0}, "specials": ["Constrict"], "hardSpecials": ["Venoshock"],
		"biome": b.graveyard, "rewards": ["venom"], "locations": [l.day], "difficulty": 2, "sprite": "Snake"},
	"GWolf": {"stats": [15, 27, 39, 51, 66], "specials": ["Frostfang"], "hardSpecials": ["Take Down"],
		"biome": b.graveyard, "rewards": ["claw"], "locations": [l.day], "difficulty": 3, "sprite": "Wolf"},
	"GSkeleton": {"stats": [15, 27, 39, 51, 66], "specials": ["Careful Strike", "Seeker Volley"], 
		"biome": b.graveyard, "rewards": ["bone"], "locations": [l.night], "difficulty": 1, "sprite": "Skeleton"},
	"GZombie": {"stats": [28, 34, 40, 46, 52], "specials": ["Dark Spikes", "Feeding Frenzy"], "hardSpecials": ["Mass Infection"],
		"biome": b.graveyard, "rewards": ["darkness"], "locations": [l.night], "difficulty": 2, "sprite": "Zombie"},
	
	"Kraken": {"stats": [19, 27, 35, 43, 51], "specials": ["Eldritch Forces"], "hardSpecials": ["Meat Harvest"],
		"biome": b.none, "rewards": ["tentacle"], "locations": [l.dungeon], "difficulty": 3, "sprite": "Kraken"},
	"Phoenix": {"stats": [15, 21, 27, 33, 39], "specials": ["Fireball"], "hardSpecials": ["Firewall"],
		"biome": b.none, "rewards": ["flame"], "locations": [l.dungeon], "difficulty": 3, "sprite": "Phoenix"},
	"Scorpion": {"stats": [17, 22, 27, 32, 37], "specials": ["Crusher Claw"], "hardSpecials": ["Piercing Sting"],
		"biome": b.none, "rewards": ["blade"], "locations": [l.dungeon], "difficulty": 3, "sprite": "Scorpion"},
	
	"BIG RAT": {"stats": [19, 25, 30, 34, 41], "passives": {"Dodgy": 3}, "specials": ["Careful Strike", "Mass Infection"], 
		"biome": b.none, "rewards": ["fur"], "locations": [l.special], "difficulty": 3, "sprite": "Rat", "elite": true},
	"BIG WOLF": {"stats": [35, 41, 47, 53, 59], "specials": ["Take Down", "Crusher Claw"],
		"biome": b.none, "rewards": ["claw"], "locations": [l.special], "difficulty": 3, "sprite": "Wolf", "elite": true},
	"BIG BIRD": {"stats": [32, 39, 46, 53, 60], "specials": ["Dive Bomb", "Dive Bomb"], "hardSpecials": ["Dive Bomb"],
		"biome": b.none, "rewards": ["wing"], "locations": [l.special], "difficulty": 3, "sprite": "Bird", "elite": true},
	"Dacula": {"stats": [44, 51, 58, 65, 72], "specials": ["Vampire", "Power Attack", "Take Down"], "hardSpecials": ["Feeding Frenzy"],
		"biome": b.none, "rewards": ["fang"], "locations": [l.special], "difficulty": 3, "sprite": "Vampire", "elite": true},
	"BIG FLOWER": {"stats": [28, 36, 44, 52, 60], "passives": {"Thorns": 2}, "specials": ["Seeker Volley", "Careful Strike", "Fireball"],
		"biome": b.none, "rewards": ["sap"], "locations": [l.special], "difficulty": 3, "sprite": "Flower", "elite": true},
	"BIG SNAKE": {"stats": [29, 38, 47, 56, 65], "passives": {"Venomous": 0}, "specials": ["Constrict", "Venoshock"],
		"biome": b.none, "rewards": ["venom"], "locations": [l.special], "difficulty": 3, "sprite": "Snake", "elite": true},
	"BIG GOBLIN": {"stats": [26, 33, 40, 47, 55], "passives": {"Dodgy": 2}, "specials": ["Shiv", "Meat Harvest", "Dark Dive"],
		"biome": b.none, "rewards": ["garbage"], "locations": [l.special], "difficulty": 3, "sprite": "Goblin", "elite": true},
	"BIG ZOMBIE": {"stats": [37, 46, 55, 64, 73], "specials": ["Feeding Frenzy", "Mass Infection", "Dark Dive"],
		"biome": b.none, "rewards": ["darkness"], "locations": [l.special], "difficulty": 3, "sprite": "Zombie", "elite": true},
	"BIG SKELETON": {"stats": [33, 44, 55, 66, 77], "specials": ["Submersion", "Frostfang", "Coldsteel", "Power Attack"],
		"biome": b.none, "rewards": ["bone"], "locations": [l.special], "difficulty": 3, "sprite": "Skeleton", "elite": true},
}

func generate_encounter(rating, isDay, biome, dungeonEnemy = null): #dungeon will bring its own list of valid enemies
	var location = l.day if isDay else l.night
	var strongestEnemy = 3 if isDay else 2
	var encounter = []
	var validEnemies = []
	if dungeonEnemy: validEnemies.append(dungeonEnemy)
	for enemy in enemyList:
		if enemyList[enemy]["locations"].has(location) and enemyList[enemy]["biome"] == biome:
			if !(dungeonEnemy and enemyList[enemy]["difficulty"] == enemyList[dungeonEnemy]["difficulty"]):
				validEnemies.append(enemy)
	if rating < 1: rating = 1
#	if seenElite: #only one elite per area
#		for enemy in validEnemies:
#			if enemyList[enemy].has("elite"):
#				validEnemies.erase(enemy)
#				strongestEnemy -= 1
#				break
	if rating > MAXENCOUNTERSIZE * strongestEnemy: rating = MAXENCOUNTERSIZE * strongestEnemy
	while rating > 0:
		if validEnemies.size() > 1: validEnemies = evaluate_list(validEnemies, rating, MAXENCOUNTERSIZE - encounter.size(), strongestEnemy)
		#print(validEnemies)
		var enemyIndicator = randi() % validEnemies.size()
		if rating == 4 and enemyIndicator == 0 and encounter.size() == 0:
			enemyIndicator+=randi() % (validEnemies.size()-1) + 1 #prevent 4wide encounters of just 1 enemy by forcing a higher difficulty one
		var nextEnemy = validEnemies[enemyIndicator]
		encounter.append(nextEnemy)
#		if enemyList[nextEnemy].has("elite"): 
#			validEnemies.erase(nextEnemy) #only one elite per encounter
#			strongestEnemy -= 1
#			var remainingSpaces = MAXENCOUNTERSIZE - encounter.size()
#			if rating > remainingSpaces * strongestEnemy: rating = remainingSpaces * strongestEnemy #needed to prevent 5stacks
		rating -= enemyList[nextEnemy]["difficulty"]
	if encounter.empty(): encounter.append(validEnemies[0]) #just in case something weird happens, avoids a softlock
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
