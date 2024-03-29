extends Node

var Boons

const REWARD = 5
var level = [false, false]
var usedMulligan
var previewMulligan

func start_battle(_startingHealth, _battle):
	usedMulligan = false
	previewMulligan = false

func start_preview(_previewUnits):
	previewMulligan = usedMulligan

func check_hit(usedBox, targetHealth, moveUser, real, battle): #fix so that murdering your own party doesn't give favor
	if moveUser.isPlayer:
		if targetHealth == 0:
			if real:
				Boons.grant_favor(REWARD)
				if usedBox.maxUses > 0:
					usedBox.reduce_uses(-1)
				return false
			if level[1]:
				for unit in global.storedParty:
					unit.shield += battle.damageCalc
					unit.update_hp()
		elif targetHealth < 0:
			if level[0] and !usedMulligan:
				if real: 
					usedMulligan = true
					Boons.grant_favor(REWARD) #mulligan means the task can be failed successfully
				previewMulligan = true
				return abs(targetHealth)
			
	else:
		if moveUser.currentHealth == 0 and real:
			#print("thorns/recoil kill")
			Boons.grant_favor(REWARD)

func post_status_eval(unit, real):
	if unit.currentHealth == 0 and real:
		#print("poison kill")
		Boons.grant_favor(REWARD)
	
