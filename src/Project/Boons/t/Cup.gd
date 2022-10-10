extends Node

var Boons

const REWARD = 5
var level = 1
var usedMulligan

func start_battle(_startingHealth):
	usedMulligan = false

func check_move(usedBox, targetHealth, _moveUser):
	if targetHealth == 0:
		print("cool")
		Boons.grant_favor(REWARD)
		if usedBox.maxUses > 0:
			usedBox.reduce_uses(-1)
		return false
	elif targetHealth < 0:
		if level >= 1 and !usedMulligan:
			usedMulligan = true
			Boons.grant_favor(REWARD) #mulligan means the task can be failed successfully
			return abs(targetHealth)
