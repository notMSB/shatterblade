extends Node

var Boons

const SHIELDVAL = 10

var level = 0

func uses_reduced(user, usedBox, useNumber, real, battle):
	if !real: useNumber -= 1 #simulating 0 uses as the preview doesn't actually subtract one
	if useNumber == 0: #broken gear
		if real:
			Boons.grant_favor(2 * usedBox.maxUses)
			Boons.Map.inventoryWindow.check_and_award_component(usedBox)
			
		if level >= 1 and battle.visible:
			user.shield += SHIELDVAL
			if real: user.update_hp()
