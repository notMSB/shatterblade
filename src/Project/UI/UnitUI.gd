extends Node2D

var Battle
var checkNode
var fixTargets = false

func _ready():
	checkNode = $"../../../"
	Battle = checkNode if checkNode.name == "Battle" else null

func set_battle():
	Battle = checkNode.battleWindow

func check_mode():
	if Battle.get_parent().mapMode:
		fixTargets = true

func _on_Button_pressed():
	if !fixTargets:
		Battle.target_chosen(get_index())
	else:
		Battle.target_chosen(get_index() + Battle.partyNum)
