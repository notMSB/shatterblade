extends Node

var Boons

const REWARD = 5
var level = [false, false]
var STRENGTHBUFF = 2
var SHIELDVAL = 8

func start_battle(_startingHealth, battle):
	battle.canSee = false
	for unit in global.storedParty:
		if level[1]: unit.strength += STRENGTHBUFF
		else: unit.tempStrength += STRENGTHBUFF
		unit.update_strength()

func check_hit(_usedMoveBox, targetHealth, moveUser, _real, battle):
	if targetHealth <= 0 and level[0] and !battle.canSee:
		moveUser.shield += SHIELDVAL
		moveUser.update_hp()

func end_battle(_endingHealth, battle):
	if battle.get_node("Peek").visible: Boons.grant_favor(REWARD)

func peek(turnCount):
	if turnCount <= 1:
		for unit in global.storedParty:
			if level[1]: unit.strength -= STRENGTHBUFF
			else: unit.tempStrength -= STRENGTHBUFF
			unit.update_strength()
