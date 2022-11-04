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
