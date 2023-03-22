extends Node2D

onready var Battle

#Statuses are stored using a 2D array which is set by activation condition
#When a condition occurs, functions are run if that condition's array has 1 or more items in it
enum statusActivations {beforeTurn, gettingHit, usingAttack, gettingKill, afterHit, successfulHit, passive}

const COUNTDOWNVAL = 50

#If system is true, uses points system. If false, uses turns system. If system is absent, lasts forever. Points/Turns are applied by moves.
var statusList = {
	"Regen": {"activation": statusActivations.beforeTurn, "effect": funcref(self, "regenerate"), "args": ["unit", 1]},
	
	"Poison": {"activation": statusActivations.beforeTurn, "subtractEarly": true, "system": true, "effect": funcref(self, "value_damage"), "args": ["unit", "value",]},
	"Burn": {"activation": statusActivations.usingAttack, "system": true, "effect": funcref(self, "adjust_damage"), "args": ["damage", -1, "value", "unit", "self"]},
	"Chill": {"activation": statusActivations.gettingHit, "system": true, "effect": funcref(self, "adjust_damage"), "args": ["damage", 1, "value", "unit", "self"]},
	"Stun": {"activation": statusActivations.beforeTurn, "subtractLate": true, "system": false, "effect": funcref(self, "stunned"), "args": ["unit"]},
	
	"Provoke": {"activation": statusActivations.passive, "system": false},
	"Stealth": {"activation": statusActivations.passive, "system": false},
	
	"Icarus": {"activation": statusActivations.gettingHit, "system": false, "effect": funcref(self, "apply_icarus"), "args": ["unit", "damage"]},
	"IDamage": {"activation": statusActivations.beforeTurn, "effect": funcref(self, "pop_icarus"), "args": ["unit", "value"], "neverCountdown": true},
	
	"Double Damage": {"activation": statusActivations.usingAttack, "system": false, "effect": funcref(self, "multiply_damage"), "args": ["damage", 1]},
	"Blocking": {"activation": statusActivations.gettingHit, "system": false, "effect": funcref(self, "multiply_damage"), "args": ["damage", 0.5]},
	"Durability Redirect": {"activation": statusActivations.passive, "system": false},
	"Movecost Refund": {"activation": statusActivations.gettingKill, "effect": funcref(self, "refund_resource"), "args": ["usedMoveBox", "unit"]},
	"Gain Mana": {"activation": statusActivations.gettingKill, "effect": funcref(self, "refund_resource"), "args": ["damage", "unit"]},
	
	"Venomous": {"activation": statusActivations.successfulHit, "effect": funcref(self, "add_status"), "args": ["target", "Poison", 2]},
	"Dodgy": {"activation": statusActivations.gettingHit, "effect": funcref(self, "multiply_damage"), "args": ["damage", -1]},
	"Thorns": {"activation": statusActivations.afterHit, "system": false, "effect": funcref(self, "counter_attack"), "args": ["attacker", 5]},
	"Firewall": {"activation": statusActivations.afterHit, "system": false, "effect": funcref(self, "counter_attack"), "args": ["attacker", "shield"]},
	"Constricting": {"activation": statusActivations.beforeTurn, "effect": funcref(self, "constrict_attack"), "args": ["unit", "intent"], "targetlock": true, "hittable": true},
}

func initialize_statuses(unit):
	for condition in statusActivations:
		unit.statuses.append([])

func remove_hittables(unit):
	if unit.hittables.size() > 0:
		for status in unit.hittables:
			var list = unit.statuses[statusList[status]["activation"]]
			for cond in list:
				var statusInfo = statusList[cond["name"]]
				if statusInfo.has("hittable"):
					remove_status(unit, list, cond)
					unit.hittables.erase(status)
			

func countdown_turns(unit, turnStart): 
	for list in unit.statuses:
		for cond in list:
			if cond.has("value"): #do not countdown turns when there are no turns
				var status = statusList[cond["name"]]
				if status.has("system"): #Pass if there is no countdown system
					if status["system"] and (turnStart == status.has("subtractEarly")): #Points usually subtract at turn end
						cond["value"] -= ceil(cond["value"] *.5)
					elif !status["system"] and (turnStart != status.has("subtractLate")): #Turns usually subtract at turn start
						cond["value"] -= 1
					if cond["value"] <= 0:
						remove_status(unit, list, cond) #Remove the status if there's no more points or turns
					unit.update_status_ui()

func add_status(unit, status, value = 0): #If value is not sent, status does not time out
	var addedStatus = find_status(unit, status) #need to see if it's on already
	if addedStatus: #if so, just increment the values of the existing one
		if value > 0:
			addedStatus["value"] += floor(value)
	else: #if not, generate a new instance
		addedStatus = {"name": status}
		if value > 0:
			addedStatus["value"] = floor(value)
		unit.statuses[statusList[status]["activation"]].append(addedStatus) #This adds the status and duration/value to the unit's personal status 2D array
		if !unit.isPlayer and statusList[status].has("targetlock"):
			unit.targetlock = true
		if statusList[status].has("hittable"):
			unit.hittables.append(status)
	if unit.ui: unit.update_status_ui()
	#print(unit.statuses)

func reduce_status(unit, status, value):
	var targetInfo = find_status(unit, status, true)
	if targetInfo:
		var targetList = targetInfo[0]
		var targetStatus = targetInfo[1]
		if !targetStatus: return
		targetStatus["value"] -= floor(value)
		if targetStatus["value"] <= 0:
			remove_status(unit, targetList, targetStatus)
		if unit.ui: unit.update_status_ui()

func remove_status(unit, list, cond):
	if !unit.isPlayer and statusList[cond["name"]].has("targetlock"): #If the status in the above list has target lock, remove the enemy's lock
		unit.targetlock = false
	list.erase(cond)

func find_status(unit, status, returnList = false):
	var list = unit.statuses[statusList[status]["activation"]]
	for cond in list:
		if cond["name"] == status:
			if returnList: return [list, cond]
			return cond

func evaluate_statuses(unit, type, args = []):
	var info = 0 if args.empty() else args[0] #has to return a number even if check for on hit activation comes up empty
	if !unit.statuses[type].empty():
		var list = unit.statuses[type]
		for cond in list:
			var statusInfo = statusList[cond["name"]]
			if statusInfo.has("effect"):
				var newArgs = []
				if statusInfo.has("args"):
					for argument in statusInfo["args"]:
						if String(argument) == "damage" or String(argument) == "usedMoveBox": newArgs.append(info)
						elif String(argument) == "unit": newArgs.append(unit)
						elif String(argument) == "target": newArgs.append(Battle.moveTarget)
						elif String(argument) == "attacker": newArgs.append(Battle.moveUser)
						elif String(argument) == "value": newArgs.append(cond["value"])
						elif String(argument) == "intent": newArgs.append(unit.storedTarget)
						elif String(argument) == "self": newArgs.append(cond["name"])
						elif String(argument) == "shield": newArgs.append(unit.shield)
						else: newArgs.append(argument)
				var newInfo = statusInfo["effect"].call_funcv(newArgs)
				if newInfo != null: info = newInfo
				if !statusInfo.has("system") and cond.has("value") and !statusInfo.has("neverCountdown"): #If there is no system for subtracting turns automatically, subtract one manually after proc
					cond["value"] -= 1
					if cond["value"] <= 0:
						remove_status(unit, list, cond)
	if type == statusActivations.gettingHit: #Some statuses remove on getting hit and are not under the gettingHit activation
		remove_hittables(unit)
	if unit.ui: unit.update_status_ui()
	return info


#Effects

func multiply_damage(damage, adjustment, value = 1):
	var multiplier = 1 if adjustment >= 0 else -1
	var damageMod = floor(damage * value * abs(adjustment)) #abs needed since floor/ceil round negative numbers oppositely
	return max(0, damage + (damageMod * multiplier))

func adjust_damage(damage, direction, value, user, statusName):
	var newDamage = damage + value * direction
	if direction > 0:
		if value > damage:
			newDamage = damage * 2
			reduce_status(user, statusName, damage)
			return newDamage
	else:
		if newDamage < 0:
			reduce_status(user, statusName, damage)
			return 0
	reduce_status(user, statusName, value)
	return newDamage

func refund_resource(refundVal, user):
	user.update_resource(refundVal, user.types.magic, true)

func percentage_damage(unit, value, damage):
	unit.take_damage(unit.maxHealth * value * damage)
	return unit.maxHealth * damage

func value_damage(unit, value, multiplier = 1):
	unit.take_damage(value * multiplier)
	return unit.currentHealth

func counter_attack(target, value):
	if value > 0: target.take_damage(value)

func regenerate(unit, healing):
	unit.heal(healing)
	return unit.currentHealth

func constrict_attack(attacker, target):
	target.take_damage(attacker.strength)

func apply_icarus(unit, damage):
	add_status(unit, "IDamage", damage)
	return 0

func pop_icarus(unit, value):
	if !find_status(unit, "Icarus"):
		unit.take_damage(value)
		reduce_status(unit, "IDamage", value)

func stunned(unit):
	unit.isStunned = true
	return -1 #placeholder
