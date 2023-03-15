extends Node2D

enum indices {none, fighter, mage, rogue}

var type = 0
var health = 1
var resVal = 0

func _on_OptionButton_item_selected(index):
	type = index
	if index == 0: #none
		$Background.color = Color(.53,.3,.3,1) #Default
		$"../Sprite".modulate = Color(.53,.3,.3,1)
		$"../MoveBoxes".visible = false
	else:
		match index:
			indices.fighter: 
				$Background.color = Color(.9,.3,.3,1) #R
				$"../Sprite".modulate = Color(.9,.3,.3,1)
			indices.mage: 
				$Background.color = Color(.3,.3,.9,1) #B
				$"../Sprite".modulate = Color(.3,.3,.9,1)
			indices.rogue: 
				$Background.color = Color(.3,.7,.3,1) #G
				$"../Sprite".modulate = Color(.3,.7,.3,1)
		$"../MoveBoxes".visible = true
	get_parent().checkNode.choose_type(get_parent())

func _on_HP_Input_value_changed(value):
	health = value

func _on_Resource_Input_value_changed(value):
	resVal = value
