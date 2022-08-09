extends Line2D

var linePoints = []
var dungeonLine = false

func dungeonize():
	modulate = Color(1, .1, .1, 1)
	dungeonLine = true

func get_connection(notPoint):
	for point in linePoints:
		if point != notPoint: return point
