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
		var usedBox = $LeftComponent if i == 0 else $RightComponent
		DisplayHolder.box_move(usedBox, components[i])
		if !Inventory.find_box(components[i]): usedBox.get_node("Blackout").visible = true
	if $LeftComponent/Blackout.visible and $RightComponent/Blackout.visible: $Weapon/Blackout.visible = true

func fix_and_reset():
	originalBox.repair_uses(Inventory.repairBonus)
	Map.set_quick_panels()
	Inventory.reset_and_update_itemDict()
	Inventory.set_box_value(originalBox, originalBox.moves[0])

func _on_LeftButton_pressed():
	if Inventory.remove_component($LeftComponent.get_node("Name").text):
		fix_and_reset()

func _on_RightButton_pressed():
	if Inventory.remove_component($RightComponent.get_node("Name").text):
		fix_and_reset()

func _on_button_mouse_entered():
	if $Weapon/Tooltip/Label.text.length() > 0:
		$Weapon/Tooltip.visible = true

func _on_button_mouse_exited():
	$Weapon/Tooltip.visible = false
