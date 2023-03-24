extends Node

var Boons

const REWARD = 10
var president = null
var level = [false, false]

func start_battle(_startingHealth, battle):
	for unit in global.storedParty:
		if !president: president = unit
		elif unit.currentHealth < president.currentHealth: president = unit
	president.currentHealth = 1
	president.update_hp()
	if level[0]: battle.StatusManager.add_status(president, "Stealth", 2)
	else: battle.StatusManager.add_status(president, "Provoke", 2)
	if level[1]:
		for unit in global.storedParty:
			if unit != president: battle.StatusManager.add_status(unit, "Dodgy", 1)

func end_battle(_endingHealth, _battle):
	if president.currentHealth > 0: 
		president.currentHealth = president.maxHealth
		president.update_hp()
		Boons.grant_favor(REWARD)
	president = null
