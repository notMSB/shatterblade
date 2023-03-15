extends Node2D

var mapMode = false #mapmode is true for all normal gameplay, but not used during debug modes
var hardMode = false

func _ready():
	$Data/Crafting.generate_grids()

func _on_Toggle_pressed():
	$Party.visible = !$Party.visible
	$Puzzle.visible = !$Puzzle.visible


func _on_Table_pressed():
	$Data/Crafting/EquipmentHolder.visible = true
	$Party.visible = false
	$Puzzle.visible = false
	
