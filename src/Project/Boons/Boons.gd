extends Node2D

enum v {j, s, t, none}
const DEFAULTREWARD = 5

const PATH = "res://src/Project/Boons/"

var Map #when the map loads in it sets itself to this

var boonList
var playerBoons = []
var chosen = v.none
var favor = 0

#At some point every boon will be its own node/script with functions activated from this one

func _ready():
	for boon in playerBoons:
		create_boon(boon)
	
	boonList = {
		"Scales": {"virtue": v.j, "costs": [30, 50], "hardCosts": [50, 75]},
		"Crown": {"virtue": v.j, "costs": [30, 50], "hardCosts": [50, 75]},
		
		"Column": {"virtue": v.s, "costs": [30, 50], "hardCosts": [50, 75]},
		"Lion": {"virtue": v.s, "costs": [30, 50], "hardCosts": [50, 75]},
		
		"Cup": {"virtue": v.t, "costs": [30, 50], "hardCosts": [50, 75]},
		"Wings": {"virtue": v.t, "costs": [30, 50], "hardCosts": [50, 75]},
	}

func create_boon(boonName):
	if !playerBoons.has(boonName): playerBoons.append(boonName)
	var babby = Node2D.new()
	add_child(babby)
	babby.name = boonName
	babby.set_script(load(PATH + v.keys()[chosen] + "/" + boonName + ".gd"))
	babby.Boons = self

func call_boon(callName, args = []): #callName is a string representing a function in the individual boon scripts
	var subFunc
	var checkVal
	var returnVal
	for boon in get_children():
		subFunc = funcref(boon, callName)
		if subFunc.is_valid(): checkVal = subFunc.call_funcv(args)
		if checkVal != null: returnVal = checkVal
	return returnVal if returnVal else 0

func call_specific(callName, args = [], boonName = ""): #todo: reconcile this and above function
	var subFunc
	var checkVal
	var returnVal
	for boon in get_children():
		if boon.name == boonName:
			subFunc = funcref(boon, callName)
			if subFunc.is_valid(): checkVal = subFunc.call_funcv(args)
			if checkVal != null: returnVal = checkVal
			break
	return returnVal if returnVal else 0

func generate_tooltip(boonName):
	var tip = ""
	match boonName:
		"Scales": tip = "Difficulty: ** \n Condition: Win battles without reusing a box. \n Effect: Generates a new box with rotating items for use in battle. \n Upgrade: Rotating items become stronger."
		"Crown": tip = "Difficulty: * \n Condition: Kill enemies with the crown. \n Effect: You get the crown. It's very normal. Enjoy! \n Upgrade: The Crown hits all enemies."
		"Column": tip = "Difficulty: *** \n Condition: Win battles in which less than half the party has less health from where they started. \n Effect: One turn of 5 shield to every party member. \n Upgrade: 5 shield to the party every turn."
		"Lion": tip = "Difficulty: *** \n Condition: Kill enemies without using attacks. \n Effect: 1 turn of thorns to every party member. \n Upgrade: The thorns become permanent."
		"Cup": tip = "Difficulty: ** \n Condition: Split kills as evenly as possible among party members. \n Effect: The first damaging move used in battle has an extra hit. \n Upgrade: Every party member's first damaging move has an extra hit."
		"Wings": tip = "Difficulty: ***** \n Condition: Kill enemies with exact lethal. \n Effect: Killing with exact lethal using an attack restores a use to the weapon involved. \n Upgrade: Once per battle, missing exact lethal counts it anyway and deals the excess damage to the next enemy."
	return tip

func set_text():
	var vText = ""
	if chosen == v.j: vText += "Justice"
	elif chosen == v.s: vText += "Strength"
	elif chosen == v.t: vText += "Temperance"
	vText += "\n"
	for boon in playerBoons:
		vText += boon + " [" + String(get_level(boon)) + "]" + "\n"
	return vText

func get_virtue_boons():
	var vBoons = []
	for boon in boonList:
		if boonList[boon]["virtue"] == chosen: vBoons.append(boon)
	return vBoons

func get_level(boonName):
	for boon in get_children():
		if boon.name == boonName:
			return boon.level
	return -1 #0 is used for base level, so -1 means it isn't in possession

func grant_favor(amount):
	favor+=amount
	if Map: Map.update_favor(favor)
