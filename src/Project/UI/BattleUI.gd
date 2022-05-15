extends Node2D

export (PackedScene) var UnitUI
export (PackedScene) var PlayerProfile
export (PackedScene) var PlayerMove
export (PackedScene) var ResourceTracker

const UNITXSTART = 100
const UNITYSTART = 100

const PLAYERXSTART = 600
const PLAYERYSTART = 600
const PLAYERINCREMENT = 80

const XINCREMENT = 250
const YINCREMENT = 265

onready var Battle = get_parent()
onready var Moves = get_node("../Moves")

const DefaultMoves = 2

var targetsVisible = false

var playerCount = 0
var enemyCount = 0

var isSubmenu = false

func setup_display(unit, _index):
	var display
	if unit.isPlayer:
		display = PlayerProfile.instance()
		display.get_node("Name").text = unit.name
		display.position.x = PLAYERXSTART + (playerCount % 2 * PLAYERINCREMENT)
		display.position.y = PLAYERYSTART + PLAYERINCREMENT if playerCount > 1 else PLAYERYSTART
		
		var moveBox
		var xPos
		for i in DefaultMoves + unit.specials.size():
			moveBox = PlayerMove.instance()
			moveBox.user = unit
			display.get_node("MoveBoxes").add_child(moveBox)
			xPos = moveBox.position.x
			if i < DefaultMoves:
				moveBox.position.x = xPos - PLAYERINCREMENT if playerCount % 2 == 0 else xPos + PLAYERINCREMENT
				moveBox.get_node("ColorRect").rect_size.y = 40
				if i == 0:
					moveBox.move = "Attack"
					moveBox.position.y -= PLAYERINCREMENT*.25
				else:
					moveBox.move = "Defend"
					moveBox.position.y += PLAYERINCREMENT*.25
				moveBox.moveType = Battle.moveType.basic
			else:
				moveBox.move = unit.specials[i - DefaultMoves]
				moveBox.moveType = Battle.moveType.special
				if Moves.moveList[moveBox.move].has("cost"):
					moveBox.cost = Moves.moveList[moveBox.move]["cost"]
				moveBox.position.x = xPos - PLAYERINCREMENT*i if playerCount % 2 == 0 else xPos + PLAYERINCREMENT*i
			moveBox.get_node("Name").text = moveBox.move
			var button = moveBox.get_node("Button")
			button.rect_size = moveBox.get_node("ColorRect").rect_size
			#button.rect_position = Vector2(-40,-20)
		set_trackers(display, display.get_node("MoveBoxes")) #moveboxes toggled on at round start
		playerCount += 1
	else:
		display = UnitUI.instance()
		#display.get_node("Name").text = unit.name
		display.get_node("HP").text = String(unit.currentHealth)
		if unit.shield > 0:
			display.get_node("HP").text += "[" + String(unit.shield) + "]"
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
		#print(str(unit.name, sprPos))
		
		#position enemy
		display.position.x = UNITXSTART + ((enemyCount % 2 + 2.5) * XINCREMENT)
		if enemyCount > 1:
			display.position.y = UNITYSTART + YINCREMENT
		else:
			display.position.y = UNITYSTART
		enemyCount += 1
	$DisplayHolder.add_child(display)
	unit.ui = display
	var bar = display.get_node("HPBar")
	bar.set_max(unit.maxHealth)
	unit.update_hp()

func toggle_moveboxes(boxes, toggle : bool, keepMoves : bool = false): #keepMoves as true means only boxes that aren't already committed are enabled
	for box in boxes.get_children():
		if !keepMoves or (keepMoves and box.buttonMode):
			toggle_single(box, toggle)

func toggle_single(box, toggle): #true for purple false for black
	if toggle:
		if box.get_node("../../ResourceTracker/ResourceBar").value < box.cost: #expensive box
			box.get_node("ColorRect").color = Color(.53,.3,.3,1)
			toggle = false #needed to disable the button
		else: 
			box.get_node("ColorRect").color = Color(.5,.1,.5,1)
			box.buttonMode = true
	else:
		box.get_node("ColorRect").color = Color(0,0,0,1)
	box.get_node("Button").visible = toggle
	box.get_node("Info").text = ""

func choose_movebox(box, user = null, target = null): #orange
	box.get_node("ColorRect").color = Color(1,.6,.2,1)
	box.buttonMode = false
	box.get_node("Button").visible = true
	if user and box.cost > 0: 
		user.update_ap(-1*box.cost)
		toggle_moveboxes(box.get_parent(), true, true)
	if target: box.updateInfo(target.name)

func set_trackers(display, boxes):
	var firstMargin
	var lastMargin
	var boxCount = 0
	for box in boxes.get_children():
		if box.moveType == Battle.moveType.special: #positioning the bar for specials, all should be next to each other by now
			boxCount+=1
			if firstMargin:
				lastMargin = box.position.x
			else:
				firstMargin = box.position.x
				lastMargin = box.position.x
	if boxCount > 0:
		var tracker = ResourceTracker.instance()
		display.add_child(tracker)
		link_boxes(tracker, boxCount, firstMargin, lastMargin)

func link_boxes(tracker, boxCount, firstMargin, lastMargin):
	var bar = tracker.get_node("ResourceBar")
	var barText = bar.get_node("Text")
	bar.margin_left = min(firstMargin, lastMargin) - PLAYERINCREMENT*.5
	bar.margin_right = max(firstMargin, lastMargin) + PLAYERINCREMENT*.5
	bar.rect_position.y -= PLAYERINCREMENT*.5
	if firstMargin > lastMargin: #Mirroring a progress bar gets a little weird
		bar.rect_pivot_offset.x = PLAYERINCREMENT*.5*boxCount
		bar.rect_scale = Vector2(-1,-1)
		barText.rect_scale = Vector2(-1,-1)
		barText.rect_pivot_offset = Vector2(PLAYERINCREMENT*.5,PLAYERINCREMENT*.125)
	bar.set_max(100)
	barText.rect_position.x += PLAYERINCREMENT*.5*(boxCount - 1)

func clear_menus():
	$Description.text = ""
	$Description.visible = false

func toggle_buttons(toggle, units = []):
	for child in $DisplayHolder.get_children():
			child.get_node("Button").visible = false
	if toggle:
		for unit in units:
			$DisplayHolder.get_child(unit.get_index()).get_node("Button").visible = toggle
		targetsVisible = true

func set_description(moveName, move):
	$Description.visible = true
	var desc = moveName
	if Battle.menuNode == get_node("../Items"): desc += " x" + String(Battle.currentUnit.items[moveName])
	if move["target"] == Battle.targetType.enemy: desc += "\n" + "Single Enemy"
	elif move["target"] == Battle.targetType.enemies: desc += "\n" + "All Enemies"
	elif move["target"] == Battle.targetType.enemyTargets: desc += "\n" + "Same Target Enemies"
	elif move["target"] == Battle.targetType.ally: desc += "\n" + "Single Ally"
	elif move["target"] == Battle.targetType.allies: desc += "\n" + "All Allies"
	elif move["target"] == Battle.targetType.user: desc += "\n" + "Self"
	if move.has("quick"): desc += "\n Quick Action "
	if move.has("cost"): desc += "\n Cost: " + String(move["cost"])
	if move.has("damage"): desc += "\n Base Damage: " + String(move["damage"]) + " + " + String(Battle.currentUnit.strength)
	if move.has("healing"): desc += "\n Healing: " + String(move["healing"])
	if move.has("hits"): desc += "\n Repeats: " + String(move["hits"])
	if move.has("level"): desc += "\n Level: " + String(move["level"]) + " / Charges: " + String(Battle.currentUnit.charges[move["level"]])
	if move.has("status"):
		desc += "\n Status: " + move["status"]
		if move.has("value"): desc += " " + String(move["value"])
	if move.has("description"): desc += "\n " + String(move["description"])
	$Description.text = desc
