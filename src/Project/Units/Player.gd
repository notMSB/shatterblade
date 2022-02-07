extends "res://src/Project/Units/Unit.gd"

var equipment = {"Weapon": "", "Armor": "", "Accessory": ""}
var items = {"Rock": 2, "Herb": 1, "Toxic Salve": 1}
var spells = ["Lightning Bolt"]
var charges = [10, 1, 1]

func _ready():
	isPlayer = true
