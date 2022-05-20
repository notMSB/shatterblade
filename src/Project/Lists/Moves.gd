extends Node2D

onready var Battle = get_parent()
var targets
var moveList
enum timings {before, after}
enum moveType {basic, special, magic, trick, item}

func _ready():
	targets = Battle.targetType
	moveList = {
	"Attack": {"target": targets.enemy, "damage": 5, "resVal": 0, "args": ["moveUser", 10], "type": moveType.basic},
	"Defend": {"target": targets.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5], "description": "Adds 5 shield", "type": moveType.basic},
	
	"Earthshaker": {"target": targets.enemies, "damage": 10, "resVal": 60, "status": "Stun", "value": 100, "type": 1},
	"Firey Assault": {"target": targets.enemyTargets, "damage": 5, "resVal": 40, "status": "Burn", "value": 100, "type": 1},
	"Special Boy": {"target": targets.enemy, "damage": 5, "resVal": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "type": 1},
	
	
	"Careful Strike": {"target": targets.enemy, "damage": 3, "resVal": 20, "effect": funcref(self, "give_status"), "args": ["moveUser", "Blocking", 1], "description": "Deals danage and blocks", "type": moveType.special},
	"Cleave": {"target": targets.enemies, "damage": 5, "resVal": 30},
	"Dive Bomb": {"target": targets.enemy, "damage": 15, "resVal": 20, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "User takes 10% of damage dealt back in recoil", "type": moveType.special},
	"Pierce": {"target": targets.enemyTargets, "damage": 4, "resVal": 25, "type": moveType.special},
	"Poison Strike": {"target": targets.enemy, "damage": 2, "resVal": 15, "status": "Poison", "value": 50, "quick": true, "type": moveType.special},
	"Power Attack": {"target": targets.enemy, "damage": 12, "resVal": 20, "type": moveType.special},
	"Take Down": {"target": targets.enemy, "damage": 7, "resVal": 30, "status": "Stun", "value": 100, "type": moveType.special},
	"Triple Hit": {"target": targets.enemy, "damage": 3, "resVal": 30, "hits": 3, "type": moveType.special},
	"Vampire": {"target": targets.enemy, "damage": 5, "resVal": 30, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", -.2], "description": "User heals 10% of damage dealt", "type": moveType.special},
	
	"Flex": {"target": targets.user, "resVal": 25, "status": "Double Damage", "value": 1, "quick": true, "type": moveType.special},
	"Protect": {"target": targets.ally, "effect": funcref(self, "switch_intents"), "args": ["moveTarget", "moveUser"], "type": moveType.special},
	"Turtle Up": {"target": targets.user, "resVal": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5, funcref(self, "get_enemy_targeters")], "description": "Shields more for each enemy targeting the user", "type": moveType.special},
	
	
	"Constrict": {"target": targets.enemy, "damage": 2, "resVal": 1, "effect": funcref(self, "give_status"), "args": ["moveUser", "Constricting", 1], "description": "Grabs target and strikes next turn if not removed", "type": moveType.magic},
	"Frostfang": {"target": targets.enemy, "damage": 10, "resVal": 2, "status": "Chill", "value": 50, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", .5, true], "description": "Multiplies target chill by 1.5 after the hit", "type": moveType.magic},
	"Plague": {"target": targets.enemies, "resVal": 2, "status": "Poison", "value": 2, "type": moveType.magic},
	
	"Channel Power": {"target": targets.user, "resVal": 0, "channel": true, "quick": true, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "strength", 5], "description": "Attacks used this turn deal 5 extra damage.", "type": moveType.magic},
	"Dodge": {"target": targets.user, "resVal": 1, "status": "Dodge", "value": 1, "type": moveType.magic},
	"Growth": {"target": targets.ally, "resVal": 1, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "strength", 5], "description": "Strength +5 for the battle", "type": moveType.magic},
	"Hide": {"target": targets.ally, "resVal": 1, "effect": funcref(self, "switch_intents"), "args": ["moveUser", "moveTarget"], "type": moveType.magic},
	"Restore": {"target": targets.ally, "resVal": 1, "description": "Remove 100 from all statuses of target ally.", "type": moveType.magic},
	"Venoshock": {"target": targets.enemy, "resVal": 1, "description": "Inflict 100 poison on an enemy. Shield 1 for every 20 poison that enemy has.", "type": moveType.magic},
	
	
	"Bonemerang": {"target": targets.enemy, "damage": 3, "resVal": 1, "quick": true},
	"Coldsteel": {"target": targets.enemy, "damage": 5, "resVal": 2, "status": "Chill", "value": 50, "hits": 2, "type": moveType.trick},
	"Crusher Claw": {"target": targets.enemy, "damage": 6, "resVal": 2, "timing": timings.before, "effect": funcref(self, "add_hits"), "args": ["moveTarget:shield", 0, 2, false], "description": "Extra hit if the target has shields", "type": moveType.trick},
	"Eye Rake": {"target": targets.enemy, "damage": 6, "resVal": 2, "description": "Inflict 100 stun if enemy is targeting the user.", "type": moveType.trick},
	"Piercing Sting": {"target": targets.enemy, "damage": 20, "resVal": 1, "status": "Poison", "value": 100, "type": moveType.trick},
	"Quick Attack": {"target": targets.enemy, "damage": 3, "resVal": 5, "quick": true, "type": moveType.trick},
	"Sucker Punch": {"target": targets.enemy, "damage": 6, "resVal": 3, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 2], "description": "Extra hit if enemy targets user", "type": moveType.trick},
	
	"Taunt": {"target": targets.enemy, "status": "Provoke", "value": 100, "resVal": 2, "quick": true, "type": moveType.trick},
	
	"Reload": {"target": targets.none, "resVal": 2, "quick": true, "type": moveType.trick},
	
	
	"Double Slash": {"target": targets.enemy, "damage": 4, "resVal": 1, "type": moveType.item},
}

#Effects
func get_enemy_targeters(unit):
	var targeters = []
	for enemy in Battle.get_team(false):
		if typeof(enemy.storedTarget) != TYPE_STRING:
			if enemy.storedTarget == unit:
				targeters.append(enemy)
	return targeters

func switch_intents(oldTarget, newTarget):
	var targeters = get_enemy_targeters(oldTarget)
	for enemy in targeters:
		Battle.set_intent(enemy, newTarget)

func restore_ap(unit, gain):
	if unit.isPlayer: unit.update_resource(gain, Battle.moveType.special, true)

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
	if attribute == "strength": unit.update_strength()

func add_hits(firstCond, secondCond, hitCount, equal = true):
	if (equal and firstCond == secondCond) or (!equal and firstCond != secondCond):
		Battle.hits = hitCount
