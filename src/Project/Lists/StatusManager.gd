extends Node2D

onready var Battle = get_parent()

#Statuses are stored using a 2D array which is set by activation condition
#When a condition occurs, functions are run if that condition's array has 1 or more items in it
enum statusActivations {beforeTurn, gettingHit, usingAttack, passive}

const THRESHOLD = 100
const COUNTDOWNVAL = 50

#If system is true, uses points system. If false, uses turns system. If system is absent, lasts forever. Points/Turns are applied by moves.
var statusList = {
	"Regen": {"activation": statusActivations.beforeTurn, "effect": funcref(self, "regenerate"), "args": ["unit", 1]},
	
	"Poison": {"activation": statusActivations.beforeTurn, "system": true, "effect": funcref(self, "percentage_damage"), "args": ["unit", "value", 0.001]},
	"Burn": {"activation": statusActivations.usingAttack, "system": true, "effect": funcref(self, "adjust_damage"), "args": ["damage", 0.002, "value"]},
	"Chill": {"activation": statusActivations.gettingHit, "system": true, "effect": funcref(self, "adjust_damage"), "args": ["damage", -0.002, "value"]},
	"Stun": {"activation": statusActivations.beforeTurn, "system": true, "effect": funcref(self, "stunned")},
	"Provoke": {"activation": statusActivations.passive, "system": true},
	
	"Double Damage": {"activation": statusActivations.usingAttack, "system": false, "effect": funcref(self, "adjust_damage"), "args": ["damage", 2]},
	"Blocking": {"activation": statusActivations.gettingHit, "system": false, "effect": funcref(self, "adjust_damage"), "args": ["damage", 0.5]},
	
	"Venomous": {"activation": statusActivations.usingAttack, "effect": funcref(self, "add_status"), "args": ["target", "Poison", 75]},
	"Dodgy": {"activation": statusActivations.gettingHit, "effect": funcref(self, "adjust_damage"), "args": ["damage", 1]},
}

func initialize_statuses(unit):
	for condition in statusActivations:
		unit.statuses.append([])

func countdown_turns(unit, turnStart): 
	for list in unit.statuses:
		for cond in list:
			var status = statusList[cond["name"]]
			if status.has("system"): #Pass if there is no countdown system
				if !turnStart and status["system"]: #Points subtract at turn end
					cond["value"] -= 2*COUNTDOWNVAL if cond["value"] >= THRESHOLD else COUNTDOWNVAL
				elif turnStart and !status["system"] : #Turns subtract at turn start
					cond["value"] -= 1
				if cond["value"] <= 0:
					list.erase(cond) #Remove the status if there's no more points or turns
				unit.update_status_ui()

func add_status(unit, status, value = 0): #If value is not sent, status does not time out
	var addedStatus = find_status(unit, status) #need to see if it's on already
	if addedStatus: #if so, just increment the values of the existing one
		if value > 0:
			addedStatus["value"] += value
	else: #if not, generate a new instance
		addedStatus = {"name": status}
		if value > 0:
			addedStatus["value"] = value
		unit.statuses[statusList[status]["activation"]].append(addedStatus)
	unit.update_status_ui()
	#print(unit.statuses)

func find_status(unit, status):
	var list = unit.statuses[statusList[status]["activation"]]
	for cond in list:
		if cond["name"] == status:
			return cond

func evaluate_statuses(unit, type, args = []):
	var info = 0 if args.empty() else args[0] #has to return a number even if check for on hit activation comes up empty
	if !unit.statuses[type].empty():
		var list = unit.statuses[type]
		for cond in list:
			var statusInfo = statusList[cond["name"]]
			if statusInfo.has("effect"):
				if statusInfo.has("system") and statusInfo["system"]: #If using points system
					if cond["value"] < THRESHOLD: #Points system statuses do not take effect if points value is below the threshold
						#print("skipping")
						continue
				var newArgs = []
				if statusInfo.has("args"):
					for argument in statusInfo["args"]:
						if String(argument) == "damage": newArgs.append(info)
						elif String(argument) == "unit": newArgs.append(unit)
						elif String(argument) == "target": newArgs.append(Battle.moveTarget)
						elif String(argument) == "value": newArgs.append(cond["value"])
						else: newArgs.append(argument)
				info = statusInfo["effect"].call_funcv(newArgs)
				if !statusInfo.has("system") and cond.has("value"): #If there is no system for subtracting turns automatically, subtract one manually after proc
					cond["value"] -= 1
					if cond["value"] <= 0:
						list.erase(cond)
		unit.update_status_ui()
	return info


#Effects

func adjust_damage(damage, adjustment, value = 1):
	return damage - (damage * value * adjustment)

func percentage_damage(unit, value, damage):
	unit.take_damage(unit.maxHealth * value * damage)
	return unit.maxHealth * damage
	

func regenerate(unit, healing):
	unit.heal(healing)
	return unit.currentHealth

func stunned():
	return Battle.STUNCODE
