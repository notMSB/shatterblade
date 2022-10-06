extends Node2D

enum v {none, j, s, t}
const DEFAULTREWARD = 5

var Map = null

var chosen = v.s
var favor = 0

var usedBoxes = []
var boxesOK = true
var HPcheck = 0

#At some point every boon will be its own node/script with functions activated from this one

func start_battle(startingHealth):
	if chosen == v.j: usedBoxes.clear()
	elif chosen == v.s:
		HPcheck = startingHealth
		for unit in global.storedParty:
			unit.shield += 5
			unit.update_hp()

func check_move(usedBox, targetHealth):
	if chosen == v.j:
		if !usedBoxes.has(usedBox):
			usedBoxes.append(usedBox)
		else:
			print("Repeat")
	elif chosen == v.t:
		if targetHealth == 0:
			print("cool")
			grant_favor(DEFAULTREWARD)
			if usedBox.maxUses > 0:
				usedBox.reduce_uses(-1)
		elif targetHealth < 0:
			print("uncool")

func end_battle(endingHealth):
	if chosen == v.j:
		if boxesOK: grant_favor(DEFAULTREWARD)
	elif chosen == v.s:
		if endingHealth >= HPcheck: grant_favor(DEFAULTREWARD)

func grant_favor(amount):
	favor+=amount
	if Map: Map.update_favor(favor)
