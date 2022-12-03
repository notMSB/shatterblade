extends Node2D

onready var Map = get_node("../../../")
onready var Inventory = get_node("../../../../Inventory")
onready var Crafting = get_node("../../../../Data/Crafting")
onready var Moves = get_node("../../../../Data/Moves")
onready var DisplayHolder = get_node("../../../HolderHolder/DisplayHolder")

func assemble(one, two):
	DisplayHolder.box_move($Leftbox, one)
	DisplayHolder.box_move($Rightbox, two)
	
	var productName = Crafting.sort_then_combine(Crafting.c.get(one), Crafting.c.get(two))
	DisplayHolder.box_move($Productbox, productName)
	$Productbox.set_uses(Moves.get_uses(productName))
	Inventory.identify_product($Productbox)

func _on_Button_pressed():
	Inventory.remove_component($Leftbox.get_node("Name").text)
	Inventory.remove_component($Rightbox.get_node("Name").text)
	Inventory.add_to_player($Productbox.get_node("Name").text)

func _on_Button_mouse_entered():
	if $Productbox/Tooltip/Label.text.length() > 0:
		$Productbox/Tooltip.visible = true

func _on_Button_mouse_exited():
	$Productbox/Tooltip.visible = false
