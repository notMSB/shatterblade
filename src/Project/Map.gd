extends Node2D

export (PackedScene) var Point
export (PackedScene) var Line
export (PackedScene) var Time
export (PackedScene) var Battle
export (PackedScene) var ChoiceUI

const INCREMENT = 150
const KILLDISTANCE = 140
const MAXDISTANCE = 250
const FUZZ = 35
const CORNER_CHECK = 20
const DISTANCE_TIME_MULT = .05

var bottomRight
var columnNum
var startIndex
var endIndex
var activeNode

var calledEvent
var timeNode
var time = 150
var isDay = true

var battleWindow
enum pointTypes {start, battle, event}

func _ready():
	randomize()
	timeNode = Time.instance()
	add_child(timeNode)
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			print(global.storedParty[i])
			global.storedParty[i].ui = $HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
			global.storedParty[i].update_hp()
		for display in $HolderHolder/DisplayHolder.get_children():
			display.get_node("Name").text = $Moves.get_classname(global.storedParty[display.get_index()].allowedType)
	bottomRight = Vector2($ReferenceRect.margin_right, $ReferenceRect.margin_bottom)
	timeNode.position.y += bottomRight.y
	columnNum = int(ceil(bottomRight.x/INCREMENT) - 1) #ceil-1 instead of floor prevents strangeness with exact divisions
	#print(columnNum)
	make_points(Vector2(INCREMENT,INCREMENT*.5))

func activate_point(type):
	if type == pointTypes.start:
		print("Start")
	elif type == pointTypes.battle:
		if !battleWindow:
			battleWindow = Battle.instance()
			add_child(battleWindow)
		else:
			battleWindow.visible = true
			battleWindow.welcome_back()
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
			return #done
		nextPos.x = INCREMENT
	make_points(nextPos)

func organize_lines():
	for point in $HolderHolder/PointHolder.get_children():
		if point.lines.empty() and point.visible: point.visible = false #remove orphaned points
		if !point.visible: #kill lines involving invisible points
			for line in point.lines:
				line.queue_free()
		else: #set start and end index among visible points, give points events
			if !startIndex: startIndex = point
			elif point.position.x < startIndex.position.x: startIndex = point
			if !endIndex: endIndex = point
			elif point.position.x >= endIndex.position.x: endIndex = point
			point.pointType = pointTypes.event

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
