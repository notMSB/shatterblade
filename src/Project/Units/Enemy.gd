extends "res://src/Project/Units/Unit.gd"

var targetlock = false
var allMoves = ["Attack"]
var spriteBase

func _ready():
	isPlayer = false
	if maxHealth != null and maxHealth > 15: allMoves[0] = "Attack+"
