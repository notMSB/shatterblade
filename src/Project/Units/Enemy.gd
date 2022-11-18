extends "res://src/Project/Units/Unit.gd"

var identity
var targetlock = false
var allMoves = ["Attack"]
var spriteBase

func _ready():
	isPlayer = false
	if maxHealth > 15: allMoves[0] = "Attack+"
