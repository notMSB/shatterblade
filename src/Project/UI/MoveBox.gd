extends Node2D

onready var CurrentScene = $"../../../../../" #Battle or Inventory are both equally ancient grandpas
var user
var moves = []
var moveIndex = 0
var moveType
var resValue = 0
var usageOrder
var trackerBar
var buttonMode = true
var savedTargetName = ""

func updateInfo(targetName = null):
	if targetName:
		savedTargetName = targetName
	$Info.text = str(usageOrder, ": ", savedTargetName)

func _on_Button_pressed():
	if CurrentScene.name == "Battle":
		if buttonMode:
			CurrentScene.evaluate_targets(moves[moveIndex], user, self)
		else:
			CurrentScene.cut_from_order(self)
	elif CurrentScene.name == "Inventory": #inventory
		CurrentScene.select_box(self)
	else: #map scene
		pass
