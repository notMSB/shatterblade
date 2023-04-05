extends Node2D

export (PackedScene) var Player

onready var Moves = get_node("../Data/Moves")
onready var Boons = get_node("../Data/Boons")
onready var Enemies = get_node("../Data/Enemies")
onready var battleWindow = get_node("../Battle")

const FIRSTMOVEBOX = 2 # 0/1 used for relics
const LASTMOVEBOX = 6
const SCALESINDEX = 1
const OFFSET = 2
const DEFAULTOPTION = "none"
const SCALESMOVES = ["Snapshot", "Line Drive", "Sidewinder"]

var selection
var enemyDifficulty = 0

var units = []
var playerBoons = [0, 0, 0]
var boonLevels = [[false, false], [false, false], [false, false]]
var opponents = [DEFAULTOPTION, DEFAULTOPTION, DEFAULTOPTION, DEFAULTOPTION]

func _ready():
	for i in 4:
		var unit = Player.instance()
		unit.displayName = str("Player ", i+1)
		unit.moves = ["X", "X", "X", "X", "X"]
		var display = $HolderHolder/DisplayHolder.setup_player(unit, i)
		unit.ui = display
		unit.battleName = str("P", i)
		display.get_node("PuzzleMenu").visible = true
		display.get_node("MoveBoxes").visible = false
		display.get_node("MoveBoxes").get_child(LASTMOVEBOX).visible = false
		display.set_battle()
		units.append(unit)
	
	for boonSelector in $HolderHolder/BoonHolder.get_children():
		for boon in Boons.boonList:
			boonSelector.get_node("Choice").add_item(boon)
	
	for enemySelector in $HolderHolder/EnemyHolder.get_children():
		for enemy in Enemies.enemyList:
			enemySelector.get_node("Choice").add_item(enemy)

func show_grid(box):
	visible = false
	$"../Toggle".visible = false
	$"../Table".visible = false
	selection = box
	toggle_holder(box.get_index(), true)

func toggle_holder(boxIndex, toggle):
	if boxIndex < FIRSTMOVEBOX: get_node("../Data/Crafting/RelicHolder").visible = toggle
	elif boxIndex == FIRSTMOVEBOX and selection.get_parent().get_child(LASTMOVEBOX).visible == true: get_node("../Data/Crafting/ScalesHolder").visible = toggle
	else: get_node("../Data/Crafting/EquipmentHolder").visible = toggle

func set_box(boxName):
	var allowedType = selection.get_node("../../PuzzleMenu").type
	if Moves.moveList.has(boxName):
		var type = Moves.moveList[boxName]["type"] - OFFSET #offset for relic types
		if type <= 0 or type == allowedType:
			toggle_holder(selection.get_index(), false)
			if SCALESMOVES.has(boxName): box_scales_move(selection, boxName)
			elif boxName == "Crown": check_crown(selection)
			else: $HolderHolder/DisplayHolder.box_move(selection, boxName)
			selection.set_uses(Moves.get_uses(boxName))
			var moveInfo = Moves.moveList[boxName] #Now, make sure attack/defend is done right
			if (selection.get_index() <= 1 #X or attack/defend
			and (moveInfo["type"] == Moves.moveType.basic or moveInfo["slot"] == Moves.equipType.any)): 
				if selection.get_index() == 0: #attack
					$HolderHolder/DisplayHolder.box_move(selection, "Attack")
				else: #defend
					$HolderHolder/DisplayHolder.box_move(selection, "Defend")
			elif moveInfo.has("morph"): #power glove
				$HolderHolder/DisplayHolder.box_move(selection, moveInfo["morph"][selection.get_index()])
			selection.get_node("Tooltip").visible = false
			$"../Data/Crafting".color_box(selection, boxName)
			selection = null
			visible = true
			$"../Toggle".visible = true
			$"../Table".visible = true

func choose_type(display):
	var i = 0
	for box in display.get_node("MoveBoxes").get_children():
		if i == 0: $HolderHolder/DisplayHolder.box_move(box, "Attack")
		elif i == 1: $HolderHolder/DisplayHolder.box_move(box, "Defend")
		elif i == 2 and display.get_node("MoveBoxes").get_child(LASTMOVEBOX).visible == true: box_scales_move(box)
		else: $HolderHolder/DisplayHolder.box_move(box, "X")
		box.get_node("ColorRect").color = Color(.53,.3,.3,1) #Default
		i+=1
	check_ready()

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
	if value == 0: boonLevels[selectorIndex] = [false, false] #Bronze
	elif value == 1: boonLevels[selectorIndex] = [true, false] #Silver
	elif value == 2: boonLevels[selectorIndex] = [false, true] #Gold
	else: boonLevels[selectorIndex] = [true, true] #Platinum
	var path = str("HolderHolder/BoonHolder/Boon ", selectorIndex, "/Choice")
	if get_node(path).get_item_text(playerBoons[selectorIndex]) == "Scales":
		for display in $HolderHolder/DisplayHolder.get_children():
			box_scales_move(display.get_node("MoveBoxes").get_child(FIRSTMOVEBOX))
	elif get_node(path).get_item_text(playerBoons[selectorIndex]) == "Crown":
		for display in $HolderHolder/DisplayHolder.get_children():
			for box in display.get_node("MoveBoxes").get_children():
				if box.moves[0] == "Crown" or box.moves[0] == "Crown+": check_crown(box)

func check_crown(box):
	var level
	for boonIndex in playerBoons.size():
		var boonName = $"HolderHolder/BoonHolder/Boon 0/Choice".get_item_text(playerBoons[boonIndex])
		if boonName == "Crown": level = boonLevels[boonIndex][0]
	if level == false: $HolderHolder/DisplayHolder.box_move(box, "Crown")
	else: $HolderHolder/DisplayHolder.box_move(box, "Crown+")

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
				boxes.get_child(index).set_uses(Moves.get_uses(boxName))
				$"../Data/Crafting".color_box(boxes.get_child(index), boxName)
				i += 1
			if enabled:
				box_scales_move(boxes.get_child(FIRSTMOVEBOX))
				boxes.get_child(FIRSTMOVEBOX).set_uses(-1)
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
	check_ready()

func set_enemy_bar(enemySelector):
	var enemyName = enemySelector.get_node("Choice").get_text()
	if enemyName != DEFAULTOPTION:
		var enemyHP = Enemies.enemyList[enemyName]["stats"][enemyDifficulty]
		enemySelector.get_node("HPBar").visible = true
		enemySelector.get_node("HPBar").max_value = enemyHP
		enemySelector.get_node("HPBar").value = enemyHP
		enemySelector.get_node("HPBar/Text").text = str(enemyHP, "/", enemyHP)

func check_ready():
	var validPlayers = false
	var validOpponents = false
	for display in $HolderHolder/DisplayHolder.get_children():
		if display.get_node("MoveBoxes").visible:
			validPlayers = true
			break
	for enemyName in opponents:
		if enemyName != DEFAULTOPTION:
			validOpponents = true
			break
	$GoButton.visible = true if validPlayers and validOpponents else false

func toggle_visibilities(toggle):
	$HolderHolder/EnemyHolder.visible = toggle
	$HolderHolder/BoonHolder.visible = toggle
	$EnemyLevel.visible = toggle
	$GoButton.visible = toggle
	for unit in units: unit.ui.get_node("PuzzleMenu").visible = toggle

func _on_enemyLevel_value_changed(value):
	enemyDifficulty = value
	for enemySelector in $HolderHolder/EnemyHolder.get_children():
		set_enemy_bar(enemySelector)

func assess_passives():
	for unit in global.storedParty:
		for box in unit.boxHolder.get_children():
			var moveData = Moves.moveList[box.moves[0]]
			if moveData.has("passive"):
				unit.passives[moveData["passive"][0]] = moveData["passive"][1]
			if moveData.has("discount"):
				unit.set_discount(moveData["discount"])
			if moveData.has("strength"):
				unit.startingStrength += moveData["strength"]

func _on_GoButton_pressed():
	global.storedParty.clear()
	for unit in units:
		if unit.ui.get_node("MoveBoxes").visible:
			global.storedParty.append(unit)
			unit.maxHealth = unit.ui.get_node("PuzzleMenu/HP Input").value
			unit.currentHealth = unit.maxHealth
			unit.allowedType = unit.ui.get_node("PuzzleMenu").type + OFFSET
			for tracker in unit.ui.get_node("Trackers").get_children():
				unit.ui.get_node("Trackers").remove_child(tracker)
				tracker.queue_free()
			battleWindow.get_node("BattleUI").setup_display(unit)
		else:
			unit.ui.visible = false
		if unit.allowedType == unit.types.special: unit.baseAP = unit.ui.get_node("PuzzleMenu/Resource Input").value
		elif unit.allowedType == unit.types.magic:
			unit.maxMana = unit.ui.get_node("PuzzleMenu/Resource Input").value
			unit.mana = unit.ui.get_node("PuzzleMenu/Resource Input").value
		elif unit.allowedType == unit.types.trick:
			unit.maxEnergy = unit.ui.get_node("PuzzleMenu/Resource Input").value
			unit.energy = unit.ui.get_node("PuzzleMenu/Resource Input").value
		unit.update_box_bars(true)
	
	for i in playerBoons.size():
		if playerBoons[i] != 0:
			var chosenBoon = $HolderHolder/BoonHolder.get_child(i).get_node("Choice").get_text()
			Boons.playerBoons.append(chosenBoon)
			Boons.create_boon(chosenBoon)
			if boonLevels[i][0]: Boons.get_node(chosenBoon).level[0] = true
			if boonLevels[i][1]: Boons.get_node(chosenBoon).level[1] = true
	
	assess_passives()
	
	var newOpponents = []
	for enemyName in opponents:
		if enemyName != DEFAULTOPTION: newOpponents.append(enemyName)
	battleWindow.get_node("BattleUI").set_holder()
	for child in battleWindow.get_node("Units").get_children():
		battleWindow.get_node("Units").remove_child(child)
		child.queue_free()
	for unit in global.storedParty:
		 battleWindow.get_node("Units").add_child(unit)
	battleWindow.visible = true
	toggle_visibilities(false)
	battleWindow.welcome_back(newOpponents, enemyDifficulty)
