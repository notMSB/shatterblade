extends Node2D

export (PackedScene) var Point
export (PackedScene) var Line

const INCREMENT = 150
const KILLDISTANCE = 140
const MAXDISTANCE = 250
const FUZZ = 35
const CORNER_CHECK = 20
var bottomRight
var columnNum
var startIndex
var endIndex
var activeNode

func _ready():
	randomize()
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			$HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
		for display in $HolderHolder/DisplayHolder.get_children():
			display.get_node("Name").text = $Moves.get_classname(global.storedParty[display.get_index()].allowedType)
	bottomRight = Vector2($ReferenceRect.margin_right, $ReferenceRect.margin_bottom)
	columnNum = int(ceil(bottomRight.x/INCREMENT) - 1) #ceil-1 instead of floor prevents strangeness with exact divisions
	#print(columnNum)
	make_points(Vector2(INCREMENT,INCREMENT*.5))
	

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
			for point in $HolderHolder/PointHolder.get_children():
				if point.lines.empty() and point.visible: point.visible = false #remove orphaned points
				if !point.visible:
					for line in point.lines:
						line.queue_free()
				else:
					if !startIndex: startIndex = point
					else:
						if point.position.x < startIndex.position.x: startIndex = point
					if !endIndex: endIndex = point
					else:
						if point.position.x >= endIndex.position.x: endIndex = point
				for line in point.lines:
					line.visible = false
			#print(str(startIndex.get_index(), " ------------> ", endIndex.get_index()))
			startIndex.toggle_activation(true)
			return #done
		nextPos.x = INCREMENT
	make_points(nextPos)

func determine_neighbors(currentPoint):
	var left = true
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
	#print(distance)
	if two.visible:
		if distance < KILLDISTANCE:
			one.visible = false
		elif distance <= MAXDISTANCE:
			var pointLine = Line.instance()
			$HolderHolder/LineHolder.add_child(pointLine)
			pointLine.add_point(one.position)
			pointLine.add_point(two.position)
			one.lines.append(pointLine)
			two.lines.append(pointLine)
		else:
			print(str(two.get_index(), ": ", distance))

func get_point(i, diff):
	return $HolderHolder/PointHolder.get_child(i - diff)

func fuzz_point(currentPoint):
	var pointChange = rando_fuzz()
	currentPoint.position.x = min(currentPoint.position.x - FUZZ + pointChange, bottomRight.x - CORNER_CHECK)
	pointChange = rando_fuzz() #reroll for the Y
	currentPoint.position.y = min(currentPoint.position.y - FUZZ + pointChange, bottomRight.y - CORNER_CHECK)

func rando_fuzz():
	return randi() % (FUZZ * 2)
