extends Node

var Boons

const REWARD = 5
var level = 1

func start_battle(_startingHealth): #make thorns passive
	for unit in global.storedParty:
		if level < 1:
			unit.passives["Thorns"] = 1
		else:
			unit.passives["Thorns"] = 0

func post_status_eval(unit):
	if unit.currentHealth < 0:
		print("poison kill")
		Boons.grant_favor(REWARD)

func check_move(_usedBox, _targetHealth, moveUser):
	if moveUser.currentHealth < 0:
		print("thorns/recoil kill")
		Boons.grant_favor(REWARD)
