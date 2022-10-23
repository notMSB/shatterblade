extends Node

var Boons

const REWARD = 5
var level = 0

func prep_inventory():
	global.itemDict["moves"].append("Crown")

func check_move(usedBox, targetHealth, _moveUser):
	if targetHealth < 0 and (usedBox.moves[0] == "Crown" or usedBox.moves[0] == "Crown+"):
		print("cool")
		Boons.grant_favor(REWARD)
