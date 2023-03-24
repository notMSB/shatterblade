extends Node

var Boons

const REWARD = 5

var level = [false, false]
var turnUses = 0
var previewUses = 0

func start_turn():
	turnUses = 0

func start_preview(_previewUnits):
	previewUses = 0

func uses_reduced(user, _usedBox, _useNumber, real, _battle):
	var modifier = 1 if level[1] else 0
	if real: turnUses += 1
	else: previewUses += 1
	if turnUses > global.storedParty.size() - modifier or (!real and previewUses > global.storedParty.size() - modifier):
		if level[0]:
			if real: 
				user.shield += turnUses
				user.update_hp()
			else: user.shield += previewUses
		user.strength += 1
		user.update_strength()
		if real:
			Boons.grant_favor(REWARD)
