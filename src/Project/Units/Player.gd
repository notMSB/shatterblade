extends "res://src/Project/Units/Unit.gd"

var equipment = {"Weapon": "", "Armor": "", "Accessory": ""}
var items = {"Rock": 2, "Herb": 1, "Toxic Salve": 1}
var spells = ["Lightning Bolt"]
var charges = [10, 1, 1]
var maxCharges = [10, 1, 1]

enum moveType {basic, special, magic, item}

func _ready():
	isPlayer = true

func update_resource(resValue, type, isGain: bool):
	if type == moveType.special:
		if isGain: ap = min(ap + resValue, maxap)
		else: ap -= resValue
		if ui.get_node_or_null("ResourceTracker") != null:
			var bar = ui.get_node("ResourceTracker/ResourceBar")
			bar.value = ap
			bar.get_child(0).text = str(ap, "/", 100)
	elif type == moveType.magic: 
		if isGain: charges[resValue] += 1
		else: charges[resValue] -= 1
		if ui.get_node_or_null("ResourceTracker") != null:
			var bar = ui.get_node("ResourceTracker/ResourceBar")
			bar.value = charges[resValue]
			bar.get_child(0).text = str(charges[resValue], "/", maxCharges[resValue])
	else: #tool/item, maybe consolidate code with above later
		if isGain: items[resValue] += 1
		else: items[resValue] -= 1
		if ui.get_node_or_null("ResourceTracker") != null:
			var bar = ui.get_node("ResourceTracker/ResourceBar")
			bar.value = items[resValue]
			bar.get_child(0).text = str(charges[resValue])
