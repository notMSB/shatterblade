extends Node2D

var lifetime = 1
var next = .5

var unpaused = false

var drift = -0.5

func set_text(text, color, up = true):
	if !up: drift *= -1
	$Text.text = str(text)
	$Text.modulate = color

func _process(delta):
	position.y += drift
	lifetime -= delta
	if lifetime <= next and !unpaused: 
		get_parent().unpause()
		unpaused = true
	if lifetime <= 0: queue_free()
