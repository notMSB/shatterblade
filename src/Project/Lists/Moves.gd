extends Node2D

const DEFAULTUSESDAMAGE = 4
const DEFAULTUSESOTHER = 8

var Battle
var moveList
enum timings {before, after}
enum moveType {none, basic, relic, item, special, magic, trick}
enum targetType {enemy, enemies, enemyTargets, ally, allies, user, none}

func _ready():
	moveList = {
	"Attack": {"target": targetType.enemy, "damage": 5, "resVal": 0, "type": moveType.basic, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "20% Recoil"},
	"Defend": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5], "description": "Adds 5 shield", "type": moveType.basic},
	
	"Earthshaker": {"target": targetType.enemies, "damage": 10, "resVal": 60, "status": "Stun", "value": 100, "type": 1},
	"Firey Assault": {"target": targetType.enemyTargets, "damage": 5, "resVal": 40, "status": "Burn", "value": 100, "type": 1},
	"Special Boy": {"target": targetType.enemy, "damage": 5, "resVal": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "type": 1},
	
	
	"Careful Strike": {"target": targetType.enemy, "damage": 3, "resVal": 20, "effect": funcref(self, "give_status"), "args": ["moveUser", "Blocking", 1], "description": "Deals danage and blocks", "type": moveType.special},
	"Cleave": {"target": targetType.enemies, "damage": 5, "resVal": 30, "type": moveType.special},
	"Dive Bomb": {"target": targetType.enemy, "damage": 15, "resVal": 20, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "User takes 20% of damage dealt back in recoil", "type": moveType.special},
	"Pierce": {"target": targetType.enemyTargets, "damage": 4, "resVal": 25, "type": moveType.special},
	"Poison Strike": {"target": targetType.enemy, "damage": 2, "resVal": 15, "status": "Poison", "value": 50, "quick": true, "type": moveType.special},
	"Power Attack": {"target": targetType.enemy, "damage": 12, "resVal": 20, "type": moveType.special},
	"Take Down": {"target": targetType.enemy, "damage": 7, "resVal": 30, "status": "Stun", "value": 100, "type": moveType.special},
	"Triple Hit": {"target": targetType.enemy, "damage": 3, "resVal": 30, "hits": 3, "type": moveType.special},
	"Vampire": {"target": targetType.enemy, "damage": 5, "resVal": 30, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", -.2], "description": "User heals 10% of damage dealt", "type": moveType.special},
	
	"Flex": {"target": targetType.user, "resVal": 25, "status": "Double Damage", "value": 1, "quick": true, "type": moveType.special},
	"Protect": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "switch_intents"), "args": ["moveTarget", "moveUser"], "quick": true, "type": moveType.special},
	"Turtle Up": {"target": targetType.user, "resVal": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5, funcref(self, "get_enemy_targeters")], "description": "Shields more for each enemy targeting the user", "type": moveType.special},
	
	
	"Constrict": {"target": targetType.enemy, "damage": 2, "resVal": 10, "effect": funcref(self, "give_status"), "args": ["moveUser", "Constricting", 1], "description": "Grabs target and strikes next turn if not removed", "type": moveType.magic},
	"Frostfang": {"target": targetType.enemy, "damage": 10, "resVal": 20, "status": "Chill", "value": 50, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", .5, true], "description": "Multiplies target chill by 1.5 after the hit", "type": moveType.magic},
	"Plague": {"target": targetType.enemies, "damaging": true, "resVal": 30, "status": "Poison", "value": 75, "type": moveType.magic},
	"Venoshock": {"target": targetType.enemy, "damaging": true, "resVal": 10, "description": "Inflict 100 poison on an enemy. Shield 1 for every 20 poison that enemy has.", "type": moveType.magic},
	
	"Dodge": {"target": targetType.user, "resVal": 20, "status": "Dodge", "value": 1, "type": moveType.magic},
	"Growth": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "strength", 5], "description": "Strength +5 for the battle", "type": moveType.magic},
	"Hide": {"target": targetType.ally, "resVal": 5, "effect": funcref(self, "switch_intents"), "args": ["moveUser", "moveTarget"], "type": moveType.magic},
	"Restore": {"target": targetType.ally, "resVal": 5, "description": "Remove 100 from all statuses of target ally.", "type": moveType.magic},
	
	
	"Bonemerang": {"target": targetType.enemy, "damage": 3, "resVal": 1, "quick": true, "type": moveType.trick},
	"Coldsteel": {"target": targetType.enemy, "damage": 5, "resVal": 2, "status": "Chill", "value": 50, "hits": 2, "type": moveType.trick},
	"Crusher Claw": {"target": targetType.enemy, "damage": 6, "resVal": 2, "timing": timings.before, "effect": funcref(self, "add_hits"), "args": ["moveTarget:shield", 0, 2, false], "description": "Extra hit if the target has shields", "type": moveType.trick},
	"Piercing Sting": {"target": targetType.enemy, "damage": 20, "resVal": 5, "status": "Poison", "value": 100, "type": moveType.trick},
	"Quick Attack": {"target": targetType.enemy, "damage": 3, "resVal": 5, "quick": true, "type": moveType.trick},
	"Sucker Punch": {"target": targetType.enemy, "damage": 6, "resVal": 3, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 2], "description": "Extra hit if enemy targetType user", "type": moveType.trick},
	
	"Taunt": {"target": targetType.enemy, "status": "Provoke", "value": 100, "resVal": 2, "quick": true, "type": moveType.trick},
	"Eye Poke": {"target": targetType.enemy, "resVal": 2, "description": "Inflict 100 stun if enemy is targeting the user.", "type": moveType.trick},
	
	"Reload": {"target": targetType.none, "resVal": 2, "cycle": true, "quick": true, "type": moveType.basic},
	
	
	"Double Slash": {"target": targetType.enemy, "damage": 4, "resVal": 1, "type": moveType.item},
	
	"Test Relic": {"type": moveType.relic, "resVal": 0, "unusable": true, "passive": ["Dodgy", 1], "price": 5},
	"Another Relic": {"type": moveType.relic, "resVal": 0, "unusable": true, "passive": ["Dodgy", 1], "price": 5},
	
	"Channel Power": {"target": targetType.user, "resVal": 0, "channel": true, "quick": true, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "strength", 5], "description": "Attacks used this turn deal 5 extra damage.", "type": moveType.relic},
	
	"X": {"type": moveType.none, "resVal": 999} #temp
}

func get_classname(type):
	if type == moveType.special: return "Fighter"
	elif type == moveType.magic: return "Mage"
	elif type == moveType.trick: return "Rogue"
	
func random_moveType():
	var typeList = [moveType.special, moveType.magic, moveType.trick]
	return typeList[randi() % typeList.size()]
	
func get_relics():
	var relics = []
	var moveData
	for move in moveList:
		moveData = moveList[move]
		if moveData.has("type") and moveData["type"] == moveType.relic:
			relics.append(move)
	return relics

func get_uses(moveName):
	if !moveList.has(moveName) or moveList[moveName]["type"] <= moveType.relic: return -1
	if moveList[moveName]["type"] == moveType.item: return 1
	if moveList[moveName].has("uses"): return moveList[moveName]["uses"]
	if moveList[moveName].has("damage"): return DEFAULTUSESDAMAGE
	return DEFAULTUSESOTHER

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
