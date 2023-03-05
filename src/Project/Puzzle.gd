extends Node2D

export (PackedScene) var Player

onready var Boons = get_node("../Data/Boons")
onready var Enemies = get_node("../Data/Enemies")

const FIRSTMOVEBOX = 2 # 0/1 used for relics
const LASTMOVEBOX = 6
const SCALESINDEX = 1
const OFFSET = 2
const DEFAULTOPTION = "none"
const SCALESMOVES = ["Rock", "Stick"]

var selection
var enemyDifficulty = 0

var playerBoons = [0, 0, 0]
var boonLevels = [0, 0, 0]
var opponents = [DEFAULTOPTION, DEFAULTOPTION, DEFAULTOPTION, DEFAULTOPTION]

func _ready():
	for i in 4:
		var unit = Player.instance()
		unit.displayName = "Player"
		unit.moves = ["X", "X", "X", "X", "X"]
		var display = $HolderHolder/DisplayHolder.setup_player(unit, i)
		display.get_node("PuzzleMenu").visible = true
		display.get_node("MoveBoxes").visible = false
		display.get_node("MoveBoxes").get_child(LASTMOVEBOX).visible = false
	
	for boonSelector in $HolderHolder/BoonHolder.get_children():
		for boon in Boons.boonList:
			boonSelector.get_node("Choice").add_item(boon)
	
	for enemySelector in $HolderHolder/EnemyHolder.get_children():
		for enemy in Enemies.enemyList:
			enemySelector.get_node("Choice").add_item(enemy)

func show_grid(box):
	visible = false
	selection = box
	toggle_holder(box.get_index(), true)

func toggle_holder(boxIndex, toggle):
	if boxIndex < FIRSTMOVEBOX: get_node("../Data/Crafting/RelicHolder").visible = toggle
	elif boxIndex == FIRSTMOVEBOX and selection.get_parent().get_child(LASTMOVEBOX).visible == true: get_node("../Data/Crafting/ScalesHolder").visible = toggle
	else: get_node("../Data/Crafting/EquipmentHolder").visible = toggle

func set_box(boxName):
	var Moves = get_node("../Data/Moves")
	var allowedType = selection.get_node("../../PuzzleMenu").type
	if Moves.moveList.has(boxName):
		var type = Moves.moveList[boxName]["type"] - OFFSET #offset for relic types
		if type <= 0 or type == allowedType:
			toggle_holder(selection.get_index(), false)
			if SCALESMOVES.has(boxName): box_scales_move(selection, boxName)
			else: $HolderHolder/DisplayHolder.box_move(selection, boxName)
			$"../Data/Crafting".color_box(selection, boxName)
			selection = null
			visible = true

func choose_type(display):
	var i = 0
	for box in display.get_node("MoveBoxes").get_children():
		if i == 0: $HolderHolder/DisplayHolder.box_move(box, "Attack")
		elif i == 1: $HolderHolder/DisplayHolder.box_move(box, "Defend")
		elif i == 2 and display.get_node("MoveBoxes").get_child(LASTMOVEBOX).visible == true: box_scales_move(box)
		else: $HolderHolder/DisplayHolder.box_move(box, "X")
		box.get_node("ColorRect").color = Color(.53,.3,.3,1) #Default
		i+=1

func box_scales_move(box, moveName = SCALESMOVES[0]):
	for i in playerBoons.size():
		if playerBoons[i] == SCALESINDEX:
			if boonLevels[i] == 0: $HolderHolder/DisplayHolder.box_move(box, moveName)
			else: $HolderHolder/DisplayHolder.box_move(box, str(moveName, "+"))

func toggle_boon_choice(index, disabled:bool):
	check_special_boons(index, disabled)
	if index > 0:
		for boonSelector in $HolderHolder/BoonHolder.get_children():
			boonSelector.get_node("Choice").set_item_disabled(index,disabled)

func set_boon(selectorIndex, boonIndex):
	toggle_boon_choice(playerBoons[selectorIndex], false)
	#var boonName = $HolderHolder/BoonHolder.get_child(selectorIndex).get_node("Choice").get_item_text(boonIndex)
	playerBoons[selectorIndex] = boonIndex
	toggle_boon_choice(playerBoons[selectorIndex], true)
	
	#print(playerBoons)

func set_boon_level(selectorIndex, value):
	boonLevels[selectorIndex] = value
	var path = str("HolderHolder/BoonHolder/Boon ", selectorIndex, "/Choice")
	if get_node(path).get_item_text(selectorIndex) == "Scales":
		for display in $HolderHolder/DisplayHolder.get_children():
			box_scales_move(display.get_node("MoveBoxes").get_child(FIRSTMOVEBOX))

func check_special_boons(boonIndex, enabled:bool):
	var boonName = $"HolderHolder/BoonHolder/Boon 0/Choice".get_item_text(boonIndex)
	if boonName == "Scales":
		for display in $HolderHolder/DisplayHolder.get_children():
			var boxes = display.get_node("MoveBoxes")
			boxes.get_child(LASTMOVEBOX).visible = enabled
			var i = 0
			while i < LASTMOVEBOX - FIRSTMOVEBOX:
				var index = FIRSTMOVEBOX + i if !enabled else LASTMOVEBOX - i
				var boxName = boxes.get_child(index+1).moves[0] if !enabled else boxes.get_child(index-1).moves[0]
				$HolderHolder/DisplayHolder.box_move(boxes.get_child(index), boxName)
				$"../Data/Crafting".color_box(boxes.get_child(index), boxName)
				i += 1
			if enabled:
				box_scales_move(boxes.get_child(FIRSTMOVEBOX))
				display.get_node("MoveBoxes").get_child(FIRSTMOVEBOX).get_node("ColorRect").color = Color(.53,.3,.3,1)
			else:
				$HolderHolder/DisplayHolder.box_move(boxes.get_child(LASTMOVEBOX), "X")

func set_enemy(selectorIndex, enemyName):
	opponents[selectorIndex] = enemyName
	if enemyName == DEFAULTOPTION: #none
		$HolderHolder/EnemyHolder.get_child(selectorIndex).get_node("HPBar").visible = false
		$HolderHolder/EnemyHolder.get_child(selectorIndex).get_node("Sprite").visible = false
	else: #valid enemy
		set_enemy_bar($HolderHolder/EnemyHolder.get_child(selectorIndex))
		$HolderHolder/EnemyHolder.get_child(selectorIndex).get_node("Sprite").visible = true
		var spritePath = str("res://src/Assets/Enemies/", Enemies.enemyList[enemyName]["sprite"], ".png")
		var sprite = $HolderHolder/EnemyHolder.get_child(selectorIndex).get_node("Sprite")
		if(ResourceLoader.exists(spritePath)):
			sprite.texture = load(spritePath)
			sprite.flip_h = true
	print(opponents)

func set_enemy_bar(enemySelector):
	var enemyName = enemySelector.get_node("Choice").get_text()
	if enemyName != DEFAULTOPTION:
		var enemyHP = Enemies.enemyList[enemyName]["stats"][enemyDifficulty]
		enemySelector.get_node("HPBar").visible = true
		enemySelector.get_node("HPBar").max_value = enemyHP
		enemySelector.get_node("HPBar").value = enemyHP
		enemySelector.get_node("HPBar/Text").text = str(enemyHP, "/", enemyHP)

func _on_enemyLevel_value_changed(value):
	enemyDifficulty = value
	for enemySelector in $HolderHolder/EnemyHolder.get_children():
		set_enemy_bar(enemySelector)
