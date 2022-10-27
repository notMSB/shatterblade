extends Node2D

export (PackedScene) var UnitUI
export (PackedScene) var PlayerProfile
export (PackedScene) var PlayerMove

const DEFAULTMOVES = 2
const PLAYERXSTART = 600
const PLAYERYSTART = 600
const PLAYERINCREMENT = 80

const UNITYSTART = 200
const XINCREMENT = 300

onready var Moves = get_node("../../../Data/Moves")

func setup_player(unit, playerCount):
	var display = PlayerProfile.instance()
	add_child(display)
	display.get_node("Name").text = unit.name
	unit.isPlayer = true
	display.position.x = PLAYERXSTART + (playerCount % 2 * PLAYERINCREMENT)
	display.position.y = PLAYERYSTART + PLAYERINCREMENT if playerCount > 1 else PLAYERYSTART
	
	add_moves(unit, display, playerCount)
	
	return display

func add_moves(unit, display, playerCount):
	unit.boxHolder = display.get_node("MoveBoxes")
	for i in DEFAULTMOVES + unit.moves.size():
		create_move(unit, playerCount, i)
	cleanup_moves(unit)

func create_move(unit, playerCount, posIndex):
	var move
	var moveBox = PlayerMove.instance()
	moveBox.user = unit
	unit.boxHolder.add_child(moveBox)
	var xPos = moveBox.position.x
	if posIndex < DEFAULTMOVES: #set up attack and defend defaults
		moveBox.position.x = xPos - PLAYERINCREMENT if playerCount % 2 == 0 else xPos + PLAYERINCREMENT
		moveBox.get_node("ColorRect").rect_size.y = 40
		move = moveBox.get_node("Name").text
		if posIndex == 0:
			if move == "X": move = "Attack"
			moveBox.position.y -= PLAYERINCREMENT*.25
		else:
			if move == "X": move = "Defend"
			moveBox.position.y += PLAYERINCREMENT*.25
	else: #set up other moves
		move = unit.moves[posIndex - DEFAULTMOVES]
		moveBox.position.x = xPos - PLAYERINCREMENT*posIndex if playerCount % 2 == 0 else xPos + PLAYERINCREMENT*posIndex
	if Moves.moveList[move].has("resVal"):
		moveBox.resValue = Moves.moveList[move]["resVal"]
	box_move(moveBox, move)
	moveBox.set_uses(Moves.get_uses(move))
	var button = moveBox.get_node("Button")
	button.rect_size = moveBox.get_node("ColorRect").rect_size

func set_boxes(boxes):
	var boxName
	for box in boxes:
		boxName = box.get_node("Name").text
		box_move(box, boxName)

func box_move(moveBox, move, isUseless = false):
	if Moves.moveList.has(move):
		var moveData = Moves.moveList[move]
		moveBox.moves.clear()
		moveBox.moveIndex = 0
		moveBox.moveType = moveData["type"]
		if moveData.has("resVal"): moveBox.resValue = moveData["resVal"]
		moveBox.moves.append(move)
		if moveData.has("cycle"): moveBox.moves.append_array(moveData["cycle"])
		elif moveBox.moveType == Moves.moveType.trick: #tricks that do not have reload on them will have a different cycle in the data
			moveBox.moves.append("Reload")
		moveBox.get_node("Name").text = move
		moveBox.get_node("Info").text = ""
		if isUseless: moveBox.set_uses(-1)
		moveBox.isCursed = true if moveData.has("cursed") else false
		sprite_move(moveBox, move)
	else:
		moveBox.get_node("Name").text = move
		sprite_move(moveBox, move, false)

func sprite_move(box, boxName, isMove = true):
	var sprite = box.get_node("Sprite")
	var cRect = box.get_node("ColorRect")
	var spritePath
	if isMove: spritePath = str("res://src/Assets/Icons/Moves/", boxName, ".png")
	else: spritePath = str("res://src/Assets/Icons/Components/", boxName, ".png")
	var tempFile = File.new()
	if(tempFile.file_exists(spritePath)):
		sprite.texture = load(spritePath)
		sprite.visible = true
		cRect.visible = false
	else:
		sprite.visible = false
		cRect.visible = true

func cleanup_moves(unit, boxColor = null): #makes all boxes perform the move they say that they are and sets passives from them
	#unit.moves.sort_custom(self, "sort_order") #Movebox resource bars appreciate sorted movelist
	var move
	var box
	for i in unit.moves.size() + DEFAULTMOVES:
		box = unit.boxHolder.get_child(i)
		if i < DEFAULTMOVES: #Adjust for relic swaps in attack/defend
			move = box.get_node("Name").text
		else: #Place the rest of the moves down
			move = unit.moves[i - DEFAULTMOVES]
		box_move(box, move)
		box.get_node("Info").text = ""
		if boxColor: box.get_node("ColorRect").color = boxColor

func manage_and_color_boxes(unit, boxColor = null): #Puts all of a unit's boxes in map mode and kills spent items
	var move
	var moveData
	for box in unit.boxHolder.get_children():
		move = box.moves[0]
		moveData = Moves.moveList[move]
		if (moveData["type"] == Moves.moveType.item and box.currentUses == 0) or moveData.has("fleeting"): #kill
			box_move(box, "X", true)
		elif moveData["type"] == Moves.moveType.trick:
			if box.moveIndex == 1 and box.moves[1] == "Catch" and box.timesEnabled > 0: box_move(box, "X", true) #temp
			else: box_move(box, move) #Needed to make sure multimove equipment resets
		box.get_node("Info").text = ""
		box.timesUsed = 0
		box.timesEnabled = 0
		if boxColor: box.get_node("ColorRect").color = boxColor

func sort_order(a, b):
	if Moves.moveList[a]["resVal"] > Moves.moveList[b]["resVal"]:
		return false
	return true

func setup_enemy(unit, enemyCount, totalEnemies):
	var display = UnitUI.instance()
	add_child(display)
	display.check_mode()
	#display.get_node("Name").text = unit.name
	display.get_node("BattleElements/HP").text = String(unit.currentHealth)
	if unit.shield > 0:
		display.get_node("BattleElements/HP").text += "[" + String(unit.shield) + "]"
	#display.get_node("Stats").text = String(unit.strength) + "/" + String(unit.speed)
	var sprite = display.get_node("Sprite")
	var button = display.get_node("Button")
	sprite.visible = true
	var spritePath = str("res://src/Assets/Enemies/", unit.identity, ".png")
	var tempFile = File.new()
	if(tempFile.file_exists(spritePath)):
		sprite.texture = load(spritePath)
		sprite.flip_h = true
	button.rect_size = sprite.get_rect().size #match the button size with the sprite
	var sprPos = sprite.get_rect().position
	button.rect_position = Vector2(sprPos.x + 48, sprPos.y + 48)
	display.position.x = (XINCREMENT*2.5 - XINCREMENT*0.5 * totalEnemies) + (enemyCount * XINCREMENT)
	display.position.y = UNITYSTART
	return display
