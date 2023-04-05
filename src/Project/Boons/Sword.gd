extends Node

var Boons

const REWARD = 7
var level = [false, false]

func level_up(invNode, _upgradeIndex):
	invNode.repairBonus = true

func uses_reduced(user, usedBox, useNumber, real, battle):
	if battle.Moves.moveList[usedBox.moves[0]].has("damage"):
		var originalUses = useNumber
		if real: originalUses = useNumber + 1
		if originalUses == usedBox.maxUses:
			if real: Boons.grant_favor(REWARD)
			if level[1]:
				user.strength += 2
				user.update_strength()
			else: battle.damageBuff += 2
