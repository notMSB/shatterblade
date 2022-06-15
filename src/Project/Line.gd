extends Line2D

var linePoints = []
var dungeonLine = false

func dungeonize():
	modulate = Color(1, .1, .1, 1)
	dungeonLine = true
