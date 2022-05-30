extends Node2D

var lines = []
var isActive = false

onready var Map = get_node("../../../")

func toggle_activation(active):
	toggle_lines(active)
	isActive = active
	$Sprite.visible = active
	if active: Map.activeNode = self

func toggle_lines(toggle):
	for line in lines:
		if is_instance_valid(line): #some lines may be deleted
			if check_neighbor(line) and !toggle: continue #do not turn off the active node's lines
			line.visible = toggle 
		else:
			lines.erase(line) #might as well get the deleted object out of the list

func check_neighbor(line): #checks if a line is connected to the active node
	if Map.activeNode:
		print(line.points)
		for pointPos in line.points:
			if pointPos == Map.activeNode.position:
				return true
	return false

func _on_Button_pressed():
	for line in lines:
		if check_neighbor(line): #the nodes are adjacent
			Map.activeNode.toggle_activation(false) #toggle off map's active node
			toggle_activation(true) #this is now the map's active node
			return #done

func _on_Button_mouse_entered():
	if !isActive: #the lines are already on if it's active
		toggle_lines(true)

func _on_Button_mouse_exited():
	if !isActive: #cannot turn off lines of the active node
		toggle_lines(false)
