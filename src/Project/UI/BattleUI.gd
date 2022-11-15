extends Node2D

export (PackedScene) var ResourceTracker

const PLAYERINCREMENT = 80

onready var Battle = get_parent()
onready var Moves = get_node("../../Data/Moves")

const DefaultMoves = 2

var playerCount = 0
var enemyCount = 0

var playerHolder

var currentPlayer

func _ready():
	var grandpa = get_node("../../")
	playerHolder = $DisplayHolder if !grandpa.mapMode else grandpa.get_node("Map/HolderHolder/DisplayHolder")

func setup_display(unit, totalEnemies):
	var display
	if unit.isPlayer:
		currentPlayer = unit
		if unit.boxHolder == null:
			display = playerHolder.setup_player(unit, playerCount)
		else:
			display = unit.boxHolder.get_parent()
		set_trackers(display, display.get_node("MoveBoxes"), unit.allowedType) #moveboxes toggled on at round start
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
	var discountVal
	if Moves.moveList[move].has("resVal"):
		discountVal = box.user.apply_discount(move)
		box.resValue = Moves.moveList[move]["resVal"] - discountVal
	box.get_node("Name").text = move

func advance_box_move(box): #For boxes with multiple moves
	box.timesEnabled = 0
	box.moveIndex = (box.moveIndex + 1) % box.moves.size()
	prepare_box(box)
	if box.moveIndex > 0:
		box.get_node("Info").text = box.moves[box.moveIndex - 1] if Moves.moveList[box.moves[0]].type >= Moves.moveType.special else ""

func toggle_moveboxes(boxes, toggle : bool, keepMoves : bool = false, disableChannels: bool = false, turnStart = false): #keepMoves as true means only boxes that aren't already committed are enabled
	var move
	for box in boxes.get_children():
		if !keepMoves or (keepMoves and box.buttonMode):
			move = box.moves[box.moveIndex]
			var moveData = Moves.moveList[move]
			#print(str(move, ": ",box.timesEnabled))
			#Channels are disabled if the unit already has an action in the queue, broken equipment and unusables are always disabled
			if turnStart: 
				box.timesEnabled += 1
				if Battle.turnCount == 1 and moveData.has("charge"): #first turn for charges
					advance_box_move(box)
			if (toggle and !(disableChannels and moveData.has("channel")) and box.currentUses != 0 and !moveData.has("unusable")
			and !(box.timesUsed > 0 and moveData.has("uselimit")) and !(box.timesEnabled > 1 and moveData.has("turnlimit"))): 
				toggle_single(box, true)
			else:
				toggle_single(box, false)

func toggle_single(box, toggle): #toggle true for purple, false for black
	if toggle:
		if box.moveType != Moves.moveType.item and box.trackerBar and box.trackerBar.value < box.resValue: #Check the resources before enabling a box
			box.change_rect_color(Color(.53,.3,.3,1))
			box.get_node("ColorRect").visible = true
			toggle = false #needed to disable the button
		else: #box can be enabled
			box.change_rect_color(Color(.5,.1,.5,1))
			box.buttonMode = true
	else: #completely disable a box
		box.change_rect_color(Color(0,0,0,1))
	box.get_node("Button").visible = toggle
	if box.moveIndex == 0: box.get_node("Info").text = "" #Prevents reloading from wiping text

func choose_movebox(box, target = null): #happens when move and target are selected, turns movebox orange
	box.change_rect_color(Color(1,.6,.2,1))
	box.buttonMode = false
	box.get_node("Button").visible = true
	if target: box.updateInfo(target.battleName)

func toggle_movebox_buttons(toggle):
	for display in playerHolder.get_children():
		if display.get_node_or_null("MoveBoxes"):
			for box in display.get_node("MoveBoxes").get_children():
				box.get_node("Button").visible = toggle

func toggle_channels(boxes):
	var move
	for box in boxes:
		move = box.moves[box.moveIndex]
		if Moves.moveList[move].has("channel"):
			toggle_single(box, false)

func set_trackers(display, boxes, classType):
	var firstMargin
	var lastMargin
	var boxCount = []
	
	for box in boxes.get_children():
		if box.visible:
			if box.get_index() <= 1: continue #skip relic slots
			boxCount.append(box)
			if firstMargin:
				lastMargin = box.position.x
			else:
				firstMargin = box.position.x
				lastMargin = box.position.x
	check_box_count(boxCount, display, firstMargin, lastMargin, classType)

func toggle_trackers(toggle):
	for display in playerHolder.get_children():
		if display.get_node_or_null("Trackers"):
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
		tracker.modulate = Color(.9,.5,.5,1)
	elif barType == Moves.moveType.magic:
		bar.set_max(currentPlayer.maxMana)
		tracker.modulate = Color(.5,.5,.9,1)
	elif barType == Moves.moveType.trick:
		bar.set_max(currentPlayer.maxEnergy)
		tracker.modulate = Color(.5,.9,.5,1)
	else:
		pass
	barText.rect_position.x += PLAYERINCREMENT*.5*(boxCount.size() - 1) #center the text

func clear_menus():
	$Description.text = ""
	#$Description.visible = false

func toggle_buttons(toggle, units = []):
	if toggle:
		var usedHolder = playerHolder if units[0].isPlayer else $DisplayHolder
		if units.size() == 1 and usedHolder == playerHolder:
			usedHolder.get_child(units[0].get_index()).get_node("Button").visible = true
		else:
			for child in usedHolder.get_children(): #known to toggle on too many buttons if not in map mode
				child.get_node("Button").visible = true
	else:
		for child in playerHolder.get_children():
			child.get_node("Button").visible = false
		for child in $DisplayHolder.get_children():
			child.get_node("Button").visible = false
	Battle.get_node("GoButton").visible = !toggle
