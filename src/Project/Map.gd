extends Node2D

export (PackedScene) var Point
export (PackedScene) var Line
export (PackedScene) var Time
export (PackedScene) var Favor
export (PackedScene) var Battle
export (PackedScene) var Inventory
export (PackedScene) var ChoiceUI
export (PackedScene) var Dungeon
export (PackedScene) var Section

onready var Moves = get_node("../Data/Moves")
onready var Quests = get_node("../Data/Quests")
onready var Enemies = get_node("../Data/Enemies")

const INCREMENT = 92
const KILLDISTANCE = 81 #lower kill distance means more points
const MAXDISTANCE = 200
const FUZZ = 45 #should never be more than half of the increment
const CORNER_CHECK = 20
const DISTANCE_TIME_MULT = .05

const MOVESPACES = 5
const NIGHTLENGTH = 50
const TOTALSECTIONS = 3

var bottomRight
var columnNum

var startIndex
var endIndex

var activePoint
var savedPoint

var calledEvent
var timeNode
var favorNode

const DIFFICULTYMODIFIER = -3
var distanceTraveled = 0
var time = 150
var currentDay = 0
var isDay = true
var currentDungeon = false

var battleWindow
var inventoryWindow
enum pointTypes {none, start, battle, event, quest, visited, town, dungeon} #Points to the left of "visited" turn off after being activated

var canEnd = false
var checkedLines = []
var nextCheck = []

func _ready():
	randomize()
	timeNode = Time.instance()
	add_child(timeNode)
	favorNode = Favor.instance()
	add_child(favorNode)
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < MOVESPACES:
				global.storedParty[i].moves.append("X")
			global.storedParty[i].ui = $HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
			global.storedParty[i].update_hp()
		for display in $HolderHolder/DisplayHolder.get_children():
			display.get_node("Name").text = Moves.get_classname(global.storedParty[display.get_index()].allowedType)
	bottomRight = Vector2($ReferenceRect.margin_right, $ReferenceRect.margin_bottom)
	timeNode.position.y += bottomRight.y + 50
	favorNode.position.y += bottomRight.y + 50
	favorNode.position.x += bottomRight.x - 150
	columnNum = int(ceil(bottomRight.x/INCREMENT) - 1) #ceil-1 instead of floor prevents strangeness with exact divisions
	#print(columnNum)
	make_points(Vector2(INCREMENT,INCREMENT*.5))
	setup_battle()
	for display in $HolderHolder/DisplayHolder.get_children():
		display.set_battle()
		for tracker in display.get_node("Trackers").get_children():
			tracker.visible = false
	setup_inventory()

func setup_inventory():
	inventoryWindow = Inventory.instance()
	get_parent().add_child(inventoryWindow)
	inventoryWindow.visible = false

func setup_battle():
	battleWindow = Battle.instance()
	get_parent().add_child(battleWindow)
	battleWindow.visible = false

func activate_inventory(mode = null):
	if mode:
		inventoryWindow.welcome_back(mode)
	else:
		inventoryWindow.welcome_back(inventoryWindow.iModes.craft) #can always craft

func activate_point(point):
	var type = point.pointType
	if type == pointTypes.start:
		print("Start")
	elif type == pointTypes.battle:
		activate_battle()
	elif type == pointTypes.dungeon:
		grab_event("Dungeon")
	elif type == pointTypes.town:
		grab_event("Town")
	elif type == pointTypes.event:
		if point.pointQuest:
			$Events/EventDescription.text = str(point.pointQuest["description"], "\nfor\n", point.pointQuest["prize"])
			run_event(point.pointQuest)
		else:
			var list = $Events.eventList
			var pool = []
			if isDay:
				for option in list: #day has a lesser value than overworld in the enum
					if list[option]["time"] <= $Events.timings.overworld: pool.append(option)
			else:
				for option in list: #night has a greater value than overworld
					if list[option]["time"] >= $Events.timings.overworld: pool.append(option)
			grab_event(pool[randi() % pool.size()])

func activate_battle(newOpponents = null):
	if !newOpponents and distanceTraveled > 1:
		newOpponents = Enemies.generate_encounter(distanceTraveled + DIFFICULTYMODIFIER + currentDay, isDay)
	battleWindow.visible = true
	battleWindow.welcome_back(newOpponents)

func grab_event(eventName): #used for premade events, generated events have their own system
	calledEvent = eventName
	$Events/EventDescription.text = $Events.eventList[eventName]["description"]
	run_event($Events.eventList[eventName])

func run_event(event):
	var yIncrement = $Events/EventDescription.rect_size.y
	var choice
	var cond
	var function
	$Events.visible = true
	for i in event["choices"].size():
		if event.has("conditions") and typeof(event["conditions"][i]) == TYPE_ARRAY: #assess the condition
			cond = event["conditions"][i]
			function = event["conditions"][i][0] #first element is the function, rest is the args
			if !function.call_funcv(cond.slice(1, cond.size()-1)): continue #skip using it as an option if the condition is false
		choice = ChoiceUI.instance()
		$Events/Choices.add_child(choice)
		choice.position.y = yIncrement
		yIncrement += choice.get_node("Button").rect_size.y
		choice.get_node("Info").text = event["choices"][i]

func finish_event():
	for option in $Events/Choices.get_children():
		option.queue_free()
	$Events.visible = false
	calledEvent = null #clearing this out is needed because it's checked to process event outcomes

func make_points(nextPos):
	var currentPoint = Point.instance()
	$HolderHolder/PointHolder.add_child(currentPoint)
	currentPoint.position = nextPos
	fuzz_point(currentPoint)

	#print(str("-----POINT ", currentPoint.get_index(), "-----"))
	determine_neighbors(currentPoint)
	
	nextPos.x += INCREMENT
	if nextPos.x >= bottomRight.x:
		nextPos.y += INCREMENT
		if nextPos.y >= bottomRight.y: #done, clean up leftovers and set start/end points
			organize_lines()
			startIndex.pointType = pointTypes.start
			activePoint = startIndex
			startIndex.toggle_activation(true)
			startIndex.set_name("Start")
			determine_distances(startIndex)
			return clean_up()
		nextPos.x = INCREMENT
	make_points(nextPos)

func find_border_points():
	var checkSection
	var adjacentPoint
	var possibleDungeons = [] #2D array of lines
	var exitPoints = []
	for i in TOTALSECTIONS - 1:
		possibleDungeons.append([])
		exitPoints.append([])
	for point in $HolderHolder/PointHolder.get_children():
		if point.visible and point.clicksFromStart and point.sectionNum != TOTALSECTIONS - 1: #no reason to check points in the last section
			checkSection = point.sectionNum
			for line in point.lines:
				adjacentPoint = line.get_connection(point)
				if adjacentPoint.sectionNum > checkSection:
					possibleDungeons[checkSection].append(line)
					exitPoints[checkSection].append(adjacentPoint)
	place_dungeons(possibleDungeons, exitPoints)

func place_dungeons(possibleDungeons, borderPoints): #dungeons start in one section and end in the next
	var dungeonLine
	var entrySection
	for border in possibleDungeons:
		if border.empty(): return print("dungeon shortage")
		var newDungeon = Dungeon.instance()
		$HolderHolder/DungeonHolder.add_child(newDungeon)
		dungeonLine = border[randi() % border.size()]
		entrySection = min(dungeonLine.linePoints[0].sectionNum, dungeonLine.linePoints[1].sectionNum)
		for point in dungeonLine.linePoints: #border[rando] is a line
			point.pointType = pointTypes.dungeon
			point.info["dungeonIndex"] = entrySection
			point.info["direction"] = point.sectionNum - entrySection #0 for entry 1 for exit
			if entrySection == point.sectionNum: 
				newDungeon.originLocation = point
				point.set_name("Entry")
			else: 
				newDungeon.exitLocation = point
				point.set_name("Exit")
		dungeonLine.dungeonize()
		newDungeon.setup(dungeonLine)
		place_town(newDungeon.exitLocation, borderPoints[entrySection])

func place_town(exitPoint, borderPoints): #towns are adjacent to dungeon exits and in the same section, if possible they are also on the border. ties broken by closeness to center
	var checkPoint
	var bestSpot
	var bestDistance = bottomRight.y/2
	var townSpots = []
	var backupSpots = []
	for line in exitPoint.lines:
		checkPoint = line.get_connection(exitPoint)
		if borderPoints.has(checkPoint): townSpots.append(checkPoint)
		elif checkPoint.sectionNum == exitPoint.sectionNum: backupSpots.append(checkPoint)
	if townSpots.empty(): 
		if backupSpots.empty(): return print("no spots for town")
		print("backup spots")
		townSpots = backupSpots
	for i in townSpots.size():
		if abs(townSpots[i].position.y - bottomRight.y/2) < bestDistance:
			bestSpot = townSpots[i]
			print("swapping town to more central spot")
	bestSpot.set_name("Town")
	bestSpot.pointType = pointTypes.town
	#print(bottomRight.y/2)

func clean_up():
	var divider = bottomRight.x / TOTALSECTIONS
	add_sections(divider)
	for point in $HolderHolder/PointHolder.get_children():
		point.sectionNum = floor(point.position.x / divider)
		point.set_name(str(point.sectionNum, " | ", point.clicksFromStart))
	set_label(endIndex, "End", true)
	if !canEnd: 
		print("disaster")
	else: 
		find_border_points()
		#categorize_points()

func add_sections(divider):
	var newSection
	var sectionBG
	for i in TOTALSECTIONS:
		newSection = Section.instance()
		$HolderHolder/SectionHolder.add_child(newSection)
		sectionBG = newSection.get_node("BG")
		sectionBG.margin_left = i * divider
		sectionBG.margin_right = sectionBG.margin_left + divider
	set_sections()

func set_sections():
	var sHolder = $HolderHolder/SectionHolder
	for i in $HolderHolder/SectionHolder.get_child_count():
		sHolder.get_child(i).visible = false if currentDay == i else true

func set_label(point, label, distance = false):
	if distance: point.set_name(str(label, " ", point.clicksFromStart))
	else: point.set_name(label)

func organize_lines():
	for point in $HolderHolder/PointHolder.get_children():
		if point.lines.empty() and point.visible: point.visible = false #remove orphaned points
		if !point.visible: #kill lines involving invisible points
			for line in point.lines:
				line.free()
		else: #set start and end index among visible points, give points events
			if !startIndex: startIndex = point
			elif point.position.x < startIndex.position.x: startIndex = point
			if !endIndex: endIndex = point
			elif point.position.x >= endIndex.position.x: endIndex = point
			point.pointType = pointTypes.battle ###
			if point.pointType == pointTypes.event: make_quest(point)

func make_quest(point):
	point.pointQuest = $Events.generate_event(Quests.generate_quest())

func determine_distances(checkPoint): #gives every node a distance from start and returns if the end node is accessible
	if checkPoint == startIndex: checkPoint.clicksFromStart = 0
	var connectedPoint
	#print(str("Evaluating Point at: ", checkPoint.clicksFromStart))
	var killLines = []
	for line in checkPoint.lines:
		if is_instance_valid(line):
			connectedPoint = line.get_connection(checkPoint)
			if !connectedPoint.visible: continue
			if connectedPoint.clicksFromStart == null:
				connectedPoint.clicksFromStart = checkPoint.clicksFromStart+1
				nextCheck.append(connectedPoint)
				#print(str("Appending point.", " Total lines: ", checkPoint.lines.size()))
			if connectedPoint == endIndex: 
				canEnd = true
		else: #kill deleted lines
			killLines.append(line)
	for line in killLines:
		checkPoint.lines.erase(line)
	if !nextCheck.empty():
		var nextPoint = nextCheck[0]
		nextCheck.remove(0)
		determine_distances(nextPoint)

func determine_neighbors(currentPoint):
	var left = true #sometimes you just need a buncha booleans
	var topleft = true
	var top = true
	var topright = true
	var currentIndex = currentPoint.get_index()
	
	if currentIndex < columnNum: #top row
		topleft = false
		top = false
		topright = false
	if currentIndex % columnNum == 0: #leftmost column
		left = false
		topleft = false
	if currentIndex % columnNum == columnNum-1: #rightmost column
		topright = false 
	
	if left: analyze_points(currentPoint, get_point(currentIndex, 1))
	if topleft: analyze_points(currentPoint, get_point(currentIndex, columnNum + 1))
	if top: analyze_points(currentPoint, get_point(currentIndex, columnNum))
	if topright: analyze_points(currentPoint, get_point(currentIndex, columnNum - 1))

func analyze_points(one, two):
	var distance = one.position.distance_to(two.position)
	if two.visible:
		if distance < KILLDISTANCE: #kill points too close to one another
			one.visible = false #visibility toggle instead of deletion to keep the indexing functional
		elif distance <= MAXDISTANCE: #any points further away than MAXDISTANCE are usually too close to an incoming point and deleted anyway, but still
			var pointLine = Line.instance()
			$HolderHolder/LineHolder.add_child(pointLine)
			pointLine.add_point(one.position) #add points to line
			pointLine.add_point(two.position)
			pointLine.linePoints.append(one)
			pointLine.linePoints.append(two)
			var xPos = (one.position.x + two.position.x)*.5
			var yPos = (one.position.y + two.position.y)*.5
			pointLine.get_node("Text").rect_position = Vector2(xPos, yPos) #set up travel time text
			pointLine.get_node("Text").text = String(ceil(distance * DISTANCE_TIME_MULT))
			one.lines.append(pointLine) #add line to points
			two.lines.append(pointLine)

func subtract_time(diff, refillAllMana = false):
	distanceTraveled = diff
	time -= diff
	if refillAllMana: update_mana()
	else: update_mana(diff)
	if time <= 0:
		time = 150 + time
		advance_day()
		timeNode.get_node("State").text = "Day"
	elif time <= 50: 
		isDay = false
		timeNode.get_node("State").text = "Night"
	timeNode.get_node("Hour").text = String(time)

func advance_day():
	isDay = true
	currentDay += 1
	set_sections()

func update_favor(amount):
	favorNode.get_node("Amount").text = String(amount)

func update_mana(gain = null):
	for unit in global.storedParty:
		if gain: unit.update_resource(gain, Moves.moveType.magic, true)
		else: unit.update_resource(unit.maxMana, Moves.moveType.magic, true)

func get_point(i, diff):
	return $HolderHolder/PointHolder.get_child(i - diff)

func fuzz_point(currentPoint):
	var pointChange = rando_fuzz()
	currentPoint.position.x = min(currentPoint.position.x - FUZZ + pointChange, bottomRight.x - CORNER_CHECK)
	pointChange = rando_fuzz() #reroll for the Y
	currentPoint.position.y = min(currentPoint.position.y - FUZZ + pointChange, bottomRight.y - CORNER_CHECK)
	currentPoint.position.y = max(currentPoint.position.y, CORNER_CHECK * 2)

func rando_fuzz():
	return randi() % (FUZZ * 2)
