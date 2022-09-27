extends Node2D

enum v {none, j, s, t}
const DEFAULTREWARD = 5

var Map = null

var chosen = v.none
var favor = 0

var usedBoxes = []
var boxesOK = true
var HPcheck = 0

func start_battle(startingHealth):
	if chosen == v.j: usedBoxes.clear()
	elif chosen == v.s: HPcheck = startingHealth

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
