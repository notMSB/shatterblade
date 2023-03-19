extends Node

var Boons

const REWARD = 5
var level = 0

func start_battle(_startingHealth, battle): #make thorns passive
	for unit in global.storedParty:
		if level < 1:
			battle.StatusManager.add_status(unit, "Thorns", 2)
		else:
			battle.StatusManager.add_status(unit, "Thorns")

func post_status_eval(unit, real):
	if unit.currentHealth < 0 and real:
		#print("poison kill")
		Boons.grant_favor(REWARD)

func check_move(_usedBox, _targetHealth, moveUser, real):
	if moveUser.currentHealth <= 0 and !moveUser.isPlayer and real:
		#print("thorns/recoil kill")
		Boons.grant_favor(REWARD)
