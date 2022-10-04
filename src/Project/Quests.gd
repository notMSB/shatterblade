extends Node2D

onready var Moves = get_node("../Moves")
onready var Trading = get_node("../Trading")
onready var Enemies = get_node("../Enemies")
onready var Crafting = get_node("../Crafting")

const RARECOST = 5
const LABORMIN = 5
const LABORMAX = 21
const UNIQUETYPES = 2
const UNIQUEREWARDS = 1

enum t {fetch, labor, hunt, weapon_request, rescue, none} #type
enum r {relic, gear, rare_component, service} #reward
enum s {trade, craft} #service
var relics = []
var cheapComponents = []
var rareComponents = []

func _ready():
	randomize()
	Trading.assign_component_values()
	relics = Moves.get_relics()
	sort_components()
	#generate_quest()

func generate_quest():
	var newQuest = {}
	newQuest["type"] = rando_item(t, UNIQUETYPES)
	newQuest["reward"] = rando_item(r, UNIQUEREWARDS)
	var typeFunc = funcref(self, str("generate_", newQuest["type"])) #funcref usage cuts down on if statements now and in the future
	var rewardFunc = funcref(self, str("rando_", newQuest["reward"]))
	newQuest["objective"] = typeFunc.call_func()
	newQuest["prize"] = rewardFunc.call_func()
	return newQuest

func sort_components():
	for item in Trading.values:
		if Trading.values[item] >= RARECOST: rareComponents.append(item) 
		else: cheapComponents.append(item)

func generate_fetch():
	return rando_item(cheapComponents)

func generate_labor():
	return floor(rand_range(LABORMIN, LABORMAX))

func generate_hunt():
	var targets = []
	for enemy in Enemies.enemyList:
		if Enemies.enemyList[enemy]["locations"].has(Enemies.l.night): targets.append(enemy)
	return rando_item(targets)

func generate_weapon_request(): #random weapon of a certain class
	return Moves.moveType.keys()[Moves.random_moveType()]

func generate_rescue(): #todo: this
	pass

func rando_relic():
	return rando_item(relics)

func rando_gear(): #cheap components only
	return Crafting.sort_then_combine(Crafting.c.get(rando_item(cheapComponents)), Crafting.c.get(rando_item(cheapComponents)))

func rando_rare_component():
	return rando_item(rareComponents)

func rando_service():
	return rando_item(s)

func rando_item(input, modifier = 0): #modifier is for cutting items at the end of the list so they are not chosen
	if typeof(input) == TYPE_ARRAY:
		return input[randi() % (input.size() - modifier)]
	else: #enum
		var keys = input.keys()
		return keys[randi() % (keys.size() - modifier)]
