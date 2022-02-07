extends Node2D

onready var Battle = get_parent()
var targets
var moveList

func _ready():
	targets = Battle.targetType
	moveList = {
	"Rock": {"target": targets.enemy, "damage": 20},
	"Herb": {"target": targets.ally, "healing": 10},
	"Potion": {"target": targets.ally, "healing": 50},
	"Toxic Salve": {"target": targets.enemy, "status": "Poison", "value": 100},
	"Torch": {"target": targets.enemy, "status": "Burn", "value": 100},
	}
