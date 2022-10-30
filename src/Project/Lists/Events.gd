extends Node2D

onready var Map = get_parent()
var eventList
enum timings {day, overworld, night, dungeon, special}

func _ready():
	print("events")
	eventList = {
	"Dungeon": {"time": timings.special, "description": "Enter dungeon?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "enter_dungeon")], [funcref(self, "advance")]]},
	"Town": {"time": timings.special, "description": "It's a town.",
		"choices": ["Trade", "Smith", "Inn", "Leave"],
		"conditions": [true, [funcref(self, "used_smith")], [funcref(self, "is_night")], true],
		"outcomes": [[funcref(self, "activate_shop")], [funcref(self, "activate_craft")], [funcref(self, "rest")], [funcref(self, "advance")]]},
	"Temple": {"time": timings.special, "description": "Enter temple?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "enter_temple")], [funcref(self, "advance")]]},
	"Store": {"time": timings.night, "description": "Enter store?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "activate_shop")], [funcref(self, "advance")]]},
	"Crafting": {"time": timings.day, "description": "Repair an item?",
		"choices": ["Yes", "No"],
		"outcomes": [[funcref(self, "activate_craft")], [funcref(self, "advance")]]},
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
	"Test5": {"time": timings.night, "description": "hello 5",
		"choices": ["Accept quest", "Reject quest"],
		"outcomes": [[funcref(self, "place_quest")], [funcref(self, "advance")]]}
}

func choose(index):
	var function
	var args = []
	var outcomes
	var eventName
	if Map.calledEvent:
		outcomes = eventList[Map.calledEvent]["outcomes"]
		eventName = Map.calledEvent
	else: #quest event contained in a point
		outcomes = Map.activePoint.pointQuest["outcomes"]
		eventName = Map.activePoint.pointQuest["type"]
		Map.calledEvent = eventName
	for i in outcomes[index].size(): #The first entry in an outcomes list is the function, followed by the arguments
		if typeof(outcomes[index][i]) == TYPE_OBJECT:
			if function: function.call_funcv(args)
			function = outcomes[index][i]
			args.clear()
		else:
			args.append(outcomes[index][i])
	if !function.call_funcv(args): #if the function returns a value, keep the event UI up
		Map.finish_event(eventName)

func generate_event(questData):
	var newEvent = {}
	newEvent["time"] = timings.special
	newEvent["description"] = str("This is a generated ", questData["type"], " event.")
	newEvent["choices"] = [String(questData["objective"]), "Do not"]
	newEvent["outcomes"] = []
	newEvent["outcomes"].append([funcref(self, "activate_quest"), questData["type"], questData["objective"]])
	newEvent["outcomes"].append([funcref(self, "advance")])
	newEvent["prize"] = questData["prize"]
	newEvent["reward"] = questData["reward"]
	newEvent["type"] = questData["type"]
	newEvent["objective"] = questData["objective"]
	return newEvent

func give_reward(openWindow = false, rewardExists = true):
	Map.activePoint.pointType = Map.pointTypes.visited
	if rewardExists:
		var questEvent = Map.activePoint.pointQuest
		if questEvent["reward"] == "service":
			if questEvent["prize"] == "trade": 
				Map.activePoint.set_type(Map.pointTypes.trader)
				Map.grab_event("Store")
			elif questEvent["prize"] == "repair": 
				Map.activePoint.set_type(Map.pointTypes.repair)
				Map.grab_event("Crafting")
		else:
			Map.inventoryWindow.add_item(questEvent["prize"], true, openWindow)

#Conditions
func has_class(className):
	for unit in global.storedParty:
		if unit.title == className:
			return true
	return false

func used_smith():
	if Map.activePoint.usedSmith:
		return false
	return true

func is_night():
	if Map.isDay:
		return false
	return true

#Outcomes

func activate_quest(questType, objective):
	var questFunc = funcref(self, str("quest_", questType))
	questFunc.call_func(objective)

func quest_fetch(neededComponment): #need for certain component
	Map.inventoryWindow.offerMode = Map.inventoryWindow.oModes.reward
	Map.inventoryWindow.offerType = Map.inventoryWindow.oTypes.component
	Map.inventoryWindow.offerNeed = neededComponment
	Map.activate_inventory(Map.inventoryWindow.iModes.offer)

func quest_labor(time): #task that takes X time
	adjust_time(time * -1)
	give_reward()

func quest_hunt(target): #battle with rare enemy
	give_reward(false, false) #reward can be given in advance since battles are currently inescapable
	Map.activate_battle([target]) #the reward is the component from the target

func quest_weapon_request(weaponType): #random weapon of a certain class
	Map.inventoryWindow.offerMode = Map.inventoryWindow.oModes.reward
	Map.inventoryWindow.offerType = Map.inventoryWindow.oTypes.weapon
	Map.inventoryWindow.offerNeed = weaponType
	Map.activate_inventory(Map.inventoryWindow.iModes.offer)

func adjust_time(value):
	Map.subtract_time(value * -1)
	
func damage_player(unitIndex, value):
	global.storedParty[unitIndex].take_damage(value)

func place_quest():
	var validPoints = []
	var currentDistance = Map.activePoint.clicksFromStart
	for point in Map.get_node("HolderHolder/PointHolder").get_children(): #Quests go on event points that are in the same section
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

func enter_temple():
	var index = Map.activePoint.info["templeIndex"]
	var temples = Map.get_node("HolderHolder/TempleHolder")
	temples.get_child(index).enter()

func activate_craft():
	Map.inventoryWindow.offerMode = Map.inventoryWindow.oModes.repair
	Map.inventoryWindow.offerType = Map.inventoryWindow.oTypes.any
	Map.activate_inventory(Map.inventoryWindow.iModes.offer)

func activate_shop():
	Map.inventoryWindow.shuffle_trade_stock()
	Map.activate_inventory(Map.inventoryWindow.iModes.trade)
	return true

func rest():
	if !Map.isDay:
		Map.subtract_time(Map.NIGHTLENGTH, true)
		for unit in global.storedParty:
			unit.currentHealth = unit.maxHealth
			unit.update_hp()
	else:
		pass

func advance():
	pass
