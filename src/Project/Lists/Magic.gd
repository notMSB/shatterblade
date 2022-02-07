extends Node2D

onready var Battle = get_parent()
var targets
var moveList

func _ready():
	targets = Battle.targetType
	moveList = {
	"Fire": {"type": "black", "target": targets.enemy, "damage": 20, "status": "Burn", "value": 150, "level": 0},
	"Heal": {"type": "white", "target": targets.ally, "healing": 20, "level": 0},
	
	"Biobeam": {"type": "black", "target": targets.enemy, "damage": 10, "status": "Poison", "value": 100, "level": 1},
	
	"Fireball": {"type": "black", "target": targets.enemies, "damage": 20, "level": 2},
	"Lightning Bolt": {"type": "black", "target": targets.enemyTargets, "damage": 20, "status": "Stun", "value": 50, "level": 2},
	
	"Teamheal": {"type": "white", "target": targets.allies, "healing": 20, "level": 2}
}
