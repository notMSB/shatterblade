extends Node2D

onready var DisplayHolder = get_node("../../../../../Party/DisplayHolder")

var playerLog : bool
var logUser
var logBox

func assemble(user, target, move, box = null):
	logUser = user
	if box: logBox = box
	$UserText.text = user.battleName
	if target != null and typeof(target) != TYPE_STRING: $TargetText.text = target.battleName
	else: $TargetText.text = ""
	DisplayHolder.box_move($MoveBox, move)
	$MoveBox.set_background()
	
	playerLog = user.isPlayer
	if !box: $Button.visible = false
	recolor()

func focus():
	$Background.color = Color(.5,.5,.1,1)

func recolor():
	if playerLog: $Background.color = Color(.3,.3,1,1)
	else: $Background.color = Color(1,.3,.3,1)

func _on_mouse_entered():
	if $MoveBox/Tooltip/Label.text.length() > 0:
		$MoveBox/Tooltip.visible = true

func _on_mouse_exited():
	$MoveBox/Tooltip.visible = false

func _on_Button_pressed():
	logBox._on_Button_pressed()
