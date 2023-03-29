extends Node

var Boons

const REWARD = 5
var usedBoxes = []
var boxesOK = true
var level = [false, false]
var startedScales = false

func prep_inventory():
	#print("scales prep inventory")
	for unit in global.storedParty:
		unit.moves.insert(0, "Snapshot")
	startedScales = true
	return 1

func added_boon(invNode):
	for i in global.storedParty.size():
		add_rocks(i, invNode)
		var bar = global.storedParty[i].ui.get_node("Trackers/ResourceTracker/ResourceBar")
		bar.margin_right += 80
		bar.get_node("Text").rect_position.x += 40

func new_member(invNode):
	add_rocks(global.storedParty.size() - 1, invNode)
	if !startedScales:
		var bar = global.storedParty[-1].ui.get_node("Trackers/ResourceTracker/ResourceBar")
		bar.margin_right += 80
		bar.get_node("Text").rect_position.x += 40

func add_rocks(i, invNode):
	var boxHolder = invNode.dHolder.get_child(i).get_node("MoveBoxes")
	if !startedScales:
		var boxCount = boxHolder.get_child_count()
		invNode.dHolder.create_move(global.storedParty[i], i, boxCount) #boxCount becomes inaccurate due to adding a new box here, but that is ok
		boxHolder.get_child(boxCount).trackerBar = boxHolder.get_child(2).trackerBar
		for j in boxCount - 2:
			invNode.swap_boxes(boxHolder.get_child(boxCount - j), boxHolder.get_child(boxCount - j - 1))
	var rockName = "Snapshot" if !level[0] else "Snapshot+"
	invNode.dHolder.box_move(boxHolder.get_child(2), rockName, true)
	invNode.identify_product(boxHolder.get_child(2))

func level_up(invNode, upgradeIndex):
	for i in global.storedParty.size():
			var boxHolder = invNode.dHolder.get_child(i).get_node("MoveBoxes")
			if upgradeIndex == 0: 
				if level[1]: invNode.dHolder.box_move(boxHolder.get_child(2), "Sidewinder+")
				else: invNode.dHolder.box_move(boxHolder.get_child(2), "Snapshot+")
			else: 
				if level[0]: invNode.dHolder.box_move(boxHolder.get_child(2), "Sidewinder+")
				else: invNode.dHolder.box_move(boxHolder.get_child(2), "Sidewinder")
		

func start_battle(_startingHealth, _battle):
	boxesOK = true

func check_move(usedBox, _targetHealth, _moveUser, real):
	if real:
		if !usedBoxes.has(usedBox):
			usedBoxes.append(usedBox)
			usedBox.get_node("Scales").visible = true
		else:
			if !(usedBox.moveIndex == 0 and usedBox.moves.size() > 1): #may need to revisit this when other multimoves are implemented
				#print("Repeat")
				boxesOK = false

func end_battle(_endingHealth, _battle):
	if boxesOK: Boons.grant_favor(REWARD)
	for box in usedBoxes:
		box.get_node("Scales").visible = false
	usedBoxes.clear()
