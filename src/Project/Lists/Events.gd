extends Node2D

onready var Map = get_parent()
var eventList
enum timings {day, overworld, night, dungeon}

func _ready():
	eventList = {
	"Test": {"time": timings.overworld, "description": "hello 1",
		"choices": ["-4", "+4"],
		"outcomes": [funcref(self, "adjust_time")],
		"args": [[-4], [4]]},
	"Test2": {"time": timings.day, "description": "hello 2",
		"choices": ["-8", "+8"],
		"outcomes": [funcref(self, "adjust_time")],
		"args": [[-8], [8]]},
	"Test3": {"time": timings.night, "description": "hello 3",
		"choices": ["-12", "+12"],
		"outcomes": [funcref(self, "adjust_time")],
		"args": [[-12], [12]]
	}
	
}

#Outcomes

func adjust_time(value):
	Map.subtract_time(value * -1)
