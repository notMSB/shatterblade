extends Node2D

onready var Battle = get_node("../../")

var isPlayer
var maxHealth

var strength = 0
var speed = 0
var defense = 0

var storedAction
var storedTarget

var currentHealth
var ap = 0
var maxap = 100
var shield = 0

var ui #set in battle function

var statuses = []
var hittables = [] #Keeps track of statuses that count down on hit
var passives = {}

var moves = []

func make_stats(hp):
	maxHealth = hp
	currentHealth = maxHealth

func take_damage(damageVal):
	if currentHealth > 0: #Can't be hitting someone that's dead
		if shield > 0:
			if shield - damageVal > 0:
				shield -= damageVal
				damageVal = 0
			else:
				damageVal -= shield
				shield = 0
		if shield <= 0:
			currentHealth -= floor(max(1, damageVal))
		update_hp()
		if currentHealth <= 0:
			ui.visible = false
			damageVal += currentHealth #Returns amount of damage actually dealt for recoil reasons
			if !isPlayer: 
				Battle.deadEnemies += 1
				if Battle.deadEnemies >= Battle.enemyNum:
					Battle.battleDone = true
		return damageVal

func heal(healVal):
	currentHealth = min(maxHealth, currentHealth + healVal)
	update_hp()

func update_hp():
	if ui != null:
		ui.get_node("BattleElements/HPBar").value = currentHealth
		ui.get_node("BattleElements/HPBar/Text").text = str(currentHealth, "/", maxHealth)
		if isPlayer:
			ui.get_node("BattleElements/Shield").text = "[" + String(shield) + "]"
		else:
			ui.get_node("BattleElements/HP").text += "[" + String(shield) + "]"

func update_strength():
	if ui != null:
		if isPlayer:
			ui.get_node("BattleElements/Strength").text = "+" + String(strength)

func update_info(text):
	if ui.get_node_or_null("Info") != null:
		ui.get_node("Info").text = String(text)

func cease_to_exist():
	ui.queue_free()
	queue_free()

func update_status_ui():
	var text = ""
	for category in statuses:
		var i = 0
		for status in category:
			#print(status["name"][0])
			if i > 0: text += ", "
			text += status["name"][0] + status["name"][1]
			if status.has("value"):
				text += "[" + String(status["value"]) + "]"
			i+=1
	if text == "": text = "[]"
	if ui.get_node_or_null("BattleElements/Statuses") != null:
		ui.get_node("BattleElements/Statuses").text = text
