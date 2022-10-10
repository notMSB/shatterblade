extends Node

var Boons

const REWARD = 5
const MAXENEMIES = 4

var moveUsers = []
var killers = []
var level = 0

func start_battle(_startingHealth):
	moveUsers.clear()
	killers.clear()
	for member in global.storedParty:
		killers.append([member, 0])

func before_move(moveUser): #returns a bonus to amount of hits the move has, level lets entire party get a hit
	if !moveUsers.has(moveUser):
		moveUsers.append(moveUser)
		if level >= 1: return 1
		elif moveUsers.size() < 2: return 1
	return 0

func check_move(_usedBox, targetHealth, moveUser):
	if targetHealth <= 0:
		for entry in killers:
			if entry[0] == moveUser:
				entry[1] += 1
		#if level >= 1:
			#moveUsers.erase(moveUser) #refresh bonus hit

func end_battle(_endingHealth):
	var highest = 0
	var lowest = MAXENEMIES
	for entry in killers:
		if entry[1] > highest: highest = entry[1]
		if entry[1] < lowest: lowest = entry[1]
	if highest - lowest >= 2:
		print("failure")
	else:
		print("success")
		Boons.grant_favor(REWARD)
	
