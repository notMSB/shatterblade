extends Node2D

export (PackedScene) var UICircle

onready var Battle = get_node("../../")

var virtue = false
var isPlayer
var maxHealth
var identity = ""
var real = true
var boxHolder

var killedMove = ""

var startingStrength = 0
var tempStrength = 0
var strength = 0
var baseHealing = 0
var speed = 0
var defense = 0

var isStunned = false

var storedAction
var storedTarget

var currentHealth
var shield = 0

var ui #set in battle function
var battleName = ""
var displayName = ""

var statuses = []
var hittables = [] #Keeps track of statuses that count down on hit
var passives = {}

var moves = []

func clone_values(original):
	currentHealth = original.currentHealth
	maxHealth = original.maxHealth
	shield = original.shield
	strength = original.strength
	storedTarget = original.storedTarget
	storedAction = original.storedAction
	identity = original.identity
	statuses = original.statuses.duplicate(true)
	real = false

func make_stats(hp):
	maxHealth = hp
	currentHealth = maxHealth

func take_damage(damageVal, pierce = false, moveName = ""):
	if virtue: return
	if currentHealth > 0: #Can't be hitting someone that's dead
		if shield > 0 and !pierce:
			if shield - damageVal > 0:
				shield -= damageVal
				damageVal = 0
			else:
				damageVal -= shield
				shield = 0
		if shield <= 0:
			currentHealth -= floor(max(0, damageVal))
		update_hp()
		if currentHealth <= 0:
			
			killedMove = moveName
			damageVal += currentHealth #Returns amount of damage actually dealt for recoil reasons
			if !isPlayer: 
				if real: ui.visible = false
				Battle.evaluate_completion(self)
			else:
				Battle.evaluate_game_over()
				if real: 
					for i in boxHolder.get_child_count():
						if i > 2 and boxHolder.get_child[i].currentUses > 0:
							boxHolder.get_child[i].reduce_uses(1)
		return damageVal

func heal(healVal):
	currentHealth = min(maxHealth, currentHealth + healVal)
	update_hp()

func update_hp(newMax = false):
	if newMax:
		ui.get_node("BattleElements/HPBar").max_value = maxHealth
	if ui != null:
		ui.get_node("BattleElements/HPBar").value = currentHealth
		ui.get_node("BattleElements/HPBar/Text").text = str(currentHealth, "/", maxHealth)
		ui.get_node("BattleElements/Shield").text = "[" + String(shield) + "]"
		if !isPlayer: ui.get_node("BattleElements/Shield").visible = true if shield > 0 else false

func update_strength(resetTemp = false):
	if resetTemp: tempStrength = 0
	if ui != null:
		if isPlayer:
			var strengthText = "+" + String(strength + tempStrength)
			if tempStrength > 0: strengthText += " (" + String(tempStrength) + ")"
			ui.get_node("BattleElements/Strength").text = strengthText

func update_info(text):
	if ui and ui.get_node_or_null("Info") != null:
		ui.get_node("Info").text = String(text)

func cease_to_exist():
	ui.queue_free()
	queue_free()

func update_status_ui():
	var statusHolder = ui.get_node_or_null("BattleElements/Statuses")
	if statusHolder != null:
		for child in statusHolder.get_children(): #temporary
			statusHolder.remove_child(child)
			child.queue_free()
		var i = 0
		for category in statuses:
			for status in category:
				var statusUI = UICircle.instance()
				statusHolder.add_child(statusUI)
				statusUI.get_node("Visuals").scale = Vector2(.5, .5)
				statusUI.position.x += 35 * i
				statusUI.set_letter(status["name"][0])
				if status.has("value"):
					statusUI.set_number(status["value"])
				statusUI.set_tooltip_text(status["tooltip"], true)
				statusUI.get_node("Visuals/Sprite").modulate = status["color"]
				i+=1

func setup_virtue():
	virtue = true
	battleName = "Virtue"
	maxHealth = 100
	currentHealth = 100
