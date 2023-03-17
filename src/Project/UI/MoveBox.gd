extends Node2D

onready var CheckScene = $"../../../"

export var canMove = true #cursed items and craft/repair product boxes get this set false

const REPAIRVALUE = .5

var user

var isCursed = false
var mapUse = false

var moves = []
var moveIndex = 0
var moveType
var resValue = 0

var usageOrder
var trackerBar
var buttonMode = true
var savedTargetName = ""

var boxModeScene

var maxUses = 0
var currentUses = maxUses
var timesUsed = 0 #times used in current battle
var timesEnabled = 0

func updateInfo(targetName = null):
	if targetName:
		savedTargetName = targetName
	$Info.text = str(usageOrder, ": ", savedTargetName)

func set_mode_scene():
	if CheckScene.name == "DisplayHolder": 
		CheckScene = CheckScene.get_node("../../")
	elif CheckScene.name == "Events" or CheckScene.name == "RepairScroll" or CheckScene.name == "CraftScroll" or CheckScene.name == "HolderHolder": 
		CheckScene = CheckScene.get_node("../")
	if CheckScene.name == "Map" or CheckScene.name == "Puzzle":
		if CheckScene.battleWindow.visible == true:
			return CheckScene.battleWindow
		if CheckScene.name == "Map":
			return CheckScene.inventoryWindow
	return CheckScene

func reduce_uses(amount):
	currentUses = max(0, currentUses - amount)
	currentUses = min(currentUses, maxUses) #in the event that an effect puts the current too high
	set_uses()

func repair_uses(bonus = false):
	if bonus: currentUses = maxUses
	else: currentUses = min(maxUses, currentUses + ceil(maxUses * REPAIRVALUE)) #round up for odds
	set_uses()

func set_uses(var newMax = null):
	if newMax != null:
		maxUses = newMax
		currentUses = newMax
		$Uses.max_value = newMax
	else: #keeping the bar updated through swaps
		$Uses.max_value = maxUses
	$Uses.visible = true if maxUses > 0 else false
	if visible: 
		$Uses.value = currentUses
		$Uses/Text.text = str(currentUses, "/", maxUses)
		$Uses.rect_position.y = 7 if get_parent().name == "MoveBoxes" and get_index() <= 1 else 25

func change_rect_color(color):
	if $Sprite.visible: color.a = .5
	$ColorRect.color = color
	$ColorRect.visible = true

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
	$Tooltip/Label.text = tip

func _on_mouse_entered():
	if $Tooltip/Label.text.length() > 0:
		$Tooltip.visible = true

func _on_mouse_exited():
	$Tooltip.visible = false

func _on_Button_pressed():
	boxModeScene = set_mode_scene()
	match boxModeScene.name:
		"Inventory": #inventory
			var map = boxModeScene.get_node("../Map")
			if map.battleWindow.visible == true:
				pass #cannot click inventory items in battle
			elif !(isCursed and get_parent().name == "MoveBoxes") and canMove: 
				if mapUse:
					map.toggle_map_use(self)
				else:
					for child in map.get_node("HolderHolder/DisplayHolder").get_children():
						child.get_node("Button").visible = false
				boxModeScene.select_box(self)
			#else: boxModeScene.set_description($Name.text)
		"Battle":
			#boxModeScene.set_description($Name.text)
			if buttonMode:
				boxModeScene.evaluate_targets(moves[moveIndex], user, self)
			else:
				boxModeScene.cut_from_order(self)
		"Puzzle":
			boxModeScene.show_grid(self)
		"Data": #party or crafting grid
			$Tooltip.visible = false
			var Puzzle = boxModeScene.get_node("../Puzzle")
			if Puzzle.selection:
				Puzzle.set_box(moves[0])
			else:
				boxModeScene.get_node("Crafting/EquipmentHolder").visible = false
				boxModeScene.get_node("../Party").visible = true
				boxModeScene.get_node("../Toggle").visible = true
				boxModeScene.get_node("../Table").visible = true
		_: #map scene
			pass
