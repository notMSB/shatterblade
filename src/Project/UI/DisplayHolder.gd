extends Node2D

export (PackedScene) var UnitUI
export (PackedScene) var PlayerProfile
export (PackedScene) var PlayerMove

const DefaultMoves = 2
const PLAYERXSTART = 600
const PLAYERYSTART = 600
const PLAYERINCREMENT = 80

const UNITYSTART = 200
const XINCREMENT = 300

onready var Moves = get_node("../../Moves") #obtain uncle

func setup_player(unit, playerCount):
	var moveBox
	var xPos
	var move
	
	var display = PlayerProfile.instance()
	add_child(display)
	display.get_node("Name").text = unit.name
	unit.isPlayer = true
	display.position.x = PLAYERXSTART + (playerCount % 2 * PLAYERINCREMENT)
	display.position.y = PLAYERYSTART + PLAYERINCREMENT if playerCount > 1 else PLAYERYSTART
	
	for i in DefaultMoves + unit.moves.size():
		moveBox = PlayerMove.instance()
		moveBox.user = unit
		unit.boxHolder = display.get_node("MoveBoxes")
		unit.boxHolder.add_child(moveBox)
		xPos = moveBox.position.x
		if i < DefaultMoves: #set up attack and defend defaults
			moveBox.position.x = xPos - PLAYERINCREMENT if playerCount % 2 == 0 else xPos + PLAYERINCREMENT
			moveBox.get_node("ColorRect").rect_size.y = 40
			if i == 0:
				move = "Attack"
				moveBox.position.y -= PLAYERINCREMENT*.25
			else:
				move = "Defend"
				moveBox.position.y += PLAYERINCREMENT*.25
			moveBox.moveType = Moves.moveType.basic
		else: #set up other moves
			move = unit.moves[i - DefaultMoves]
			moveBox.moveType = Moves.moveList[move]["type"]
			if Moves.moveList[move].has("resVal"):
				moveBox.resValue = Moves.moveList[move]["resVal"]
			moveBox.position.x = xPos - PLAYERINCREMENT*i if playerCount % 2 == 0 else xPos + PLAYERINCREMENT*i
		moveBox.moves.append(move)
		if moveBox.moveType == Moves.moveType.trick: moveBox.moves.append("Reload")
		moveBox.get_node("Name").text = move
		var button = moveBox.get_node("Button")
		button.rect_size = moveBox.get_node("ColorRect").rect_size
		
	return display
	
	
func setup_enemy(unit, enemyCount, totalEnemies):
	var display = UnitUI.instance()
	add_child(display)
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
