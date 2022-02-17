extends Node2D

onready var Battle = get_parent()
var targets
var moveList
enum timings {before, after}

func _ready():
	targets = Battle.targetType
	moveList = {
	"Attack": {"target": targets.enemy, "damage": 5, "effect": funcref(self, "restore_ap"), "args": ["moveUser", 10]},
	"Defend": {"target": targets.user, "status": "Blocking", "value": 1, "effect": funcref(self, "restore_ap"), "args": ["moveUser", 10]},
	
	"Double Slash": {"target": targets.enemy, "damage": 4, "cost": 20, "hits": 2},
	"Pierce": {"target": targets.enemyTargets, "damage": 4, "cost": 25},
	"Cleave": {"target": targets.enemies, "damage": 5, "cost": 30},
	"Quick Attack": {"target": targets.enemy, "damage": 3, "cost": 15, "quick": true},
	
	"Poison Strike": {"target": targets.enemy, "damage": 2, "cost": 15, "status": "Poison", "value": 50, "quick": true, "weight": 1},
	"Earthshaker": {"target": targets.enemies, "damage": 10, "cost": 60, "status": "Stun", "value": 100, "weight": 1},
	"Coldsteel": {"target": targets.enemy, "damage": 5, "cost": 30, "status": "Chill", "value": 50, "hits": 2, "weight": 1},
	"Firey Assault": {"target": targets.enemyTargets, "damage": 5, "cost": 40, "status": "Burn", "value": 100, "weight": 1},
	
	"Power Attack": {"target": targets.enemy, "damage": 12, "cost": 20, "weight": 2},
	"Careful Strike": {"target": targets.enemy, "damage": 3, "cost": 20, "effect": funcref(self, "give_status"), "args": ["moveUser", "Blocking", 1], "description": "Deals danage and blocks", "weight": 2},
	"Special Boy": {"target": targets.enemy, "damage": 5, "cost": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "weight": 1},
	"Sucker Punch": {"target": targets.enemy, "damage": 6, "cost": 20, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 2], "description": "Extra hit if enemy targets user", "weight": 2},
	
	"Piercing Sting": {"target": targets.enemy, "damage": 20, "cost": 40, "status": "Poison", "value": 100, "weight": 1},
	"Crusher Claw": {"target": targets.enemy, "damage": 6, "cost": 20, "timing": timings.before, "effect": funcref(self, "add_hits"), "args": ["moveTarget:shield", 0, 2, false], "description": "Extra hit if the target has shields", "weight": 1},
	"Plague": {"target": targets.enemies, "cost": 50, "status": "Poison", "value": 100, "weight": 1},
	"Dive Bomb": {"target": targets.enemy, "damage": 15, "cost": 20, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "User takes 10% of damage dealt back in recoil", "weight": 2},
	"Take Down": {"target": targets.enemy, "damage": 7, "cost": 30, "status": "Stun", "value": 100, "weight": 1},
	"Vampire": {"target": targets.enemy, "damage": 5, "cost": 30, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", -.2], "description": "User heals 10% of damage dealt", "weight": 1},
	"Frostfang": {"target": targets.enemy, "damage": 10, "cost": 20, "status": "Chill", "value": 50, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", .5, true], "description": "Multiplies target chill by 1.5 after the hit", "weight": 2},
	"Constrict": {"target": targets.enemy, "damage": 2, "cost": 20, "effect": funcref(self, "give_status"), "args": ["moveUser", "Constricting", 1], "description": "Grabs target and strikes next turn if not removed", "weight": 1},
	"Triple Hit": {"target": targets.enemy, "damage": 3, "cost": 30, "hits": 3, "weight": 1},
	"Growth": {"target": targets.user, "cost": 25, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "strength", 5], "description": "Strength +5 for the battle", "weight": 1},
	"Dodge": {"target": targets.user, "cost": 25, "status": "Dodge", "value": 1},
	
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

func give_status(unit, status, value = 0, stack = null): #for when a status goes on someone besides the target
	var StatusManager = get_node("../StatusManager")
	if stack: #Multiply status based on its current value instead of adding
		var statusInfo = StatusManager.find_status(unit, status)
		StatusManager.add_status(unit, status, statusInfo["value"] * value)
	else:
		if value > 0:
			StatusManager.add_status(unit, status, value)
		else:
			StatusManager.add_status(unit, status)

func take_recoil(unit, damage, modifier):
	if modifier >= 0:
		unit.take_damage(damage * modifier)
	else:
		unit.heal(damage * modifier * -1)

func change_attribute(unit, attribute, amount, multiplier = 1):
	if typeof(multiplier) == TYPE_ARRAY: #for when i am getting weird with passing arguments
		multiplier = multiplier.size()
	var temp = unit.get(attribute) + (amount * multiplier)
	unit.set(attribute, temp)
	if attribute == "shield": unit.update_hp()

func add_hits(firstCond, secondCond, hitCount, equal = true):
	if (equal and firstCond == secondCond) or (!equal and firstCond != secondCond):
		Battle.hits = hitCount
