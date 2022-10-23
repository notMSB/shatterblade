extends Node2D

const DEFAULTUSESDAMAGE = 4
const DEFAULTUSESOTHER = 8

var Battle
var moveList
enum rarities {unobtainable, rare, uncommon, common}
enum timings {before, after}
enum moveType {none, basic, item, special, magic, trick}
enum equipType {any, none, relic, gear}
enum targetType {enemy, enemies, enemyTargets, ally, allies, user, none}

func _ready():
	moveList = {
	"Attack": {"target": targetType.enemy, "damage": 5, "resVal": 0, "slot": equipType.relic, "type": moveType.basic, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "20% Recoil"},
	"Defend": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5], "description": "Adds 5 shield", "slot": equipType.relic, "type": moveType.basic},
	
	"Earthshaker": {"target": targetType.enemies, "damage": 10, "resVal": 60, "status": "Stun", "value": 1, "type": 1},
	"Firey Assault": {"target": targetType.enemyTargets, "damage": 5, "resVal": 40, "status": "Burn", "value": 1, "type": 1},
	"Special Boy": {"target": targetType.enemy, "damage": 5, "resVal": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "type": 1},
	
	
	"Careful Strike": {"target": targetType.enemy, "damage": 3, "resVal": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5], "description": "Deals danage and blocks", "slot": equipType.gear, "type": moveType.special},
	"Cleave": {"target": targetType.enemies, "damage": 5, "resVal": 30, "slot": equipType.gear, "type": moveType.special},
	"Dive Bomb": {"target": targetType.enemy, "damage": 15, "resVal": 20, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "User takes 20% of damage dealt back in recoil", "slot": equipType.gear, "type": moveType.special},
	"Pierce": {"target": targetType.enemyTargets, "damage": 4, "resVal": 25, "slot": equipType.gear, "type": moveType.special},
	"Poison Strike": {"target": targetType.enemy, "damage": 2, "resVal": 15, "status": "Poison", "value": 5, "quick": true, "slot": equipType.gear, "type": moveType.special},
	"Power Attack": {"target": targetType.enemy, "damage": 12, "resVal": 20, "slot": equipType.gear, "type": moveType.special},
	"Take Down": {"target": targetType.enemy, "damage": 7, "resVal": 30, "status": "Stun", "value": 1, "slot": equipType.gear, "type": moveType.special},
	"Triple Hit": {"target": targetType.enemy, "damage": 3, "resVal": 30, "hits": 3, "slot": equipType.gear, "type": moveType.special},
	"Vampire": {"target": targetType.enemy, "damage": 5, "resVal": 30, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", -.2], "description": "User heals 10% of damage dealt", "slot": equipType.gear, "type": moveType.special},
	
	"Flex": {"target": targetType.user, "resVal": 25, "status": "Double Damage", "value": 1, "quick": true, "slot": equipType.gear, "type": moveType.special},
	"Protect": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "switch_intents"), "args": ["moveTarget", "moveUser"], "quick": true, "slot": equipType.gear, "type": moveType.special},
	"Turtle Up": {"target": targetType.user, "resVal": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5, funcref(self, "get_enemy_targeters")], "description": "Shields more for each enemy targeting the user", "slot": equipType.gear, "type": moveType.special},
	
	
	"Constrict": {"target": targetType.enemy, "damage": 5, "resVal": 20, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Stun", funcref(self, "is_unit_poisoned")], "description": "Stuns target if they are poisoned", "slot": equipType.gear, "type": moveType.magic},
	"Frostfang": {"target": targetType.enemy, "damage": 10, "resVal": 20, "status": "Chill", "value": 50, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", .5, true], "description": "Multiplies target chill by 1.5 after the hit", "slot": equipType.gear, "type": moveType.magic},
	"Plague": {"target": targetType.enemies, "damaging": true, "resVal": 30, "status": "Poison", "value": 5, "slot": equipType.gear, "type": moveType.magic},
	"Venoshock": {"target": targetType.enemy, "damaging": true, "resVal": 10, "status": "Poison", "value": 5, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", funcref(self, "get_target_poison")],"description": "Inflict 5 poison on an enemy. Shield 1 for every poison that enemy has.", "slot": equipType.gear, "type": moveType.magic},
	
	"Dodge": {"target": targetType.user, "resVal": 20, "status": "Dodgy", "value": 1, "slot": equipType.gear, "type": moveType.magic},
	"Growth": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "change_attribute"), "args": ["moveTarget", "strength", 5], "description": "Strength +5 for the battle", "slot": equipType.gear, "type": moveType.magic},
	"Hide": {"target": targetType.ally, "resVal": 5, "effect": funcref(self, "switch_intents"), "args": ["moveUser", "moveTarget"], "slot": equipType.gear, "type": moveType.magic},
	"Restore": {"target": targetType.ally, "resVal": 5, "description": "Remove 100 from all statuses of target ally.", "slot": equipType.gear, "type": moveType.magic},
	
	
	"Coldsteel": {"target": targetType.enemy, "damage": 5, "resVal": 2, "status": "Chill", "value": 50, "hits": 2, "slot": equipType.gear, "type": moveType.trick},
	"Crusher Claw": {"target": targetType.enemy, "damage": 6, "resVal": 2, "timing": timings.before, "effect": funcref(self, "add_hits"), "args": ["moveTarget:shield", 0, 2, false], "description": "Extra hit if the target has shields", "slot": equipType.gear, "type": moveType.trick},
	"Piercing Sting": {"target": targetType.enemy, "damage": 10, "resVal": 5, "status": "Poison", "value": 5, "slot": equipType.gear, "type": moveType.trick},
	"Quick Attack": {"target": targetType.enemy, "damage": 3, "resVal": 5, "quick": true, "slot": equipType.gear, "type": moveType.trick},
	"Sucker Punch": {"target": targetType.enemy, "damage": 6, "resVal": 3, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 2], "description": "Extra hit if enemy targets user", "slot": equipType.gear, "type": moveType.trick},
	"Bonemerang": {"target": targetType.enemy, "damage": 4, "resVal": 1, "quick": true, "cycle": ["Catch"], "slot": equipType.gear, "type": moveType.trick, "uses": 12},
	
	"Taunt": {"target": targetType.enemy, "status": "Provoke", "value": 1, "resVal": 2, "quick": true, "slot": equipType.gear, "type": moveType.trick},
	"Eye Poke": {"target": targetType.enemy,"resVal": 2, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Stun", funcref(self, "is_enemy_targeting_user")], "description": "Inflict stun if enemy is targeting the user.", "slot": equipType.gear, "type": moveType.trick},
	
	"Reload": {"target": targetType.none, "resVal": 2, "cycle": true, "quick": true, "slot": equipType.none, "type": moveType.trick},
	"Catch": {"target": targetType.none, "resVal": 2, "cycle": true, "quick": true, "slot": equipType.none, "type": moveType.trick, "turnlimit": 1},
	
	"Speed Potion": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "give_status"), "args": ["moveUser", "Dodgy", funcref(self, "get_enemy_targeters")], "description": "Gives 1 dodge for every enemy targeting user", "slot": equipType.gear, "type": moveType.item},
	"Throwing Knife": {"target": targetType.enemy, "damage": 8, "resVal": 0, "slot": equipType.gear, "type": moveType.item, "uses": 2},
	"Brass Knuckles": {"target": targetType.enemy, "status": "Stun", "value": 1, "resVal": 0, "slot": equipType.gear, "type": moveType.item},
	"Health Potion": {"target": targetType.ally, "resVal": 0, "healing": 20, "slot": equipType.gear, "type": moveType.item},
	"Poison Potion": {"target": targetType.enemy, "resVal": 0, "status": "Poison", "value": 10, "slot": equipType.gear, "type": moveType.item},
	"Leather Buckler": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 15], "description": "Adds 15 shield", "slot": equipType.gear, "type": moveType.item},
	"Storm of Steel": {"target": targetType.enemy, "damage": 2, "resVal": 0, "slot": equipType.gear, "type": moveType.item, "hits": 12, "barrage": true},
	"Bone Zone": {"target": targetType.user, "resVal": 0, "quick": true ,"effect": funcref(self, "fill_boxes"), "args": ["moveUser", "Bone Attack"], "description": "bones", "slot": equipType.gear, "type": moveType.item},
	"Bone Attack": {"slot": equipType.none, "resVal": 0 ,"type": moveType.none, "uselimit": 1, "fleeting": true, "target": targetType.enemy, "damage": 7, "quick": true},
	
	"Rock": {"slot": equipType.none, "type": moveType.none, "uselimit": 1, "cycle": ["Stick"], "target": targetType.enemy, "damage": 3, "quick": true, "cursed": true},
	"Stick": {"slot": equipType.none, "type": moveType.none, "uselimit": 1, "cycle": true, "target": targetType.enemy, "damage": 7, "cursed": true},
	
	"Coin": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true ,"price": 1},
	"Silver": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true ,"price": 10},
	
	"Bracers": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "strength": 1, "price": 5},
	"Cape": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "passive": ["Dodgy", 1], "price": 5},
	"Stabilizer": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.rare, "uses": 5, "target": targetType.user, "resVal": 0, "status": "Durability Redirect", "value": 1, "quick": true},
	"Cloak of Visibility": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "passive": ["Provoke", 0], "price": 5},
	
	"Power Glove": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.uncommon, "morph": ["Attack+", "Defend+"]},
	"Attack+": {"slot": equipType.relic, "type": moveType.none, "morph": ["Attack+", "Defend+", "Power Glove"], "target": targetType.enemy, "damage": 10, "resVal": 0},
	"Defend+": {"slot": equipType.relic, "type": moveType.none, "morph": ["Attack+", "Defend+", "Power Glove"], "target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 10], "description": "Adds 10 shield"},
	
	"War Horn": {"target": targetType.user, "rarity": rarities.uncommon, "resVal": 0, "channel": true, "quick": true, "uselimit": 1, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "tempStrength", 2, "turnCount"], "description": "Attacks used this turn deal extra damage which increases every turn.", "slot": equipType.relic, "type": moveType.special},
	"Osmosis Device": {"slot": equipType.relic, "type": moveType.magic, "rarity": rarities.uncommon, "unusable": true, "passive": ["Gain Mana", 1]},
	"Power Loader": {"slot": equipType.relic, "type": moveType.trick, "rarity": rarities.uncommon, "unusable": true, "discount": [["Reload", 1], ["Catch", 1]], "description": "Reloads cost 1 less."},
	
	"Crown": {"slot": equipType.relic, "type": moveType.none, "cursed": true, "resVal": 0, "channel": true, "damage": 15, "target": targetType.enemy, "uselimit": 1},
	"Crown+": {"slot": equipType.relic, "type": moveType.none, "cursed": true, "resVal": 0, "channel": true, "damage": 15, "target": targetType.enemies, "uselimit": 1},
	
	"X": {"slot": equipType.any, "type": moveType.none, "resVal": 999} #temp
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
	var weight
	for move in moveList:
		moveData = moveList[move]
		if moveData.has("slot") and moveData["slot"] == equipType.relic:
			if moveData.has("rarity"):
				weight = moveData["rarity"]
			else: weight = 0
			for i in weight:
				relics.append(move)
	return relics

func get_uses(moveName):
	if !moveList.has(moveName): return -1
	if moveList[moveName].has("uses"): return moveList[moveName]["uses"]
	if moveList[moveName]["type"] <= moveType.basic: return -1
	if moveList[moveName]["slot"] == equipType.relic: return -1
	if moveList[moveName]["type"] == moveType.item: return 1
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

func is_enemy_targeting_user(enemy):
	var targetType = typeof(enemy.storedTarget)
	if (targetType == TYPE_STRING and enemy.storedTarget == "Party") or (enemy.storedTarget == Battle.moveUser):
		return 1
	return 0

func switch_intents(oldTarget, newTarget):
	var targeters = get_enemy_targeters(oldTarget)
	for enemy in targeters:
		Battle.set_intent(enemy, newTarget)

func restore_ap(unit, gain):
	if unit.isPlayer: unit.update_resource(gain, Battle.moveType.special, true)

func give_status(unit, status, value = 0, stack = null, altZero = false): #for when a status goes on someone besides the target
	var StatusManager = get_node("../StatusManager")
	if stack: #Multiply status based on its current value instead of adding
		var statusInfo = StatusManager.find_status(unit, status)
		StatusManager.add_status(unit, status, statusInfo["value"] * value)
	else:
		if value > 0:
			StatusManager.add_status(unit, status, value) 
		else:
			if altZero: StatusManager.add_status(unit, status, 0) #altzero decides whether a 0 means a status goes on forever or not at all

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
	if attribute == "strength" or attribute == "tempStrength": unit.update_strength()

func is_unit_poisoned(unit): #a little overly specific
	var StatusManager = get_node("../StatusManager")
	if StatusManager.find_status(unit, "Poison"): return 1
	else: return 0

func get_unit_poison(_unit): #kinda redundant, definitely a stopgap
	var StatusManager = get_node("../StatusManager")
	var statusInfo = StatusManager.find_status(Battle.moveTarget, "Poison")
	if statusInfo: return statusInfo["value"]
	else: return 0

func add_hits(firstCond, secondCond, hitCount, equal = true):
	if (equal and firstCond == secondCond) or (!equal and firstCond != secondCond):
		Battle.hits = hitCount

func fill_boxes(player, moveName):
	for box in player.boxHolder.get_children():
		var boxMove = box.moves[0]
		if boxMove == "X" or (moveList[boxMove].type == moveType.item and box.currentUses == 0):
			box.get_node("../../../").box_move(box, moveName)
			box.set_uses(-1)
			box.timesUsed = 0
