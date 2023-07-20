extends Node2D

onready var Map = get_node("../../../")

var index
var type

var totalPoints = 5
var loadedExits
const INCREMENT = 70
const XSTART = 320
const YPOS = 250

var originPoint
var mascot = null
var biomesUsed = []

func setup():
	loadedExits = 0
	totalPoints += Map.currentArea
	biomesUsed = Map.curate_biomes(3)
	if !mascot: 
		mascot = Map.currentMascot
		$Description.text = str(mascot, " Dungeon")
	make_points(Vector2(XSTART, YPOS))

func make_points(nextPos, prevPoint = false):
	var point = Map.Point.instance()
	$Points.add_child(point)
	point.position = nextPos
	nextPos.x += INCREMENT
	if prevPoint: 
		make_line(prevPoint, point)
		if prevPoint != originPoint: prevPoint.pointType = Map.pointTypes.battle
	else: 
		originPoint = point
	if (nextPos.x-XSTART) / INCREMENT < totalPoints:
		make_points(nextPos, point)
		if (nextPos.x-XSTART) / INCREMENT > totalPoints - 2:
			point.pointType = Map.pointTypes.temple
			point.set_type_text("T")
			if Map.currentArea < 2:
				split(point, true)
				split(point, false)
	else:
		set_exit(point, Vector2(INCREMENT, 0))

func split(prevPoint, direction):
	var point = Map.Point.instance()
	var posFix = INCREMENT if direction else INCREMENT * -1
	$Points.add_child(point)
	point.position = prevPoint.position
	point.position.y += posFix
	set_exit(point, Vector2(0, posFix))
	make_line(prevPoint, point)

func set_exit(point, posFix):
	var exitBiomeUI = get_node(str("Biomes/", loadedExits))
	exitBiomeUI.position = point.position + posFix
	point.pointType = Map.pointTypes.boss
	point.set_type_text("B")
	point.info["biome"] = biomesUsed.pop_front()
	Map.set_biome_ui(exitBiomeUI, point.info["biome"])
	loadedExits+=1

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
	if point == originPoint:
		$Exit.visible = true
	else:
		$Exit.visible = false

func enter():
	originPoint.toggle_activation(true)
	visible = true
	Map.currentDungeon = self

func exit():
	Map.savedPoint.toggle_activation(true, false) #Activate the overworld point, change false to true to skip activating the event
	Map.currentDungeon = null
	visible = false

func _on_Exit_pressed():
	exit()
