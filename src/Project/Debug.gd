extends Node2D

export (PackedScene) var Party
export (PackedScene) var Inventory
export (PackedScene) var Battle
export (PackedScene) var Map
onready var Game = get_parent()

func _on_Party_pressed():
	add_scene(Party)
	$Party.visible = false
	$Map.visible = true

func _on_Inventory_pressed():
	add_scene(Inventory)

func _on_Battle_pressed():
	add_scene(Battle)

func _on_Map_pressed():
	Game.mapMode = true
	add_scene(Map)
	visible = false

func add_scene(sceneName):
	Game.add_child(sceneName.instance())
