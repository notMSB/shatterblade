extends Node2D

var isPlayer
var maxHealth
var strength
var defense
var speed

var storedAction
var storedTarget

var currentHealth
var ap = 0
var maxap = 100
var shield = 5

var ui #set in battle function

var statuses = []
var hittables = [] #Keeps track of statuses that count down on hit
var passives = {}

var specials = ["Crusher Claw", "Sucker Punch"]

func make_stats(hp, atk, def, spd):
	maxHealth = hp
	currentHealth = maxHealth
	strength = atk
	defense = def
	speed = spd

func take_damage(damageVal):
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
	return damageVal

func heal(healVal):
	currentHealth = min(maxHealth, currentHealth + healVal)
	update_hp()
	if currentHealth <= 0:
		ui.visible = false

func update_hp():
	ui.get_node("HP").text = String(currentHealth)
	if shield > 0:
		ui.get_node("HP").text += "[" + String(shield) + "]"

func update_ap(change):
	ap = min(ap + change, maxap)
	ui.get_node("Info").text = String(ap)

func update_info(text):
	ui.get_node("Info").text = String(text)

func update_status_ui():
	var text = ""
	for category in statuses:
		for status in category:
			#print(status["name"][0])
			text += status["name"][0] + status["name"][1]
			if status.has("value"):
				text += "[" + String(status["value"]) + "]"
			text += "\n"
	if text == "": text = "[]"
	ui.get_node("Statuses").text = text
