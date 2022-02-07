extends Node2D

onready var Battle = get_parent()
var targets
var moveList

func _ready():
	targets = Battle.targetType
	moveList = {
	"Attack": {"target": targets.enemy, "damage": 5, "effect": funcref(self, "restore_ap"), "args": ["moveUser", 10]},
	"Defend": {"target": targets.user, "status": "Blocking", "value": 1, "effect": funcref(self, "restore_ap"), "args": ["moveUser", 10]},

	"Double Slash": {"target": targets.enemy, "damage": 5, "cost": 20, "hits": 2},
	"Pierce": {"target": targets.enemyTargets, "damage": 5, "cost": 25},
	"Cleave": {"target": targets.enemies, "damage": 7, "cost": 30},
	"Quick Attack": {"target": targets.enemy, "damage": 5, "cost": 15, "quick": true},
	
	"Poison Stab": {"target": targets.enemy, "damage": 5, "cost": 15, "status": "Poison", "value": 50, "quick": true, "weight": 1},
	"Earthshaker": {"target": targets.enemies, "damage": 10, "cost": 60, "status": "Stun", "value": 100, "weight": 1},
	"Coldsteel": {"target": targets.enemy, "damage": 5, "cost": 30, "status": "Chill", "value": 50, "hits": 2, "weight": 1},
	"Firey Assault": {"target": targets.enemyTargets, "damage": 5, "cost": 40, "status": "Burn", "value": 100, "weight": 1},
	
	"Power Attack": {"target": targets.enemy, "damage": 12, "cost": 20, "weight": 2},
	"Careful Strike": {"target": targets.enemy, "damage": 5, "cost": 20, "effect": funcref(self, "give_status"), "args": ["moveUser", "Blocking", 1], "description": "Deals danage and blocks", "weight": 2},
	"Special Boy": {"target": targets.enemy, "damage": 5, "cost": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "weight": 1},
	"Sucker Punch": {"target": targets.enemy, "damage": 8, "cost": 20, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 2], "description": "Extra hit if enemy targets user", "weight": 2},
	
	"Turtle Up": {"target": targets.user, "cost": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5, funcref(self, "get_enemy_targeters")], "description": "Shields more for each enemy targeting the user", "weight": 2},
	"Flex": {"target": targets.user, "cost": 25, "status": "Double Damage", "value": 1, "quick": true, "weight": 1},
	"Taunt": {"target": targets.enemy, "status": "Provoke", "value": 100, "cost": 20, "quick": true, "weight": 2},
	"Protect": {"target": targets.ally, "effect": funcref(self, "switch_intents"), "args": ["moveTarget", "moveUser"], "weight": 2},
	"Hide": {"target": targets.ally, "effect": funcref(self, "switch_intents"), "args": ["moveUser", "moveTarget"], "weight": 2},
}

#Effects
func get_enemy_targeters(unit):
	var targeters = []
	for enemy in Battle.get_team(false):
		if enemy.storedTarget == unit:
			targeters.append(enemy)
	return targeters

func switch_intents(oldTarget, newTarget):
	var targeters = get_enemy_targeters(oldTarget)
	for enemy in targeters:
		Battle.set_intent(enemy, newTarget)

func restore_ap(unit, gain):
	if unit.isPlayer: unit.update_ap(gain)

func give_status(unit, status, value = 0): #for when a status goes on someone besides the target
	if value > 0:
		get_node("../StatusManager").add_status(unit, status, value)
	else:
		get_node("../StatusManager").add_status(unit, status)

func change_attribute(unit, attribute, amount, multiplier = 1): #for when a status goes on someone besides the target
	if typeof(multiplier) == TYPE_ARRAY: #for when i am getting weird with passing arguments
		multiplier = multiplier.size()
	var temp = unit.get(attribute) + (amount * multiplier)
	unit.set(attribute, temp)
	if attribute == "shield": unit.update_hp()

func add_hits(firstCond, secondCond, hitCount):
	if firstCond == secondCond:
		Battle.hits = hitCount
