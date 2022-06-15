extends Node2D

var lines = []
var isActive = false
var pointType = 0
var clicksFromStart
var info = {}

onready var Map = get_tree().current_scene

func toggle_activation(active, skip = false):
	if active: 
		Map.activePoint = self
		if (!skip and pointType != Map.pointTypes.visited): Map.activate_point(self.pointType) #skip used to exit dungeon without reactivating it
		$Sprite.visible = true
		$Sprite.modulate = Color(1,1,1,1)
	else: 
		deactivate_color()
		Map.activePoint = null
		if pointType < Map.pointTypes.visited:
			pointType = Map.pointTypes.visited
	isActive = active
	toggle_lines(active)

func deactivate_color():
	$Sprite.modulate = Color(.5,.1,.5,1) #special color for deactivating a previously active node

func toggle_lines(toggle):
	for line in lines:
		if is_instance_valid(line): #some lines may be deleted
			if check_neighbor(line) and !toggle: continue #do not turn off the active node's lines
			line.visible = toggle 
		else:
			lines.erase(line) #might as well get the deleted object out of the list

func check_neighbor(line, excludeDungeon = false): #checks if a line is connected to the active node
	if Map.activePoint:
		for pointPos in line.points:
			if pointPos == Map.activePoint.position: #dungeon lines
				if excludeDungeon and line.dungeonLine: return false
				else: return line
	return false

func set_name(text):
	$Name.visible = true
	$Name.text = str(text)

func _on_Button_pressed():
	if !Map.get_node("Events").visible and self != Map.activePoint:
		var movementLine
		for line in lines:
			movementLine = check_neighbor(line, true) #exclude dungeon lines
			if movementLine: #the nodes are adjacent
				Map.activePoint.toggle_activation(false) #toggle off map's active node
				toggle_activation(true) #this is now the map's active node
				if Map.currentDungeon: 
					Map.currentDungeon.evaluate_exit(Map.activePoint)
					Map.subtract_time(1)
				else: 
					Map.subtract_time(ceil(movementLine.points[0].distance_to(movementLine.points[1]) * Map.DISTANCE_TIME_MULT))
				return #done

func _on_Button_mouse_entered():
	if !isActive: #the lines are already on if it's active
		toggle_lines(true)

func _on_Button_mouse_exited():
	if !isActive: #cannot turn off lines of the active node
		toggle_lines(false)
