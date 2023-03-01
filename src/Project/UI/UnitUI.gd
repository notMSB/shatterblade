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
	if !Battle.visible:
		Battle.get_node("../Map").use_map_move(global.storedParty[get_index()])
	else:
		if !fixTargets:
			Battle.target_chosen(get_index())
		else:
			Battle.target_chosen(get_index() + global.storedParty.size())

func position_preview_rect(projectedHP = null, isPlayer = false):
	var multiplier = 120 if isPlayer else 200
	var differential = 60 if isPlayer else 50
	if projectedHP == null: projectedHP = $BattleElements/HPBar.value
	projectedHP = max(projectedHP, 0)
	var previewRect = get_node_or_null("BattleElements/PreviewRect")
	if previewRect:
		previewRect.margin_left = (projectedHP / $BattleElements/HPBar.max_value) * multiplier - differential
		previewRect.margin_right = ($BattleElements/HPBar.value / $BattleElements/HPBar.max_value) * multiplier - differential
