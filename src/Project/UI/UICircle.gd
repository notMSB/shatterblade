extends Node2D

func set_letter(text):
	$Letter.text = text

func reposition_tooltip(amount):
	$Tooltip.position.x += amount

func set_tooltip_text(tip):
	$Tooltip/Background.margin_left = -120 #Need to reset all of these to default for each time a new move needs a tooltip generated
	$Tooltip/Background.margin_right = 120
	$Tooltip/Inside.margin_left = -117
	$Tooltip/Inside.margin_right = 117
	$Tooltip/Background.margin_top = -160
	$Tooltip/Inside.margin_top = -157
	$Tooltip/Label.margin_top = -157
	var longestLineSize = 0
	var splits = tip.split("\n")
	var lineCount = splits.size()
	for line in splits:
		var length = $Tooltip/Label.get_font("font").get_string_size(line).x
		if length > 225: lineCount += 1 #extra long descriptions
		if length > 375: lineCount +=1
		if length > 450: lineCount +=1
		if length > longestLineSize: longestLineSize = length
	if longestLineSize < 200:
		var offset = (200 - longestLineSize) / 2
		$Tooltip/Inside.margin_left += offset
		$Tooltip/Inside.margin_right -= offset
		$Tooltip/Background.margin_left += offset
		$Tooltip/Background.margin_right -= offset
	if lineCount < 5:
		var offset = (5 - lineCount) * 16
		$Tooltip/Inside.margin_top += offset
		$Tooltip/Background.margin_top += offset
		$Tooltip/Label.margin_top += offset
	if lineCount > 5:
		var offset = (lineCount - 5) * 16
		$Tooltip/Inside.margin_bottom += offset
		$Tooltip/Background.margin_bottom += offset
		$Tooltip/Label.margin_bottom += offset
	$Tooltip/Label.text = tip

func _on_Area2D_mouse_entered():
	$Tooltip.visible = true

func _on_Area2D_mouse_exited():
	$Tooltip.visible = false
