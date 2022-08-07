extends Node2D

onready var Crafting = get_node("../../Crafting")
onready var Enemies = get_node("../../Enemies")

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
	if itemName == "X":
		return 0
	elif Crafting.c.has(itemName):
		return values[itemName]
	else:
		var items = Crafting.break_down(itemName)
		return get_item_value(items[0]) + get_item_value(items[1])

func get_inventory_value(inventory):
	var finalValue = 0
	for item in inventory:
		finalValue += get_item_value(item)
	return finalValue
