extends Node2D

onready var Map = get_node("../../../")
onready var Inventory = get_node("../../../../Inventory")
onready var Crafting = get_node("../../../../Data/Crafting")
onready var Moves = get_node("../../../../Data/Moves")
onready var DisplayHolder = get_node("../../../HolderHolder/DisplayHolder")

var originalBox

func disassemble(weaponName):
	var components = Crafting.break_down(weaponName)
	for i in components.size():
		if i == 0: DisplayHolder.box_move($LeftComponent, components[i])
		elif i == 1: DisplayHolder.box_move($RightComponent, components[i])

func fix_and_reset():
	originalBox.repair_uses()
	Map.set_quick_panels()
	Inventory.reset_and_update_itemDict()

func _on_LeftButton_pressed():
	if Inventory.remove_component($LeftComponent.get_node("Name").text):
		fix_and_reset()

func _on_RightButton_pressed():
	if Inventory.remove_component($RightComponent.get_node("Name").text):
		fix_and_reset()
