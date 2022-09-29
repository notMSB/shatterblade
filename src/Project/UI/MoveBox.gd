extends Node2D

onready var CheckScene = $"../../../"

const REPAIRVALUE = .5

var user
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

func updateInfo(targetName = null):
	if targetName:
		savedTargetName = targetName
	$Info.text = str(usageOrder, ": ", savedTargetName)

func set_mode_scene(): #returns battle, inventory, or map
	if CheckScene.name == "DisplayHolder": 
		CheckScene = CheckScene.get_node("../../")
	if CheckScene.name == "Map":
		if CheckScene.battleWindow.visible == true:
			return CheckScene.battleWindow
		elif CheckScene.inventoryWindow.visible == true:
			return CheckScene.inventoryWindow
	return CheckScene

func reduce_uses(amount):
	currentUses = max(0, currentUses - amount)
	set_uses()

func repair_uses():
	currentUses = min(maxUses, currentUses + ceil(maxUses * REPAIRVALUE)) #round up for odds
	set_uses()

func set_uses(var newMax = null):
	if newMax: 
		maxUses = newMax
		currentUses = newMax
		$Uses.max_value = newMax
	$Uses.visible = true if maxUses > 0 else false
	if visible: 
		$Uses.value = currentUses
		$Uses/Text.text = str(currentUses, "/", maxUses)

func _on_Button_pressed():
	boxModeScene = set_mode_scene()
	if boxModeScene.name == "Battle":
		if buttonMode:
			boxModeScene.evaluate_targets(moves[moveIndex], user, self)
		else:
			boxModeScene.cut_from_order(self)
	elif boxModeScene.name == "Inventory": #inventory
		boxModeScene.select_box(self)
	else: #map scene
		pass
