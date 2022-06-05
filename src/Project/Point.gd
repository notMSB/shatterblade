extends Node2D

var lines = []
var isActive = false
var pointType

onready var Map = get_node("../../../")

func toggle_activation(active):
	if active: 
		Map.activeNode = self
		if !($Sprite.visible): Map.activate_point(self.pointType)
		$Sprite.visible = true
		$Sprite.modulate = Color(1,1,1,1)
	else: 
		$Sprite.modulate = Color(.5,.1,.5,1) #special color for deactivating a previously active node
		Map.activeNode = null
	isActive = active
	toggle_lines(active)

func toggle_lines(toggle):
	for line in lines:
		if is_instance_valid(line): #some lines may be deleted
			if check_neighbor(line) and !toggle: continue #do not turn off the active node's lines
			line.visible = toggle 
		else:
			lines.erase(line) #might as well get the deleted object out of the list

func check_neighbor(line): #checks if a line is connected to the active node
	if Map.activeNode:
		for pointPos in line.points:
			if pointPos == Map.activeNode.position:
				return line
	return false

func _on_Button_pressed():
	if !Map.get_node("Events").visible:
		var movementLine
		for line in lines:
			movementLine = check_neighbor(line)
			if movementLine: #the nodes are adjacent
				Map.activeNode.toggle_activation(false) #toggle off map's active node
				toggle_activation(true) #this is now the map's active node
				Map.subtract_time(ceil(movementLine.points[0].distance_to(movementLine.points[1]) * Map.DISTANCE_TIME_MULT))
				return #done

func _on_Button_mouse_entered():
	if !isActive: #the lines are already on if it's active
		toggle_lines(true)

func _on_Button_mouse_exited():
	if !isActive: #cannot turn off lines of the active node
		toggle_lines(false)
