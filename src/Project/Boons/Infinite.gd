extends Node

var Boons

var level = [false, false]

func uses_reduced(user, usedBox, useNumber, real, battle):
	if !real: useNumber -= 1 #simulating 0 uses as the preview doesn't actually subtract one
	if useNumber == 0: #broken gear
		if real:
			Boons.grant_favor(2 * usedBox.maxUses)
			if level[1]: Boons.Map.inventoryWindow.check_and_award_component(usedBox, true)
			else: Boons.Map.inventoryWindow.check_and_award_component(usedBox)
			
		if level[0] and battle.visible:
			battle.StatusManager.add_status(user, "Dodgy", 1)
			battle.StatusManager.add_status(user, "Resist", 1)
