extends Node2D

export (PackedScene) var Point
export (PackedScene) var Line
export (PackedScene) var Time
export (PackedScene) var Favor
export (PackedScene) var Battle
export (PackedScene) var Inventory
export (PackedScene) var ChoiceUI
export (PackedScene) var Dungeon
export (PackedScene) var Temple
export (PackedScene) var Section
export (PackedScene) var QuickCraft
export (PackedScene) var QuickRepair

onready var Moves = get_node("../Data/Moves")
onready var Quests = get_node("../Data/Quests")
onready var Enemies = get_node("../Data/Enemies")
onready var Boons = get_node("../Data/Boons")
onready var Trading = get_node("../Data/Trading")

const INCREMENT = 90
const KILLDISTANCE = 81 #lower kill distance means more points
const MAXDISTANCE = 199
const FUZZ = 35 #should never be more than half of the increment
const CORNER_CHECK = 20
const DISTANCE_TIME_MULT = .05

const LEFTBOUND = 280
const MIDPOINT = 640
const RIGHTBOUND = 960

const NIGHTLENGTH = 50
const TOTALSECTIONS = 2
const BASEXP = 5
const XPINCREMENT = 5

var bottomRight
var columnNum

var startIndex
var endIndex

var activePoint
var savedPoint

var calledEvent
var timeNode
var favorNode

const DIFFICULTYMODIFIER = -4
const DUNGEONDIFFICULTY = [2, 3, 3, 4]
const DAYTIME = 150
var distanceTraveled = 0
var time = DAYTIME
var currentDay = 0
var currentArea = 0
const AREADIFFICULTYMOD = 3
const DAYDIFFICULTYMOD = 1
var isDay = true
var currentDungeon = null
var currentTemple = null
var biomesList
var availableBiomes = []
var currentBiome
var seenElite = false

var selectedMapMove = null
var selectedMapBox = null

var delayBattle = null

var battleWindow
var inventoryWindow
enum pointTypes {none, start, battle, quest, visited, event, town, dungeon, repair, trader, temple, end} #Points to the left of "visited" turn off after being activated

var canEnd = false
var checkedLines = []
var nextCheck = []
var regens = 0
const REGENLIMIT = 100

func _ready():
	randomize()
	timeNode = Time.instance()
	add_child(timeNode)
	favorNode = Favor.instance()
	add_child(favorNode)
	Boons.Map = self
	
	biomesList = Enemies.b
	availableBiomes = range(0, biomesList.size()-1) #exclude the "none" at the end
	set_biome()
	Trading.assign_component_values(currentBiome, "Scorpion") #todo: change this when new mascots are added
	setup_inventory()
	
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < inventoryWindow.MOVESPACES:
				global.storedParty[i].moves.append("X")
			global.storedParty[i].ui = $HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
			global.storedParty[i].update_hp()
		for display in $HolderHolder/DisplayHolder.get_children():
			set_display_color(display)
	bottomRight = Vector2($ReferenceRect.margin_right, $ReferenceRect.margin_bottom)
	timeNode.position.y += bottomRight.y
	favorNode.position.y += bottomRight.y + 5
	favorNode.position.x += bottomRight.x - 150
	set_boon_text()
	columnNum = int(ceil(bottomRight.x/INCREMENT) - 1) #ceil-1 instead of floor prevents strangeness with exact divisions
	#print(columnNum)
	make_points(Vector2(INCREMENT,INCREMENT*.5))
	setup_battle()
	$XPBar.max_value = BASEXP
	battleWindow.setup_party()
	for display in $HolderHolder/DisplayHolder.get_children():
		display.set_battle()
		for tracker in display.get_node("Trackers").get_children():
			tracker.visible = true
	for unit in global.storedParty:
		battleWindow.set_ui(unit)
		for box in unit.boxHolder.get_children():
			inventoryWindow.identify_product(box)
	get_parent().move_child(battleWindow, inventoryWindow.get_index())
	#get_parent().move_child(self, inventoryWindow.get_index())
	var Party = get_parent().get_node_or_null("Party")
	if Party: get_parent().move_child(Party, get_index())
	
	set_time_text()
	set_quick_panels()

func set_quick_panels():
	set_quick_crafts()
	set_quick_repairs()

func set_biome():
	currentBiome = availableBiomes[randi() % availableBiomes.size()]
	availableBiomes.erase(currentBiome)
	match currentBiome:
		biomesList.plains: $Background.color = Color("00005f") #Blue
		biomesList.forest: $Background.color = Color("005c00") #Green
		biomesList.mountain: $Background.color = Color("923b3b") #Red
		biomesList.city: $Background.color = Color("6f7300") #Yellow
		biomesList.battlefield: $Background.color = Color("923e00") #Orange
		biomesList.graveyard: $Background.color = Color("4e004e") #Purple

func set_boon_text():
	favorNode.get_node("Virtue").text = Boons.set_text()

func setup_inventory():
	inventoryWindow = Inventory.instance()
	get_parent().add_child(inventoryWindow)

func setup_battle():
	battleWindow = get_parent().get_node("Battle")
	battleWindow.visible = false

func activate_inventory():
	inventoryWindow.welcome_back()

func set_display_color(display):
	var unitType = global.storedParty[display.get_index()].allowedType
	if unitType == Moves.moveType.special: display.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
	elif unitType == Moves.moveType.magic: display.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
	elif unitType == Moves.moveType.trick: display.get_node("ColorRect").color = Color(.3,.7,.3,1) #G

func activate_point(point):
	var type = point.pointType
	if type == pointTypes.none:
		pass
	elif type == pointTypes.start:
		print("Start")
	elif type == pointTypes.end: #todo: event asking if you want to end (and eventually a boss here)
		#print("End")
		regen_map(true)
	elif type == pointTypes.dungeon:
		grab_event("Dungeon")
	elif type == pointTypes.town:
		var townValue = 0 if isDay else 1 #towns should close on their night
		townValue += currentDay
		if townValue <= point.sectionNum: grab_event("Town")
		else: pass #todo: event saying town is closed
	elif type == pointTypes.trader:
		grab_event("Store")
	elif type == pointTypes.repair:
		grab_event("Crafting")
	elif type == pointTypes.temple:
		grab_event("Temple")
	elif type == pointTypes.battle or !isDay or point.sectionNum > currentDay: #no events at night
		activate_battle()
	elif type == pointTypes.event:
		if point.pointQuest:
			$Events/EventDescription.text = str(point.pointQuest["description"], "\nfor\n", point.pointQuest["prize"])
			run_event(point.pointQuest)
		else:
			var list = $Events.eventList
			var pool = []
			if isDay:
				for option in list: #day has a lesser value than overworld in the enum
					if list[option]["time"] <= $Events.timings.overworld: pool.append(option)
			else:
				for option in list: #night has a greater value than overworld
					if list[option]["time"] >= $Events.timings.overworld: pool.append(option)
			grab_event(pool[randi() % pool.size()])

func check_delay():
	if delayBattle:
		var temp = delayBattle
		delayBattle = null
		activate_battle(temp)

func activate_battle(newOpponents = null):
	
	#if inventoryWindow.visible:
		#delayBattle = newOpponents
	if currentDungeon:
		var dungeonRando = DUNGEONDIFFICULTY[randi() % DUNGEONDIFFICULTY.size()]
		newOpponents = Enemies.generate_encounter(dungeonRando + get_difficulty_mod(), false, currentBiome, currentDungeon.mascot)
	elif !newOpponents and distanceTraveled > 1:
		var dayEncounter = isDay
		if isDay and activePoint.sectionNum > currentDay: dayEncounter = false #if it's day but you're out of bounds it counts as night
		newOpponents = Enemies.generate_encounter(distanceTraveled + DIFFICULTYMODIFIER + get_difficulty_mod(), dayEncounter, currentBiome, null, seenElite)
	battleWindow.visible = true
	check_for_elite(newOpponents)
	battleWindow.welcome_back(newOpponents, currentArea)

func check_for_elite(opponents):
	for enemy in opponents:
		if Enemies.enemyList[enemy].has("elite"):
			seenElite = true
			return

func get_difficulty_mod():
	var nightMod = 0 if isDay else 1
	return DAYDIFFICULTYMOD * currentDay + AREADIFFICULTYMOD * currentArea + nightMod

func grab_event(eventName): #used for premade events, generated events have their own system
	calledEvent = eventName
	$Events/EventDescription.text = $Events.eventList[eventName]["description"]
	run_event($Events.eventList[eventName])

func run_event(event):
	var yIncrement = $Events/EventDescription.rect_size.y
	var choice
	var cond
	var function
	$Events.visible = true
	for option in $Events/Choices.get_children():
			option.queue_free()
	for i in event["choices"].size():
		var canClick = true
		choice = ChoiceUI.instance()
		$Events/Choices.add_child(choice)
		choice.position.y = yIncrement
		yIncrement += choice.get_node("Button").rect_size.y
		choice.get_node("Info").text = event["choices"][i]
		
		if event.has("conditions"):
			if typeof(event["conditions"][i]) == TYPE_ARRAY: #assess the condition
				cond = event["conditions"][i]
				function = event["conditions"][i][0] #first element is the function, rest is the args
				if !function.call_funcv(cond.slice(1, cond.size()-1)): canClick = false #skip using it as an option if the condition is false
			else:
				canClick = event["conditions"][i]
				if !canClick: #offering condition
					if event.has("type"):
						if event["type"] == "fetch":
							inventoryWindow.offerType = inventoryWindow.oTypes.component
						else: #weapon request
							inventoryWindow.offerType = inventoryWindow.oTypes.weapon
						inventoryWindow.offerNeed = event["objective"]
					else: #repair
						inventoryWindow.offerType = inventoryWindow.oTypes.any
					choice.get_node("Offerbox").visible = true
		if !canClick: choice.get_node("Button").visible = false

func repair_event_box():
	var repairName = $Events/Choices.get_child(0).get_node("Offerbox/Name").text
	if repairName != "X":
		inventoryWindow.add_to_player(repairName)
		if activePoint.pointType != pointTypes.town: activePoint.mark_as_visited()

func return_event_box():
	var eBox = $Events/Choices.get_child(0).get_node("Offerbox")
	if eBox.get_node("Name").text != "X":
		inventoryWindow.swap_boxes(eBox, inventoryWindow.xCheck())

func finish_event(checkName):
	if calledEvent == checkName:
		for option in $Events/Choices.get_children():
			option.queue_free()
		$Events.visible = false
		calledEvent = null #clearing this out is needed because it's checked to process event outcomes

func toggle_map_use(box):
	if !(box.get_parent().name != "MoveBoxes" and box.resValue > 0 or inventoryWindow.tHolder.visible): #for moves that need to be equipped to be used, or when the trader is active
		selectedMapBox = box
		selectedMapMove = box.moves[box.moveIndex]
		for child in get_node("HolderHolder/DisplayHolder").get_children():
			child.get_node("Button").visible = true

func use_map_move(unit):
	var moveUser = null
	if selectedMapBox.get_parent().name == "MoveBoxes": moveUser = global.storedParty[selectedMapBox.get_parent().get_parent().get_index()]
	if moveUser == null or moveUser.mana >= Moves.moveList[selectedMapMove]["resVal"]:
		if Moves.moveList[selectedMapMove].has("healing"):
			unit.heal(Moves.moveList[selectedMapMove]["healing"])
		if Moves.moveList[selectedMapMove].has("statBoost"):
			unit.boost_stat(Moves.moveList[selectedMapMove]["statBoost"])
		selectedMapBox.reduce_uses(1)
		if selectedMapBox.currentUses == 0: #it's broken
			$HolderHolder/DisplayHolder.box_move(selectedMapBox, "X", true)
		if moveUser != null: moveUser.update_resource(Moves.moveList[selectedMapMove]["resVal"], Moves.moveType.magic, false)
	end_map_move()

func end_map_move():
	inventoryWindow.deselect_multi([selectedMapBox])
	for child in $HolderHolder/DisplayHolder.get_children():
		child.get_node("Button").visible = false
	selectedMapMove = null
	selectedMapBox = null

func make_points(nextPos):
	var currentPoint = Point.instance()
	$HolderHolder/PointHolder.add_child(currentPoint)
	currentPoint.position = nextPos
	fuzz_point(currentPoint)

	#print(str("-----POINT ", currentPoint.get_index(), "-----"))
	determine_neighbors(currentPoint)
	
	nextPos.x += INCREMENT
	if nextPos.x >= bottomRight.x:
		nextPos.y += INCREMENT
		if nextPos.y >= bottomRight.y: #done, clean up leftovers and set start/end points
			organize_lines()
			startIndex.set_type(pointTypes.start)
			activePoint = startIndex
			startIndex.toggle_activation(true)
			startIndex.set_name("Start")
			determine_distances(startIndex)
			move_map(LEFTBOUND)
			return clean_up()
		nextPos.x = INCREMENT
	make_points(nextPos)

func find_border_points():
	var checkSection
	var adjacentPoint
	var possibleDungeons = [] #2D array of lines
	var exitPoints = []
	for i in TOTALSECTIONS - 1:
		possibleDungeons.append([])
		exitPoints.append([])
	for point in $HolderHolder/PointHolder.get_children():
		if point.visible and point.clicksFromStart and point.sectionNum != TOTALSECTIONS - 1: #no reason to check points in the last section
			checkSection = point.sectionNum
			for line in point.lines:
				adjacentPoint = line.get_connection(point)
				if adjacentPoint.sectionNum > checkSection:
					possibleDungeons[checkSection].append(line)
					exitPoints[checkSection].append(adjacentPoint)
	place_dungeons(possibleDungeons, exitPoints)

func place_dungeons(possibleDungeons, borderPoints): #dungeons start in one section and end in the next
	var dungeonLine
	var entrySection
	for border in possibleDungeons:
		if border.empty(): 
			regen_map()
			return print("dungeon shortage")
		var newDungeon = Dungeon.instance()
		$HolderHolder/DungeonHolder.add_child(newDungeon)
		dungeonLine = border[randi() % border.size()]
		entrySection = min(dungeonLine.linePoints[0].sectionNum, dungeonLine.linePoints[1].sectionNum)
		for point in dungeonLine.linePoints: #border[rando] is a line
			point.set_type(pointTypes.dungeon)
			point.info["dungeonIndex"] = entrySection
			point.info["direction"] = point.sectionNum - entrySection #0 for entry 1 for exit
			if entrySection == point.sectionNum: 
				newDungeon.originLocation = point
				point.set_name("Entry")
			else: 
				newDungeon.exitLocation = point
				point.set_name("Exit")
		dungeonLine.dungeonize()
		newDungeon.setup(dungeonLine)
		place_town(newDungeon.exitLocation, borderPoints[entrySection])
	classify_remaining_points()

func place_temple(point):
	var newTemple = Temple.instance()
	#point.set_name("Temple")
	$HolderHolder/TempleHolder.add_child(newTemple)
	newTemple.setup()
	point.set_type(pointTypes.temple)
	point.info["templeIndex"] = point.sectionNum - 1

func place_town(exitPoint, borderPoints): #towns are adjacent to dungeon exits and in the same section, if possible they are also on the border. ties broken by closeness to center
	var checkPoint
	var bestSpot
	var bestDistance = bottomRight.y/2
	var townSpots = []
	var backupSpots = []
	for line in exitPoint.lines:
		checkPoint = line.get_connection(exitPoint)
		if borderPoints.has(checkPoint): townSpots.append(checkPoint)
		elif checkPoint.sectionNum == exitPoint.sectionNum: backupSpots.append(checkPoint)
	if townSpots.empty(): 
		if backupSpots.empty(): 
			regen_map()
			return print("no spots for town")
		#print("backup spots")
		townSpots = backupSpots
	for i in townSpots.size():
		if abs(townSpots[i].position.y - bottomRight.y/2) < bestDistance:
			bestSpot = townSpots[i]
			#print("swapping town to more central spot")
	bestSpot.set_name("Town")
	bestSpot.set_type(pointTypes.town)
	#print(bottomRight.y/2)

func clean_up():
	var divider = bottomRight.x / TOTALSECTIONS
	add_sections(divider)
	for point in $HolderHolder/PointHolder.get_children():
		point.sectionNum = floor(point.position.x / divider)
		point.set_name(str(point.sectionNum, " | ", point.clicksFromStart))
		if point.clicksFromStart == null and point.visible: 
			print("hiding null point")
			point.visible = false
	set_label(endIndex, "End", true)
	endIndex.set_type(pointTypes.end)
	if !canEnd: 
		print("disaster")
		regen_map()
	else: 
		find_border_points()
		#categorize_points()

func regen_map(newMember = false):
	print("---------------- New Map ----------------")
	if newMember:
		currentArea += 1
		if global.storedParty.size() < 4:
			var Party = get_parent().get_node_or_null("Party")
			if Party:
				Party.visible = true
				Party.area_break()
		else:
			return get_tree().change_scene("res://src/Project/Win.tscn")
			#you win !
	startIndex = null
	endIndex = null
	canEnd = false
	for holder in $HolderHolder.get_children():
		if holder != $HolderHolder/DisplayHolder: #this one can stay
			for child in holder.get_children():
				holder.remove_child(child)
				child.queue_free()
	regens += 1
	if regens < REGENLIMIT: 
		make_points(Vector2(INCREMENT,INCREMENT*.5))
		advance_day(true)
		time = DAYTIME
		seenElite = false
		set_biome()
		set_time_text()
		for unit in global.storedParty:
			unit.currentHealth = unit.maxHealth
			unit.update_hp()
	else: print("Bad map gen settings")

func add_new_member():
	var unit = global.storedParty[-1]
	unit.Battle = battleWindow
	unit._ready()
	while unit.moves.size() < inventoryWindow.MOVESPACES:
		unit.moves.append("X")
	unit.ui = $HolderHolder/DisplayHolder.setup_player(unit, global.storedParty.size()-1)
	unit.update_hp()
	unit.ui.get_node("Name").text = unit.displayName
	set_display_color(unit.ui)
	battleWindow.partyNum += 1
	battleWindow.setup_player(global.storedParty.size()-1, true)
	unit.ui.set_battle()
	battleWindow.set_ui(unit)
	for box in unit.boxHolder.get_children():
		inventoryWindow.identify_product(box)
	#for tracker in unit.ui.get_node("Trackers").get_children():
	#	tracker.visible = false
	Boons.call_boon("new_member", [inventoryWindow])

func add_sections(divider):
	var newSection
	var sectionBG
	var addedSections = []
	for i in TOTALSECTIONS:
		newSection = Section.instance()
		$HolderHolder/SectionHolder.add_child(newSection)
		addedSections.append(newSection)
		sectionBG = newSection.get_node("BG")
		sectionBG.margin_left = i * divider
		sectionBG.margin_right = sectionBG.margin_left + divider
	set_sections(addedSections)

func set_sections(addedSections = null):
	var sHolder = $HolderHolder/SectionHolder
	if addedSections:
		for i in addedSections.size():
			addedSections[i].visible = false if currentDay == i else true
	else:
		for i in TOTALSECTIONS:
			sHolder.get_child(i).visible = false if currentDay == i else true

func set_label(point, label, distance = false):
	if distance: point.set_name(str(label, " ", point.clicksFromStart))
	else: point.set_name(label)

func organize_lines():
	for point in $HolderHolder/PointHolder.get_children():
		if point.lines.empty() and point.visible: point.visible = false #remove orphaned points
		if !point.visible: #kill lines involving invisible points
			for line in point.lines:
				line.free()
		else: #set start and end index among visible points
			if !startIndex: startIndex = point
			elif point.position.x < startIndex.position.x: startIndex = point
			if !endIndex: endIndex = point
			elif point.position.x >= endIndex.position.x: endIndex = point

func classify_remaining_points():
	Quests.setup(currentBiome)
	var remainingPoints = []
	for point in $HolderHolder/PointHolder.get_children():
		if point.visible and point.pointType == pointTypes.none:
			remainingPoints.append(point)
		
	for i in TOTALSECTIONS:
		Quests.servicesMade = 0
		var sectionPoints = []
		for point in remainingPoints:
			if point.sectionNum == i:
				sectionPoints.append(point)
		if sectionPoints.empty(): 
			regen_map() #needs to be a really messed up mapgen for this, but if it happens it crashes
			print("no points for quests")
			return
		if i > 0:
			var randoPoint = sectionPoints[randi() % sectionPoints.size()]
			place_temple(randoPoint)
			sectionPoints.erase(randoPoint)
		var battleCount = ceil(sectionPoints.size() * .5)
		while battleCount > 0:
			var randoPoint = sectionPoints[randi() % sectionPoints.size()]
			randoPoint.pointType = pointTypes.battle
			sectionPoints.erase(randoPoint)
			battleCount -= 1
		sectionPoints.shuffle() #first 2 in the list get to be service rewards, so list needs to be randomized
		for eventPoint in sectionPoints:
			eventPoint.pointType = pointTypes.event
			make_quest(eventPoint)
	set_point_displays()

func set_point_displays():
	for point in $HolderHolder/PointHolder.get_children():
		if point.pointType == pointTypes.dungeon: point.set_type_text("D")
		elif point.pointType == pointTypes.end: point.set_type_text("E")
		elif point.pointType == pointTypes.start: point.set_type_text("S")
		elif point.pointType == pointTypes.town: point.set_type_text("T")
		elif point.sectionNum == currentDay:
			if point.pointType > pointTypes.event:
				point.set_type_text(pointTypes.keys()[point.pointType][0].to_upper())
			elif point.pointQuest:
				if point.pointQuest["prize"] == "trade": point.set_name("Trader")
				elif point.pointQuest["prize"] == "repair": point.set_name("Repair")
				var sprite = point.get_node("Image")
				var spritePath
				if point.pointQuest["type"] == "fetch": 
					spritePath = str("res://src/Assets/Icons/Components/", point.pointQuest["objective"], ".png")
					sprite.set_scale(Vector2(.5,.5))
				else:
					sprite.set_scale(Vector2(.25,.25))
					if point.pointQuest["type"] == "labor": spritePath = "res://src/Assets/Misc/labor.png"
					if point.pointQuest["type"] == "weapon_request": spritePath = str("res://src/Assets/Misc/", point.pointQuest["objective"], ".png")
					if point.pointQuest["type"] == "hunt": spritePath = str("res://src/Assets/Enemies/", Enemies.enemyList[point.pointQuest["objective"]]["sprite"], ".png")
				
				point.get_node("Button").flat = true
				sprite.texture = load(spritePath)
				sprite.visible = true
				
		else:
			point.set_type_text("")
			point.get_node("Button").flat = false
			point.get_node("Image").visible = false

func make_quest(point):
	point.pointQuest = $Events.generate_event(Quests.generate_quest())

func determine_distances(checkPoint): #gives every node a distance from start and returns if the end node is accessible
	if checkPoint == startIndex: checkPoint.clicksFromStart = 0
	var connectedPoint
	#print(str("Evaluating Point at: ", checkPoint.clicksFromStart))
	var killLines = []
	for line in checkPoint.lines:
		if is_instance_valid(line):
			connectedPoint = line.get_connection(checkPoint)
			if !connectedPoint.visible: continue
			if connectedPoint.clicksFromStart == null:
				connectedPoint.clicksFromStart = checkPoint.clicksFromStart+1
				nextCheck.append(connectedPoint)
				#print(str("Appending point.", " Total lines: ", checkPoint.lines.size()))
			if connectedPoint == endIndex: 
				canEnd = true
		else: #kill deleted lines
			killLines.append(line)
	for line in killLines:
		checkPoint.lines.erase(line)
	if !nextCheck.empty():
		var nextPoint = nextCheck[0]
		nextCheck.remove(0)
		determine_distances(nextPoint)

func determine_neighbors(currentPoint):
	var left = true #sometimes you just need a buncha booleans
	var topleft = true
	var top = true
	var topright = true
	var currentIndex = currentPoint.get_index()
	
	if currentIndex < columnNum: #top row
		topleft = false
		top = false
		topright = false
	if currentIndex % columnNum == 0: #leftmost column
		left = false
		topleft = false
	if currentIndex % columnNum == columnNum-1: #rightmost column
		topright = false 
	
	if left: analyze_points(currentPoint, get_point(currentIndex, 1))
	if topleft: analyze_points(currentPoint, get_point(currentIndex, columnNum + 1))
	if top: analyze_points(currentPoint, get_point(currentIndex, columnNum))
	if topright: analyze_points(currentPoint, get_point(currentIndex, columnNum - 1))

func analyze_points(one, two):
	var distance = one.position.distance_to(two.position)
	if two.visible:
		if distance < KILLDISTANCE: #kill points too close to one another
			one.visible = false #visibility toggle instead of deletion to keep the indexing functional
		elif distance <= MAXDISTANCE: #any points further away than MAXDISTANCE are usually too close to an incoming point and deleted anyway, but still
			var pointLine = Line.instance()
			$HolderHolder/LineHolder.add_child(pointLine)
			pointLine.add_point(one.position) #add points to line
			pointLine.add_point(two.position)
			pointLine.linePoints.append(one)
			pointLine.linePoints.append(two)
			var xPos = (one.position.x + two.position.x)*.5
			var yPos = (one.position.y + two.position.y)*.5
			pointLine.get_node("Text").rect_position = Vector2(xPos, yPos) #set up travel time text
			pointLine.get_node("Text").text = String(ceil(distance * DISTANCE_TIME_MULT))
			one.lines.append(pointLine) #add line to points
			two.lines.append(pointLine)

func increment_xp(amount, rewardUnit):
	var newValue = $XPBar.value + amount
	while newValue >= $XPBar.max_value:
		var rewards = [Enemies.enemyList[rewardUnit.identity]["rewards"][0]]
		inventoryWindow.add_multi(rewards)
		newValue -= $XPBar.max_value
		$XPBar.max_value += XPINCREMENT
	$XPBar.value = newValue
	$XPBar/Label.text = str($XPBar.value, "/", $XPBar.max_value)

func subtract_time(diff, refillAllMana = false):
	distanceTraveled = diff
	time -= diff
	if refillAllMana: update_mana()
	else: update_mana(diff)
	if time <= 0:
		time = DAYTIME + time
		advance_day()
	elif time <= 50: 
		isDay = false
	set_time_text()

func set_time_text():
	var biomeName = String(biomesList.keys()[currentBiome])
	timeNode.get_node("Area").text = "Area " + String(currentArea + 1)
	timeNode.get_node("Biome").text = biomeName[0].to_upper()+biomeName.substr(1, -1)
	if isDay: 
		timeNode.get_node("State").text = "Day " + String(currentDay + 1) + " - " + String(time - 50)
	else: 
		timeNode.get_node("State").text = "Night " + String(currentDay + 1)
		timeNode.get_node("Hour").text = String(time)

func eval_darkness(pointA, pointB):
	if pointA.sectionNum != currentDay and pointB.sectionNum != currentDay and !currentDungeon:
		for unit in global.storedParty:
			unit.take_damage(currentArea+1)
		battleWindow.evaluate_game_over()
		battleWindow.evaluate_revives()

func advance_day(reset = false):
	isDay = true
	if reset: currentDay = 0
	else: currentDay += 1
	set_sections()
	set_point_displays()

func set_quick_crafts():
	var quickIncrement = 80
	var presentComponents = []
	var totalRows = 0
	
	for child in $CraftScroll/ColorRect.get_children():
		$CraftScroll/ColorRect.remove_child(child)
		child.queue_free()
	
	for item in global.itemDict:
		if item != "moves": #components only
			if global.itemDict[item] >= 2:
				create_quick_craft(item, item, totalRows, quickIncrement)
				totalRows+=1
			if global.itemDict[item] >= 1:
				presentComponents.append(item)
	
	for i in presentComponents.size():
		var j = i + 1
		while j < presentComponents.size():
			create_quick_craft(presentComponents[i], presentComponents[j], totalRows, quickIncrement)
			j+=1
			totalRows+=1
	$CraftScroll/ColorRect.rect_min_size = Vector2(LEFTBOUND, quickIncrement * totalRows)

func create_quick_craft(one, two, totalRows, quickIncrement):
	var newQuick = QuickCraft.instance()
	$CraftScroll/ColorRect.add_child(newQuick)
	newQuick.position.y = totalRows * quickIncrement
	newQuick.assemble(one, two)

func set_quick_repairs():
	var quickIncrement = 80
	var totalRows = 0
	var weaponList = inventoryWindow.get_all_gear()
	
	for child in $RepairScroll/ColorRect.get_children():
		$RepairScroll/ColorRect.remove_child(child)
		child.queue_free()
	
	for weapon in weaponList:
		var newQuick = QuickRepair.instance()
		$RepairScroll/ColorRect.add_child(newQuick)
		newQuick.position.y = totalRows * quickIncrement
		newQuick.originalBox = weapon
		$HolderHolder/DisplayHolder.box_move(newQuick.get_node("Weapon"), weapon.get_node("Name").text)
		var temp = [weapon.get_node("Name").text, weapon.maxUses, weapon.currentUses]
		inventoryWindow.flip_values(newQuick.get_node("Weapon"), temp)
		totalRows += 1
		newQuick.disassemble(weapon.get_node("Name").text)
	$RepairScroll/ColorRect.rect_min_size = Vector2(LEFTBOUND, quickIncrement * totalRows)

func update_favor(amount):
	favorNode.get_node("Amount").text = String(amount)

func update_mana(gain = null):
	for unit in global.storedParty:
		if gain: unit.update_resource(gain, Moves.moveType.magic, true)
		else: unit.update_resource(unit.maxMana, Moves.moveType.magic, true)

func get_point(i, diff):
	return $HolderHolder/PointHolder.get_child(i - diff)

func fuzz_point(currentPoint):
	var pointChange = rando_fuzz()
	currentPoint.position.x = min(currentPoint.position.x - FUZZ + pointChange, bottomRight.x - CORNER_CHECK)
	pointChange = rando_fuzz() #reroll for the Y
	currentPoint.position.y = min(currentPoint.position.y - FUZZ + pointChange, bottomRight.y - CORNER_CHECK)
	currentPoint.position.y = max(currentPoint.position.y, CORNER_CHECK * 2)

func rando_fuzz():
	return randi() % (FUZZ * 2)

func move_map(pointPos):
	var checkPos = 640 - pointPos
	checkPos = min(checkPos, LEFTBOUND)
	checkPos = max(checkPos, LEFTBOUND * -1)
	$HolderHolder/LineHolder.position.x = checkPos
	$HolderHolder/PointHolder.position.x = checkPos
	$HolderHolder/SectionHolder.position.x = checkPos
