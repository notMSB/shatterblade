extends Node

var Boons

const REWARD = 5
var healthCheck = 0
var level = 0

func start_battle(startingHealth):
	healthCheck = startingHealth
	for unit in global.storedParty:
		unit.shield += 5
		unit.update_hp()

func start_turn():
	if level >= 1:
		for unit in global.storedParty:
			unit.shield += 5
			unit.update_hp()

func end_battle(endingHealth):
	if endingHealth >= healthCheck: Boons.grant_favor(REWARD)
