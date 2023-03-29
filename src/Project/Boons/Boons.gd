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
		"Scales": {"virtue": v.j, "costs": [30, 50, 40], "hardCosts": [50, 75, 80]},
		"Crown": {"virtue": v.j, "costs": [30, 55, 45], "hardCosts": [50, 75, 80]},
		"Sword": {"virtue": v.j, "costs": [30, 40, 55], "hardCosts": [50, 75, 80]},
		"Blind": {"virtue": v.j, "costs": [30, 40, 45], "hardCosts": [50, 75, 80]},
		
		"Column": {"virtue": v.s, "costs": [30, 55, 35], "hardCosts": [50, 75, 80]},
		"Lion": {"virtue": v.s, "costs": [30, 40, 45], "hardCosts": [50, 75, 80]},
		"Infinite": {"virtue": v.s, "costs": [30, 40, 30], "hardCosts": [50, 75, 80]},
		"Weak": {"virtue": v.s, "costs": [30, 25, 55], "hardCosts": [50, 75, 80]},
		
		"Cup": {"virtue": v.t, "costs": [30, 60, 65], "hardCosts": [50, 75, 80]},
		"Wings": {"virtue": v.t, "costs": [30, 60, 45], "hardCosts": [50, 75, 80]},
		"Tides": {"virtue": v.t, "costs": [30, 40, 55], "hardCosts": [50, 75, 80]},
		"Mask": {"virtue": v.t, "costs": [30, 35, 40], "hardCosts": [50, 75, 80]},
	}

func create_boon(boonName):
	if !playerBoons.has(boonName): playerBoons.append(boonName)
	var babby = Node2D.new()
	add_child(babby)
	babby.name = boonName
	babby.set_script(load(PATH + boonName + ".gd"))
	babby.Boons = self

func call_boon(callName, args = [], signalBase = null): #callName is a string representing a function in the individual boon scripts
	var subFunc
	var checkVal
	var returnVal
	for boon in get_children():
		subFunc = funcref(boon, callName)
		if subFunc.is_valid(): checkVal = subFunc.call_funcv(args)
		if checkVal != null: returnVal = checkVal
	if signalBase: signalBase.boon_signal()
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
		"Scales": tip = "Scales \n Difficulty: ** \n Condition: Win battles without reusing a box. \n Effect: Generates a new box with rotating items for use in battle. \n Silver: Rotating items become stronger. \n Gold: Adds a third rotating item."
		"Crown": tip = "Crown \n Difficulty: * \n Condition: Kill enemies with the crown. \n Effect: You get the crown. It's very normal. Enjoy! \n Silver: The Crown hits all enemies that share an intent target. \n Gold: Obtain a second Crown."
		"Sword": tip = "Sword \n Difficulty: *** \n Condition: Use damaging gear when it has maximum durability. \n Effect: The activated gear deals more damage, as if you have 2 extra strength. \n Silver: Repairs always restore gear to maximum durability. \n Gold: Strength bonus lasts the rest of the battle."
		"Blind": tip = "Blind \n Difficulty: ***** \n Downside: Enemy intents and damage preview are disabled while active. \n Condition: Win battles without deactivating. \n Effect: +2 strength for the party on Turn 1 while active. \n Silver: Killing blows while active grant the user +8 shield. \n Gold: Strength bonus lasts beyond turn 1."
		
		"Column": tip = "Column \n Difficulty: ** \n Condition: Win battles in which less than half the party has less health from where they started. \n Effect: One turn of 5 shield to every party member. \n Silver: 5 shield to the party every turn. \n Gold: Party starts battle with 1 Resist."
		"Lion": tip = "Lion \n Difficulty: *** \n Condition: Kill enemies without using attacks. \n Effect: 1 turn of thorns to every party member. \n Silver: The thorns become permanent. \n Gold: Every party member becomes venomous."
		"Infinite": tip = "Infinite \n Difficulty: *** \n Condition: Break your gear. \n Effect: Regain a component used in the crafting recipe for the broken gear. \n Silver: Breaking gear grants the user 10 shield. \n Gold: Material given back is higher value instead of lower."
		"Weak": tip = "Weak \n Difficulty: ***** \n Downside: On battle start, the lowest health member is named VIP. Their health is set to 1 and they have a turn of Provoke. \n Condition: Win battles where the VIP survives. \n Effect: If the VIP survives, they are fully healed. \n Silver: Stealth instead of Provoke. Gold: Others gain 1 Dodge."
		
		"Cup": tip = "Cup \n Difficulty: ** \n Condition: Split kills as evenly as possible among party members. \n Effect: The first damaging move used in battle has an extra hit. \n Silver: Every party member's first damaging move has an extra hit. \n Gold: The first kill of the battle restores the extra hit ability."
		"Wings": tip = "Wings \n Difficulty: ***** \n Condition: Kill enemies with exact lethal. \n Effect: Killing with exact lethal using an attack restores a use to the weapon involved. \n Silver: Once per battle, missing exact lethal counts it anyway and deals the excess damage to the next enemy. \n Gold: Exact lethal grants the entire party shield equal to damage dealt."
		"Tides": tip = "Tides \n Difficulty: ** \n Condition: Deplete more uses of gear than you have total party members in a turn. \n Effect: Upon achieving the condition, units gain 1 Strength for using gear that turn. \n Silver: After activation, user gains shield equal to total uses depleted that turn. \n Gold: Activation becomes 1 use easier."
		"Mask": tip = "Mask \n Difficulty: ***** \n Downside: Enemies gain more health equal to the amount of times you've filled up the XP bar. \n Condition: Fill up the XP bar. \n Effect: None. \n Silver: Gain a +3 damage bonus when targeting an enemy with more current health than the move user's max health. \n Gold: Double XP granted for first kill of the battle."
	return tip

func set_text():
	if chosen == v.j: return "Justice"
	elif chosen == v.s: return "Strength"
	elif chosen == v.t: return "Temperance"
	else: return ""

func get_virtue_boons():
	var vBoons = []
	for boon in boonList:
		if boonList[boon]["virtue"] == chosen: vBoons.append(boon)
	return vBoons

func get_level(boonName):
	for boon in get_children():
		if boon.name == boonName:
			return boon.level
	return null

func grant_favor(amount):
	favor+=amount
	if Map: Map.update_favor(favor)
