extends Node2D

export (PackedScene) var UnitUI
export (PackedScene) var PlayerProfile
export (PackedScene) var PlayerMove

const DEFAULTMOVES = 3
const PLAYERXSTART = 572
const PLAYERYSTART = 530
const STARTXINCREMENT = 135
const STARTYINCREMENT = 135
const PLAYERINCREMENT = 80

const UNITYSTART = 200
const XINCREMENT = 300

onready var Moves = get_node("/root/Game/Data/Moves")

func setup_player(unit, playerCount):
	var display = PlayerProfile.instance()
	add_child(display)
	display.get_node("Name").text = unit.displayName
	unit.isPlayer = true
	display.position.x = PLAYERXSTART + (playerCount % 2 * STARTXINCREMENT)
	display.position.y = PLAYERYSTART + STARTYINCREMENT if playerCount > 1 else PLAYERYSTART
	if playerCount % 2 != 0: 
		display.get_node("Sprite").flip_h = true
		display.get_node("Name").align = 1 #Left
	if playerCount >= 2: 
		display.get_node("Sprite").flip_v = true
		display.get_node("BattleElements/HPBar").rect_position.y = -66
		display.get_node("BattleElements/PreviewRect").rect_position.y = -66
		display.get_node("BattleElements/Statuses").rect_position.y = -30
		display.get_node("Name").rect_position.y += 66
	
	add_moves(unit, display, playerCount)
	
	return display

func add_moves(unit, display, playerCount):
	unit.boxHolder = display.get_node("MoveBoxes")
	var movesIncrement = 13 if playerCount >= 2 else -7
	unit.boxHolder.position.y += movesIncrement
	display.get_node("Trackers").position.y += movesIncrement
	for i in DEFAULTMOVES + unit.moves.size():
		create_move(unit, playerCount, i)
	cleanup_moves(unit)

func create_move(unit, playerCount, posIndex):
	var move
	var moveBox = PlayerMove.instance()
	var hotkey = InputEventKey.new()
	hotkey.set_scancode(get_scancode(playerCount <= 1, posIndex))
	if playerCount % 2 != 0: hotkey.set_shift(true)
	moveBox.get_node("Button").shortcut = ShortCut.new()
	moveBox.get_node("Button").shortcut.set_shortcut(hotkey)
	moveBox.user = unit
	unit.boxHolder.add_child(moveBox)
	var drift = -23 if playerCount % 2 == 0 else 28
	var xPos = moveBox.position.x + drift
	if posIndex < DEFAULTMOVES: #set up attack and defend defaults
		moveBox.get_node("Tooltip").position.y -= 30
		moveBox.position.x = xPos - 100 if playerCount % 2 == 0 else xPos + 100
		moveBox.get_node("ColorRect").rect_size.y = 40
		move = moveBox.get_node("Name").text
		if posIndex == 0:
			moveBox.z_index = -3
			if move == "X": move = "Take"
			if playerCount >= 2: moveBox.position.y += PLAYERINCREMENT*.25
			else: moveBox.position.y -= PLAYERINCREMENT*.25
			moveBox.position.x = xPos - 20 if playerCount % 2 == 0 else xPos + 20
			moveBox.get_node("ColorRect").margin_bottom = 20
			moveBox.get_node("ReferenceRect").margin_bottom = 20
			moveBox.get_node("Blackout").margin_bottom = 20
			moveBox.get_node("Sprite").position.y = 0
			#if playerCount % 2 == 0: moveBox.get_node("Name").margin_right = 0
			#else: moveBox.get_node("Name").margin_left = 0
		elif posIndex == 1:
			if move == "X": move = "Attack"
			moveBox.position.y -= PLAYERINCREMENT*.25
		else:
			if move == "X": move = "Defend"
			moveBox.position.y += PLAYERINCREMENT*.25
			moveBox.get_node("ColorRect").margin_bottom = 20
			moveBox.get_node("ReferenceRect").margin_bottom = 20
			moveBox.get_node("Blackout").margin_bottom = 20
			moveBox.get_node("Sprite").position.y = 0
	else: #set up other moves
		if unit.moves.size() < posIndex - DEFAULTMOVES + 1:
			move = "X"
		else: move = unit.moves[posIndex - DEFAULTMOVES]
		moveBox.position.x = xPos - PLAYERINCREMENT*(posIndex-1) - 20 if playerCount % 2 == 0 else xPos + PLAYERINCREMENT*(posIndex-1) + 20
	if Moves.moveList[move].has("resVal"):
		moveBox.resValue = Moves.moveList[move]["resVal"]
	box_move(moveBox, move)
	moveBox.set_uses(Moves.get_uses(move))
	var button = moveBox.get_node("Button")
	button.rect_size = moveBox.get_node("ColorRect").rect_size

func get_scancode(topRow, posIndex):
	if topRow:
		match posIndex:
			0: return KEY_Q
			1: return KEY_W
			2: return KEY_E
			3: return KEY_R
			4: return KEY_T
			5: return KEY_Y
			6: return KEY_U
			7: return KEY_I
	else:
		match posIndex:
			0: return KEY_Z
			1: return KEY_X
			2: return KEY_C
			3: return KEY_V
			4: return KEY_B
			5: return KEY_N
			6: return KEY_M
			7: return KEY_COMMA

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
		moveBox.mapUse = true if moveData.has("mapUsable") else false
		sprite_move(moveBox, move)
		moveBox.set_tooltip_text(Moves.get_description(move))
	else:
		moveBox.get_node("Name").text = move
		sprite_move(moveBox, move, false)

func sprite_move(box, boxName, isMove = true):
	var sprite = box.get_node("Sprite")
	var cRect = box.get_node("ColorRect")
	var spritePath
	if boxName[-1] == "+":
		boxName.erase(boxName.length() - 1, 1)
		box.get_node("Name").modulate = Color(1, 1, 0, 1)
	else:
		box.get_node("Name").modulate = Color(1, 1, 1, 1)
	if isMove: spritePath = str("res://src/Assets/Icons/Moves/", boxName, ".png")
	else: spritePath = str("res://src/Assets/Icons/Components/", boxName, ".png")
	if ResourceLoader.exists(spritePath):
		sprite.scale = Vector2(.75, .75)
		sprite.texture = load(spritePath)
		if sprite.texture.get_size().x < 80:
			sprite.scale = Vector2(.75, .75)
		else:
			sprite.scale = Vector2(1, 1)
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

func manage_and_color_boxes(unit, invWindow = null): #Puts all of a unit's boxes in map mode and kills spent items
	var move
	var moveData
	for box in unit.boxHolder.get_children():
		move = box.moves[0]
		moveData = Moves.moveList[move]
		if (moveData["type"] >= Moves.moveType.item and box.currentUses == 0) or moveData.has("fleeting"): #it's broken
			box_move(box, "X", true)
		elif moveData["type"] == Moves.moveType.trick or moveData.has("charge"):
			if box.moveIndex == 1 and box.moves[1] == "Catch" and box.timesEnabled > 0: box_move(box, "X", true) #temp, hardcode
			else: box_move(box, move) #Needed to make sure multimove equipment resets
		box.get_node("Info").text = ""
		box.timesUsed = 0
		box.timesEnabled = 0
		if invWindow: invWindow.identify_product(box)

func sort_order(a, b):
	if Moves.moveList[a]["resVal"] > Moves.moveList[b]["resVal"]:
		return false
	return true

func setup_enemy(unit, enemyCount, totalEnemies):
	var display = UnitUI.instance()
	add_child(display)
	#display.get_node("Name").text = unit.name
	#display.get_node("Stats").text = String(unit.strength) + "/" + String(unit.speed)
	var sprite = display.get_node("Sprite")
	var button = display.get_node("Button")
	sprite.visible = true
	var spritePath = str("res://src/Assets/Enemies/", unit.spriteBase, ".png")
	if(ResourceLoader.exists(spritePath)):
		sprite.texture = load(spritePath)
		sprite.flip_h = true
	button.rect_size = sprite.get_rect().size #match the button size with the sprite
	var sprPos = sprite.get_rect().position
	button.rect_position = Vector2(sprPos.x + 48, sprPos.y + 48)
	display.position.x = (XINCREMENT*2.5 - XINCREMENT*0.5 * totalEnemies) + (enemyCount * XINCREMENT)
	display.position.y = UNITYSTART
	return display
