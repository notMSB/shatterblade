extends Node2D

var Battle
var checkNode

var fadeout = false

func _process(_delta):
	if fadeout:
		$Sprite.modulate.a -= .02
		if $Sprite.modulate.a <= 0 and $BattleElements/PopupManager.get_child_count() <= 0: faded()

func faded():
	visible = false

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

func position_preview_rect(projectedHP, unit):
	$BattleElements/HPBar/PreviewText.text = str(projectedHP, "/", $BattleElements/HPBar.max_value)
	if !unit.isPlayer: #might want to make this check faster down the line
		if ((Battle.Boons.playerBoons.has("Wings") and projectedHP == 0)
		or (Battle.Boons.playerBoons.has("Lion") and unit.killedMove == "" and projectedHP <= 0) 
		or (Battle.Boons.playerBoons.has("Crown") and unit.killedMove == "Crown" and projectedHP <= 0)):
			$BattleElements/PreviewRect.color = Color(.447, .447, 0, .392)
		else:
			$BattleElements/PreviewRect.color = Color(.447, 0, 0, .392)
	var multiplier = 132 if unit.isPlayer else 200
	var differential = 66 if unit.isPlayer else 50
	if projectedHP == null: projectedHP = $BattleElements/HPBar.value
	projectedHP = max(projectedHP, 0)
	var previewRect = get_node_or_null("BattleElements/PreviewRect")
	if previewRect:
		previewRect.margin_left = (projectedHP / $BattleElements/HPBar.max_value) * multiplier - differential
		previewRect.margin_right = ($BattleElements/HPBar.value / $BattleElements/HPBar.max_value) * multiplier - differential

func _on_HPBar_mouse_entered():
	if $BattleElements/PreviewRect.margin_left != $BattleElements/PreviewRect.margin_right and Battle.visible:
		$BattleElements/HPBar/Text.visible = false
		$BattleElements/HPBar/PreviewText.visible = true

func _on_HPBar_mouse_exited():
	if $BattleElements/PreviewRect.margin_left != $BattleElements/PreviewRect.margin_right:
		$BattleElements/HPBar/Text.visible = true
		$BattleElements/HPBar/PreviewText.visible = false

func _on_Button_mouse_entered():
	if Battle.visible: Battle.check_drag(self)
	else: Battle.get_node("../Inventory").check_drag(self)
