extends Node2D

onready var Map = get_tree().current_scene

var index
var type

var totalPoints
const INCREMENT = 100
const XSTART = 200
const YPOS = 300

var originLocation
var exitLocation

var enteredFromOrigin
var originPoint
var exitPoint

func setup(dLine): #dungeon line, links the two points
	totalPoints = ceil(dLine.points[0].distance_to(dLine.points[1]) * Map.DISTANCE_TIME_MULT) - 1
	make_points(Vector2(XSTART, YPOS))

func make_points(nextPos, prevPoint = false):
	var point = Map.Point.instance()
	$Points.add_child(point)
	point.position = nextPos
	nextPos.x += INCREMENT
	if prevPoint: make_line(prevPoint, point)
	else: 
		originPoint = point
	if (nextPos.x-XSTART) / INCREMENT < totalPoints:
		make_points(nextPos, point)
	else:
		exitPoint = point

func determine_side():
	if Map.activePoint.info["direction"] == 0: #0 is left 1 is right
		originPoint.toggle_activation(true)
		enteredFromOrigin = true
	else:
		exitPoint.toggle_activation(true)
		enteredFromOrigin = false

func make_line(one, two):
	var line = Map.Line.instance()
	$Lines.add_child(line)
	line.add_point(one.position)
	line.add_point(two.position)
	line.linePoints.append(one)
	line.linePoints.append(two)
	line.get_node("Text").visible = false
	one.lines.append(line) #add line to points
	two.lines.append(line)

func evaluate_exit(point):
	if point == originPoint or point == exitPoint:
		$Exit.visible = true
	else:
		$Exit.visible = false

func enter():
	determine_side()
	visible = true

func switch_save(newSave): #If a player fully traversed the dungeon, switch the overworld's save point to the other side
	Map.savedPoint.toggle_activation(false)
	Map.savedPoint = newSave

func _on_Exit_pressed():
	if Map.activePoint == originPoint:
		if !enteredFromOrigin: switch_save(originLocation)
		originPoint.toggle_activation(false)
	else:
		if enteredFromOrigin: switch_save(exitLocation)
		exitPoint.toggle_activation(false)
	Map.savedPoint.toggle_activation(true, false) #Activate the overworld point, change false to true to skip activating the event
	Map.currentDungeon = false
	visible = false
