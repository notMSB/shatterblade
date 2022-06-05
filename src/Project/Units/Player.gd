extends "res://src/Project/Units/Unit.gd"

var maxAP = 100
var charges = [10, 5, 2]
var maxCharges = [10, 5, 2]
var energy = 10
var maxEnergy = 10
var boxHolder

var allowedType
var types
var title

func _ready():
	isPlayer = true
	types = Battle.get_node("Moves").moveType

func update_resource(resValue, type, isGain: bool):
	if type == types.special:
		if isGain: ap = min(ap + resValue, maxap)
		else: ap -= resValue
	elif type == types.magic:
		if isGain: charges[resValue] +=1
		else: charges[resValue] -=1
	if type == types.trick:
		if isGain: energy = min(energy + resValue, maxEnergy)
		else: energy -= resValue
	update_box_bars()

func update_box_bars():
	var prevBox = boxHolder.get_children()[0]
	for box in boxHolder.get_children():
		if box.moveType != prevBox.moveType or (box.moveType == types.magic and box.resValue != prevBox.resValue):
			if box.moveType == types.special:
				box.trackerBar.value = ap
				box.trackerBar.get_child(0).text = str(ap, "/", maxAP)
			elif box.moveType == types.magic:
				box.trackerBar.value = charges[box.resValue]
				box.trackerBar.get_child(0).text = str(charges[box.resValue], "/", maxCharges[box.resValue])
			elif box.moveType == types.trick:
				box.trackerBar.value = energy
				box.trackerBar.get_child(0).text = str(energy, "/", maxEnergy)
			prevBox = box

func update_bar(bar, value, limit):
	bar.get_child(0).text = str(value, "/", limit)
