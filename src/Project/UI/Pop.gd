extends Node2D

var lifetime = 1

var drift = -0.5

func set_text(text, color, up = true):
	if !up: drift *= -1
	$Text.text = str(text)
	$Text.modulate = color

func _process(delta):
	position.y += drift
	lifetime -= delta
	if lifetime <= 0: queue_free()
