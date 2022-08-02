extends Node2D

onready var Map = get_parent()
var eventList
enum timings {day, overworld, night, dungeon, special}

func _ready():
	eventList = {
	"Dungeon": {"time": timings.special, "description": "Enter dungeon?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "enter_dungeon")], [funcref(self, "advance")]]},
	"Store": {"time": timings.special, "description": "Enter store?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "activate_shop")], [funcref(self, "advance")]]},	
	"Test": {"time": timings.night, "description": "hello 1",
		"choices": ["-4", "+4"],
		"outcomes": [[funcref(self, "adjust_time"), -4], [funcref(self, "adjust_time"), 4]]},
	"Test2": {"time": timings.night, "description": "hello 2",
		"choices": ["P1 -5", "P2 -5", "0 damage"],
		"conditions": [true, true, [funcref(self, "has_class"), "Fighter"]],
		"outcomes": [[funcref(self, "damage_player"), 0, 5], [funcref(self, "damage_player"), 1, 5], [funcref(self, "advance")]]},
	"Test3": {"time": timings.night, "description": "hello 3",
		"choices": ["-12", "+12"],
		"outcomes": [[funcref(self, "adjust_time"), -12], [funcref(self, "adjust_time"), 12]]},
	"Test4": {"time": timings.night, "description": "hello 4",
		"choices": ["Gain 5 time but P0 takes 5 damage", "Lose 5 time"],
		"outcomes": [[funcref(self, "adjust_time"), 5, funcref(self, "damage_player"), 0, 5], [funcref(self, "adjust_time"), -5]]},
	"Test5": {"time": timings.day, "description": "hello 5",
		"choices": ["Accept quest", "Reject quest"],
		"outcomes": [[funcref(self, "place_quest")], [funcref(self, "advance")]]}
}

func choose(index):
	var function
	var args = []
	var outcomes = eventList[Map.calledEvent]["outcomes"]
	for i in outcomes[index].size():
		if typeof(outcomes[index][i]) == TYPE_OBJECT:
			if function: function.call_funcv(args)
			function = outcomes[index][i]
			args.clear()
		else:
			args.append(outcomes[index][i])
	function.call_funcv(args)
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

func place_quest():
	var validPoints = []
	var currentDistance = Map.activePoint.clicksFromStart
	for point in Map.get_node("HolderHolder/PointHolder").get_children(): #Quests go on event points that 
		if point.visible and point.clicksFromStart > currentDistance and point.pointType == Map.pointTypes.event:
			validPoints.append(point)
	if validPoints.empty():
		print("no points")
	else:
		var chosenPoint = validPoints[randi() % validPoints.size()]
		chosenPoint.pointType = Map.pointTypes.quest
		Map.set_label(chosenPoint, "Quest", true)

func enter_dungeon():
	var index = Map.activePoint.info["dungeonIndex"]
	var dungeons = Map.get_node("HolderHolder/DungeonHolder")
	Map.savedPoint = Map.activePoint
	dungeons.get_child(index).enter()
	Map.currentDungeon = dungeons.get_child(index)

func activate_shop():
	pass

func advance():
	pass
