extends Node2D

export (PackedScene) var ResourceTracker

const PLAYERINCREMENT = 80

onready var Battle = get_parent()
onready var Moves = get_node("../Moves")

const DefaultMoves = 2

var targetsVisible = false

var playerCount = 0
var enemyCount = 0

var playerHolder

var currentPlayer

func _ready():
	var grandpa = get_node("../../")
	playerHolder = $DisplayHolder if grandpa.name == "root" else grandpa.get_node("HolderHolder/DisplayHolder")

func setup_display(unit, totalEnemies):
	var display
	if unit.isPlayer:
		currentPlayer = unit
		if unit.boxHolder == null:
			display = playerHolder.setup_player(unit, playerCount)
		else:
			display = unit.boxHolder.get_parent()
		set_trackers(display, display.get_node("MoveBoxes")) #moveboxes toggled on at round start
		playerCount += 1
	else: #Enemy
		display = $DisplayHolder.setup_enemy(unit, enemyCount, totalEnemies)
		enemyCount += 1
	unit.ui = display
	display.get_node("BattleElements").visible = true
	var bar = display.get_node("BattleElements/HPBar")
	bar.set_max(unit.maxHealth)
	unit.update_hp()

func prepare_box(box):
	var move = box.moves[box.moveIndex]
	if Moves.moveList[move].has("resVal"):
		box.resValue = Moves.moveList[move]["resVal"]
	box.get_node("Name").text = move

func advance_box_move(box): #For boxes with multiple moves
	box.moveIndex = (box.moveIndex + 1) % box.moves.size()
	prepare_box(box)
	if box.moveIndex > 0:
		box.get_node("Info").text = box.moves[box.moveIndex -1]

func toggle_moveboxes(boxes, toggle : bool, keepMoves : bool = false, disableChannels: bool = false): #keepMoves as true means only boxes that aren't already committed are enabled
	var move
	for box in boxes.get_children():
		if !keepMoves or (keepMoves and box.buttonMode):
			move = box.moves[box.moveIndex]
			if toggle and !(disableChannels and Moves.moveList[move].has("channel")): #Channels are disabled if the unit already has an action in the queue
				toggle_single(box, true)
			else:
				toggle_single(box, false)

func toggle_single(box, toggle): #true for purple false for black
	if toggle:
		if box.trackerBar and box.trackerBar.value < box.resValue: #Check the resources before enabling a box
			box.get_node("ColorRect").color = Color(.53,.3,.3,1)
			toggle = false #needed to disable the button
		else: #box can be enabled
			box.get_node("ColorRect").color = Color(.5,.1,.5,1)
			box.buttonMode = true
	else: #completely disable a box
		box.get_node("ColorRect").color = Color(0,0,0,1)
	box.get_node("Button").visible = toggle
	if box.moveIndex == 0: box.get_node("Info").text = "" #Prevents reloading from wiping text

func choose_movebox(box, target = null): #happens when move and target are selected, turns movebox orange
	box.get_node("ColorRect").color = Color(1,.6,.2,1)
	box.buttonMode = false
	box.get_node("Button").visible = true
	if target: box.updateInfo(target.name)

func toggle_channels(boxes):
	var move
	for box in boxes:
		move = box.moves[box.moveIndex]
		if Moves.moveList[move].has("channel"):
			toggle_single(box, false)

func set_trackers(display, boxes):
	var firstMargin
	var lastMargin
	var boxCount = []
	var prevBox = boxes.get_children()[0]
	
	for box in boxes.get_children():
		if box.visible:
			if box.moveType == Moves.moveType.basic: continue
			if box.moveType != prevBox.moveType:
				check_box_count(boxCount, display, firstMargin, lastMargin, prevBox.moveType)
				boxCount = []
				firstMargin = null
				lastMargin = null
			boxCount.append(box)
			if firstMargin:
				lastMargin = box.position.x
			else:
				firstMargin = box.position.x
				lastMargin = box.position.x
			prevBox = box
	check_box_count(boxCount, display, firstMargin, lastMargin, prevBox.moveType)

func toggle_trackers(toggle):
	for display in playerHolder.get_children():
		for tracker in display.get_node("Trackers").get_children():
			tracker.visible = toggle

func check_box_count(count, display, firstMargin, lastMargin, barType):
	if count.size() > 0:
		var tracker = ResourceTracker.instance()
		display.get_node("Trackers").add_child(tracker)
		link_boxes(tracker, count, firstMargin, lastMargin, barType)

func link_boxes(tracker, boxCount, firstMargin, lastMargin, barType):
	var bar = tracker.get_node("ResourceBar")
	var barText = bar.get_node("Text")
	bar.margin_left = min(firstMargin, lastMargin) - PLAYERINCREMENT*.5
	bar.margin_right = max(firstMargin, lastMargin) + PLAYERINCREMENT*.5
	bar.rect_position.y -= PLAYERINCREMENT*.5
	if firstMargin <= 0: #Mirroring a progress bar gets a little weird
		bar.rect_pivot_offset.x = PLAYERINCREMENT*.5*boxCount.size()
		bar.rect_scale = Vector2(-1,-1)
		barText.rect_scale = Vector2(-1,-1)
		barText.rect_pivot_offset = Vector2(PLAYERINCREMENT*.5,PLAYERINCREMENT*.125)
	for box in boxCount:
		box.trackerBar = bar
	if barType == Moves.moveType.special:
		bar.set_max(currentPlayer.maxAP)
	elif barType == Moves.moveType.trick:
		bar.set_max(currentPlayer.maxEnergy)
	elif barType == Moves.moveType.magic:
		bar.set_max(currentPlayer.maxMana)
	else:
		pass
	barText.rect_position.x += PLAYERINCREMENT*.5*(boxCount.size() - 1) #center the text

func clear_menus():
	$Description.text = ""
	$Description.visible = false

func toggle_buttons(toggle, units = []):
	if toggle:
		var usedHolder = playerHolder if units[0].isPlayer else $DisplayHolder
		if units.size() == 1 and usedHolder == playerHolder:
			usedHolder.get_child(units[0].get_index()).get_node("Button").visible = true
		else:
			for child in usedHolder.get_children():
				child.get_node("Button").visible = true
		targetsVisible = true
	else:
		for child in playerHolder.get_children():
			child.get_node("Button").visible = false
		for child in $DisplayHolder.get_children():
			child.get_node("Button").visible = false

func set_description(moveName, move):
	$Description.visible = true
	var desc = moveName
	if move["target"] == Battle.targetType.enemy: desc += "\n" + "Single Enemy"
	elif move["target"] == Battle.targetType.enemies: desc += "\n" + "All Enemies"
	elif move["target"] == Battle.targetType.enemyTargets: desc += "\n" + "Same Target Enemies"
	elif move["target"] == Battle.targetType.ally: desc += "\n" + "Single Ally"
	elif move["target"] == Battle.targetType.allies: desc += "\n" + "All Allies"
	elif move["target"] == Battle.targetType.user: desc += "\n" + "Self"
	if move.has("quick"): desc += "\n Quick Action "
	if move.has("resVal"): desc += "\n Cost: " + String(move["resVal"])
	if move.has("damage"): desc += "\n Base Damage: " + String(move["damage"]) + " + " + String(Battle.currentUnit.strength)
	if move.has("healing"): desc += "\n Healing: " + String(move["healing"])
	if move.has("hits"): desc += "\n Repeats: " + String(move["hits"])
	if move.has("status"):
		desc += "\n Status: " + move["status"]
		if move.has("value"): desc += " " + String(move["value"])
	if move.has("description"): desc += "\n " + String(move["description"])
	$Description.text = desc
