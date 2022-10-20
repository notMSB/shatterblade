extends Node

var Boons

const REWARD = 5
var usedBoxes = []
var boxesOK = true

func prep_inventory():
	print("scales prep inventory")
	for unit in global.storedParty:
		unit.moves.insert(0, "Rock")
	return 1

func start_battle(_startingHealth):
	boxesOK = true
	usedBoxes.clear()

func check_move(usedBox, _targetHealth, _moveUser):
	if !usedBoxes.has(usedBox):
		usedBoxes.append(usedBox)
	else:
		print("Repeat")
		boxesOK = false

func end_battle(_endingHealth):
	if boxesOK: Boons.grant_favor(REWARD)
