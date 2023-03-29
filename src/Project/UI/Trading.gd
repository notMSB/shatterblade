extends Node2D

onready var Crafting = get_node("../Crafting")
onready var Enemies = get_node("../Enemies")
onready var Moves = get_node("../Moves")

var selectedBox
var values = {}
var stock = []
const RELICDEFAULTPRICE = 7
const DEFAULTVALUE = 5

func assign_component_values(biome, dungeonMascot):
	var eList = Enemies.enemyList
	var validEnemies = []
	for enemy in eList:
		if eList[enemy]["biome"] == biome:
			validEnemies.append(enemy)
	validEnemies.append(dungeonMascot)
	for component in Crafting.c:
		values[component] = DEFAULTVALUE
	for enemy in validEnemies:
		if eList[enemy]["locations"].has(Enemies.l.day):
			for reward in eList[enemy]["rewards"]:
				values[reward] = DEFAULTVALUE - 3
		elif eList[enemy]["locations"].has(Enemies.l.night):
			for reward in eList[enemy]["rewards"]:
				values[reward] = DEFAULTVALUE - 2
		elif eList[enemy]["locations"].has(Enemies.l.dungeon):
			for reward in eList[enemy]["rewards"]:
				values[reward] = DEFAULTVALUE - 1
	

func get_item_value(itemName, box = null):
	var value = 0
	if Crafting.c.has(itemName):
		
		return values[itemName]
	if typeof(itemName) == TYPE_INT or itemName == "X" or Moves.moveList[itemName]["type"] == Moves.moveType.basic:
		return 0
	elif Moves.moveList[itemName].has("price"):
		value = Moves.moveList[itemName]["price"]
	elif Moves.moveList[itemName]["slot"] == Moves.equipType.relic:
		value = RELICDEFAULTPRICE
	else:
		var items = Crafting.break_down(itemName)
		value = get_item_value(items[0]) + get_item_value(items[1])
	if box and box.maxUses > 1: #damaged item eval
		value = max(ceil(value * box.currentUses / box.maxUses), 1) #subject to change, but currently broken weapons shouldn't have a value of 0
	return value

func get_inventory_value(inventory):
	var finalValue = 0
	for item in inventory:
		finalValue += get_item_value(item)
	return finalValue
