extends Node2D

onready var Map = get_parent()
var eventList
enum timings {day, overworld, night, dungeon}

func _ready():
	eventList = {
	"Test": {"time": timings.night, "description": "hello 1",
		"choices": ["-4", "+4"],
		"outcome": funcref(self, "adjust_time"),
		"args": [[-4], [4]]},
	"Test2": {"time": timings.day, "description": "hello 2",
		"choices": ["P1 -5", "P2 -5", "0 damage"],
		"conditions": [true, true, [funcref(self, "has_class"), "Fighter"]],
		"outcome": funcref(self, "damage_player"),
		"args": [[0, 5], [1, 5], [0, 0]]},
	"Test3": {"time": timings.night, "description": "hello 3",
		"choices": ["-12", "+12"],
		"outcome": funcref(self, "adjust_time"),
		"args": [[-12], [12]]},
	"Test4": {"time": timings.night, "description": "hello 3",
		"choices": ["Gain 5 time but P0 takes 5 damage", "Lose 5 time"],
		"outcomes": [[funcref(self, "adjust_time"), funcref(self, "damage_player")], [funcref(self, "adjust_time")]],
		"args": [[[5],[0,5]], [[-5]]]
		
	
	}
	
}

func choose(index):
	var args = eventList[Map.calledEvent]["args"][index]
	if eventList[Map.calledEvent].has("outcome"): #just one function involved
		eventList[Map.calledEvent]["outcome"].call_funcv(args)
	else: #3D arrays have arrived
		var outcomes = eventList[Map.calledEvent]["outcomes"]
		for i in outcomes[index].size():
			outcomes[index][i].call_funcv(args[i])
	Map.finish_event()

#Conditions

func has_class(className):
	for unit in global.storedParty:
		if unit.title == className:
			return true
	return false

#Outcomes

func adjust_time(value):
	Map.subtract_time(value * -1)
	
func damage_player(unitIndex, value):
	global.storedParty[unitIndex].take_damage(value)
