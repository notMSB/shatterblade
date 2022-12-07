extends Node2D

var clickCost = null

func _on_Button_pressed():
	get_node("../../").select_pressed(self)

func set_tooltip(tip):
	var longestLineSize = 0
	var splits = tip.split("\n")
	var lineCount = splits.size()
	for line in splits:
		var length = $Tooltip/Label.get_font("font").get_string_size(line).x
		lineCount += floor(length / 225) #extra long descriptions
		if length > longestLineSize: longestLineSize = length
	if longestLineSize < 200:
		var offset = (200 - longestLineSize) / 2
		$Tooltip/Inside.margin_left += offset
		$Tooltip/Inside.margin_right -= offset
		$Tooltip/Background.margin_left += offset
		$Tooltip/Background.margin_right -= offset
	if lineCount != 5:
		var offset = (5 - lineCount) * 16
		$Tooltip/Inside.margin_bottom -= offset
		$Tooltip/Background.margin_bottom -= offset
		$Tooltip/Label.margin_bottom -= offset
	$Tooltip/Label.text = tip

func _on_Button_mouse_entered():
	$Tooltip.visible = true

func _on_Button_mouse_exited():
	$Tooltip.visible = false
