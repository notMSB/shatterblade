extends "res://src/Project/Units/Unit.gd"

var identity
var targetlock = false
var allMoves = ["Attack"]

func _ready():
	isPlayer = false
