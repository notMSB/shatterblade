extends Node

var Boons

const REWARD = 4
var level = [false, false]

func start_battle(_startingHealth, battle): #make thorns passive
	for unit in global.storedParty:
		if !level[0]:
			battle.StatusManager.add_status(unit, "Thorns", 2)
		else:
			battle.StatusManager.add_status(unit, "Thorns")
		if level[1]:
			battle.StatusManager.add_status(unit, "Venomous")

func post_status_eval(unit, real):
	if unit.currentHealth < 0 and real:
		#print("poison kill")
		Boons.grant_favor(REWARD)

func check_move(_usedBox, _targetHealth, moveUser, real):
	if moveUser.currentHealth <= 0 and !moveUser.isPlayer and real:
		#print("thorns/recoil kill")
		Boons.grant_favor(REWARD)
