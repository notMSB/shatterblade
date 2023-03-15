extends Node

var Boons

const REWARD = 5

var level = 0
var turnUses = 0
var previewUses = 0

func start_turn():
	turnUses = 0

func start_preview(_previewUnits):
	previewUses = 0

func uses_reduced(user, _usedBox, _useNumber, real, battle):
	if real: turnUses += 1
	else: previewUses += 1
	if turnUses > global.storedParty.size() or (!real and previewUses > global.storedParty.size()):
		battle.StatusManager.add_status(user, "Dodgy", 1)
		if real:
			Boons.grant_favor(REWARD)
			if level >= 1: battle.doubleXP = true
			
		
