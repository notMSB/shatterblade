extends Node2D

enum v {none, j, s, t}
const DEFAULTREWARD = 5

const PATH = "res://src/Project/Boons/"

var Map #when the map loads in it sets itself to this

var playerBoons = ["Lion"]
var chosen = v.s
var favor = 0

#At some point every boon will be its own node/script with functions activated from this one

func _ready():
	var babby 
	for boon in playerBoons:
		babby = Node2D.new()
		add_child(babby)
		babby.name = boon
		babby.set_script(load(PATH + v.keys()[chosen] + "/" + boon + ".gd"))
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

func grant_favor(amount):
	favor+=amount
	if Map: Map.update_favor(favor)
