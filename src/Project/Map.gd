extends Node2D

export (PackedScene) var Point
export (PackedScene) var Line
export (PackedScene) var Time
export (PackedScene) var Battle
export (PackedScene) var Inventory
export (PackedScene) var ChoiceUI
export (PackedScene) var Dungeon

const INCREMENT = 150
const KILLDISTANCE = 140
const MAXDISTANCE = 250
const FUZZ = 35
const CORNER_CHECK = 20
const DISTANCE_TIME_MULT = .05

const MOVESPACES = 5

var bottomRight
var columnNum
var startIndex
var endIndex
var activePoint
var savedPoint

var calledEvent
var timeNode
var time = 150
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
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < MOVESPACES:
				global.storedParty[i].moves.append("X")
			global.storedParty[i].ui = $HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
			global.storedParty[i].update_hp()
		for display in $HolderHolder/DisplayHolder.get_children():
			display.get_node("Name").text = $Moves.get_classname(global.storedParty[display.get_index()].allowedType)
	bottomRight = Vector2($ReferenceRect.margin_right, $ReferenceRect.margin_bottom)
	timeNode.position.y += bottomRight.y
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
	add_child(inventoryWindow)
	inventoryWindow.visible = false

func setup_battle():
	battleWindow = Battle.instance()
	add_child(battleWindow)
	battleWindow.visible = false

func activate_inventory():
	inventoryWindow.welcome_back(inventoryWindow.iModes.default)

func activate_point(type):
	if type == pointTypes.start:
		print("Start")
	elif type == pointTypes.battle:
		battleWindow.visible = true
		battleWindow.welcome_back()
	elif type == pointTypes.dungeon:
		run_event("Dungeon")
	elif type == pointTypes.event:
		var list = $Events.eventList
		var pool = []
		if isDay:
			for option in list: #day has a lesser value than overworld in the enum
				if list[option]["time"] <= $Events.timings.overworld: pool.append(option)
		else:
			for option in list: #night has a greater value than overworld
				if list[option]["time"] >= $Events.timings.overworld: pool.append(option)
		run_event(pool[randi() % pool.size()])

func run_event(eventName):
	calledEvent = eventName
	$Events.visible = true
	$Events/EventDescription.text = $Events.eventList[eventName]["description"]
	var choice
	var yIncrement = $Events/EventDescription.rect_size.y
	var event
	for i in $Events.eventList[eventName]["choices"].size():
		event = $Events.eventList[eventName]
		if event.has("conditions") and typeof(event["conditions"][i]) == TYPE_ARRAY: #assess the condition
			var cond = event["conditions"][i]
			var function = event["conditions"][i][0] #first element is the function, rest is the args
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
			startIndex.toggle_activation(true)
			startIndex.set_name("Start")
			determine_distances(startIndex)
			return clean_up()
		nextPos.x = INCREMENT
	make_points(nextPos)

func categorize_points():
	var townList = []
	var fourList = []
	var dungeonList = []
	var threeList = []
	#var dungeonList = []
	for point in $HolderHolder/PointHolder.get_children():
		if point.visible and point.clicksFromStart:
			if point.clicksFromStart >= 3 and point.clicksFromStart < endIndex.clicksFromStart:
				if point.lines.size() >= 5:
					townList.append(point)
				elif point.lines.size() == 4:
					fourList.append(point)
				elif point.lines.size() == 3:
					threeList.append(point)
				elif point.lines.size() == 2:
					dungeonList.append(point)
	if townList.size() < 3: 
		townList.append_array(fourList)
		print("appending backup towns")
	var towns = place_landmarks(townList, "Town")
	if dungeonList.size() < 3:
		dungeonList.append_array(threeList)
		print("appending backup dungeons")
	var dungeons = place_landmarks(dungeonList, "Dungeon")
	if towns and dungeons: finalize_dungeons(towns, dungeons)

func place_landmarks(list, landmark):
	if list.size() <= 1: 
		print("not enough")
		return
	var closest = list[0]
	var furthest = list[0]
	list.remove(0)
	for point in list:
		if point.clicksFromStart > furthest.clicksFromStart:
			furthest = point
		if point.clicksFromStart < closest.clicksFromStart:
			closest = point
	set_label(closest, str("Closest ", landmark), true)
	set_label(furthest, str("Furthest ", landmark), true)
	return [closest, furthest]

func finalize_dungeons(towns, dungeons):
	var connection
	var cLine
	var connections = []
	for i in dungeons.size():
		dungeons[i].pointType = pointTypes.dungeon
		dungeons[i].info["dungeonIndex"] = i
		for line in dungeons[i].lines:
			for point in line.linePoints:
				if !(towns.has(point) or dungeons.has(point) or connections.has(point) or endIndex == point):
					connection = point
					cLine = line
		if connection: #Set up the dungeon and link the two points together
			cLine.dungeonize()
			var newDungeon = Dungeon.instance()
			$HolderHolder/DungeonHolder.add_child(newDungeon)
			newDungeon.setup(cLine)
			if dungeons[i].position.x < connection.position.x: #0 is left 1 is right
				dungeons[i].info["direction"] = 0
				connection.info["direction"] = 1
				newDungeon.originLocation = dungeons[i]
				newDungeon.exitLocation = connection
			else:
				dungeons[i].info["direction"] = 1
				connection.info["direction"] = 0
				newDungeon.originLocation = connection
				newDungeon.exitLocation = dungeons[i]
			set_label(connection, "Connection", true)
			connection.pointType = pointTypes.dungeon
			connections.append(connection)
			connection.info["dungeonIndex"] = i
			newDungeon.originLocation = dungeons[i]
			newDungeon.exitLocation = connection
			connection = null

func clean_up():
	for point in $HolderHolder/PointHolder.get_children():
		point.set_name(point.clicksFromStart)
	set_label(endIndex, "End", true)
	if !canEnd: 
		print("disaster")
	else: 
		categorize_points()

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
			point.pointType = pointTypes.battle

func determine_distances(checkPoint): #gives every node a distance from start and returns if the end node is accessible
	if checkPoint == startIndex: checkPoint.clicksFromStart = 0
	#print(str("Evaluating Point at: ", checkPoint.clicksFromStart))
	var killLines = []
	for line in checkPoint.lines:
		if is_instance_valid(line):
			for point in line.linePoints:
				if !point.visible: continue
				if point.clicksFromStart == null:
					point.clicksFromStart = checkPoint.clicksFromStart+1
					nextCheck.append(point)
					#print(str("Appending point.", " Total lines: ", checkPoint.lines.size()))
				if point == endIndex: 
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

func subtract_time(diff):
	time -= diff
	if time <= 0:
		time = 150 + time
		isDay = true
		timeNode.get_node("State").text = "Day"
	elif time <= 50: 
		isDay = false
		timeNode.get_node("State").text = "Night"
	timeNode.get_node("Hour").text = String(time)

func get_point(i, diff):
	return $HolderHolder/PointHolder.get_child(i - diff)

func fuzz_point(currentPoint):
	var pointChange = rando_fuzz()
	currentPoint.position.x = min(currentPoint.position.x - FUZZ + pointChange, bottomRight.x - CORNER_CHECK)
	pointChange = rando_fuzz() #reroll for the Y
	currentPoint.position.y = min(currentPoint.position.y - FUZZ + pointChange, bottomRight.y - CORNER_CHECK)

func rando_fuzz():
	return randi() % (FUZZ * 2)
