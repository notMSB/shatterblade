extends Node2D

onready var Battle = $"../../../../../"
var user
var move = "test"
var moveType
var resValue = 0
var usageOrder
var buttonMode = true
var savedTargetName = ""

func updateInfo(targetName = null):
	if targetName:
		savedTargetName = targetName
	$Info.text = str(usageOrder, ": ", savedTargetName)

func _on_Button_pressed():
	if buttonMode:
		Battle.evaluate_targets(move, user, self)
	else:
		Battle.cut_from_order(self)
