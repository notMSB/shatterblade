extends Node2D

var Battle
var checkNode

func _ready():
	checkNode = $"../../../"
	Battle = checkNode if checkNode.name == "Battle" else null

func set_battle():
	Battle = checkNode.battleWindow

func _on_Button_pressed():
	if !Battle.visible:
		Battle.get_node("../Map").use_map_move(global.storedParty[get_index()])
	else:
		if Battle.chosenMove["target"] == Battle.Moves.targetType.ally:
			Battle.target_chosen(get_index())
		else:
			Battle.target_chosen(get_index() + global.storedParty.size())

func position_preview_rect(projectedHP = null, isPlayer = false):
	if !isPlayer:
		if projectedHP == 0 and Battle.Boons.playerBoons.has("Wings"): #might want to make this check faster down the line
			$BattleElements/PreviewRect.color = Color(.447, .447, 0, .392)
		else:
			$BattleElements/PreviewRect.color = Color(.447, 0, 0, .392)
	var multiplier = 132 if isPlayer else 200
	var differential = 66 if isPlayer else 50
	if projectedHP == null: projectedHP = $BattleElements/HPBar.value
	projectedHP = max(projectedHP, 0)
	var previewRect = get_node_or_null("BattleElements/PreviewRect")
	if previewRect:
		previewRect.margin_left = (projectedHP / $BattleElements/HPBar.max_value) * multiplier - differential
		previewRect.margin_right = ($BattleElements/HPBar.value / $BattleElements/HPBar.max_value) * multiplier - differential
