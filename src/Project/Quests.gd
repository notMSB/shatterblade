extends Node2D

onready var Moves = get_node("../Moves")
#onready var Trading = get_node("../Trading")

enum t {fetch, labor, hunt, rescue} #type
enum r {relic, gear, component, service} #reward
var relics = []
var cheapComponents = []
var rareComponents = []


func _ready():
	randomize()
	relics = Moves.get_relics()
	generate_quest()

func generate_quest():
	print(rando_item(t))
	
func rando_item(input):
	var keys = input.keys()
	return keys[randi() % keys.size()]
