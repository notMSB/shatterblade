extends Node

var Boons

const REWARD = 5
const MAXENEMIES = 4

var moveUsers = []
var previewUsers = []
var killers = []
var level = 0

func start_battle(_startingHealth):
	moveUsers.clear()
	killers.clear()
	for member in global.storedParty:
		killers.append([member, 0])
		member.ui.get_node("BattleElements/VirtueStatus").text = "0"

func start_preview(previewUnits):
	previewUsers.clear()
	for i in moveUsers.size():
		previewUsers.append(previewUnits[i])

func before_move(moveUser, real): #returns a bonus to amount of hits the move has, level lets entire party get a hit
	var currentUsers = moveUsers if real else previewUsers
	if !currentUsers.has(moveUser):
		currentUsers.append(moveUser)
		if level >= 1: return 1
		elif currentUsers.size() < 2: return 1
	return 0

func check_move(_usedBox, targetHealth, moveUser, real):
	if targetHealth <= 0 and real:
		for entry in killers:
			if entry[0] == moveUser:
				entry[1] += 1
				entry[0].ui.get_node("BattleElements/VirtueStatus").text = String(entry[1])
		#if level >= 1:
			#moveUsers.erase(moveUser) #refresh bonus hit

func end_battle(_endingHealth):
	var highest = 0
	var lowest = MAXENEMIES
	for entry in killers:
		entry[0].ui.get_node("BattleElements/VirtueStatus").text = ""
		if entry[1] > highest: highest = entry[1]
		if entry[1] < lowest: lowest = entry[1]
	if highest - lowest >= 2:
		pass#print("failure")
	else:
		#print("success")
		Boons.grant_favor(REWARD)
	
