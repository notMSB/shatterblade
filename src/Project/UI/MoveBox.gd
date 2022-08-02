extends Node2D

onready var CurrentScene = $"../../../../../" #Battle, Inventory, and Map are all equally ancient grandpas
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

func updateInfo(targetName = null):
	if targetName:
		savedTargetName = targetName
	$Info.text = str(usageOrder, ": ", savedTargetName)

func set_mode_scene():
	if CurrentScene.name != "Battle" and CurrentScene.name != "Inventory": #map scene
		if CurrentScene.battleWindow.visible == true:
			return CurrentScene.battleWindow
		elif CurrentScene.inventoryWindow.visible == true:
			return CurrentScene.inventoryWindow
	return CurrentScene

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
