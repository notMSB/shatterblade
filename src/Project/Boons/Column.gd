extends Node

var Boons

const REWARD = 5
var healthCheck = []
var level = 0

func start_battle(_startingHealth):
	healthCheck.clear()
	for unit in global.storedParty:
		unit.shield += 5
		unit.update_hp()
		
		healthCheck.append(unit.currentHealth)
		unit.ui.get_node("BattleElements/VirtueStatus").text = String(unit.currentHealth)

func start_turn():
	if level >= 1:
		for unit in global.storedParty:
			unit.shield += 5
			unit.update_hp()

func end_battle(_endingHealth):
	var failures = 0
	for i in global.storedParty.size():
		if global.storedParty[i].currentHealth < healthCheck[i]:
			failures += 1
		global.storedParty[i].ui.get_node("BattleElements/VirtueStatus").text = ""
	if failures <= healthCheck.size() * .5:
		Boons.grant_favor(REWARD)
