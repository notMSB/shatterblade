extends Node2D

onready var Party = get_node("../../")

var unitName
var chosen = false

func _on_Button_pressed():
	Party.choose_member(self)
