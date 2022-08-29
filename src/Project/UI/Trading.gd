extends Node2D

onready var Crafting = get_node("../Crafting")
onready var Enemies = get_node("../Enemies")
onready var Moves = get_node("../Moves")

var selectedBox
var values = {}
var stock = []
const DEFAULTVALUE = 5

func assign_component_values():
	var eList = Enemies.enemyList
	for component in Crafting.c:
		values[component] = DEFAULTVALUE
	for enemy in eList:
		for reward in eList[enemy]["rewards"]:
			values[reward] = max(1, values[reward] - 1)

func get_item_value(itemName):
	if typeof(itemName) == TYPE_INT or itemName == "X":
		return 0
	elif Crafting.c.has(itemName):
		return values[itemName]
	elif Moves.moveList[itemName].has("price"):
		return Moves.moveList[itemName]["price"]
	else:
		var items = Crafting.break_down(itemName)
		return get_item_value(items[0]) + get_item_value(items[1])

func get_inventory_value(inventory):
	var finalValue = 0
	for item in inventory:
		finalValue += get_item_value(item)
	print(finalValue)
	return finalValue
