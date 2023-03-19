extends Node

var Boons

const REWARD = 8

var level = 0

func level_up(invNode):
	invNode.repairBonus = true

func uses_reduced(_user, usedBox, useNumber, real, battle):
	if battle.Moves.moveList[usedBox.moves[0]].has("damage"):
		var originalUses = useNumber
		if real: originalUses = useNumber + 1
		if originalUses == usedBox.maxUses:
			if real: Boons.grant_favor(REWARD)
			battle.damageBuff += 2
