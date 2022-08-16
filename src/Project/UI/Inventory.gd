extends Node2D

export (PackedScene) var ItemBox

const XSTART = 360
const YSTART = 200

const XINCREMENT = 80
const YINCREMENT = 60

const XMAX = 8
const YMAX = 4
const CRAFTBOXES = 3
const DEFAULTCOLOR = Color(.53,.3,.3,1)
const MOVEHOLDER = "moves"
const MOVESPACES = 5

onready var iHolder = $HolderHolder/InventoryHolder
onready var cHolder = $HolderHolder/CraftboxHolder
onready var tHolder = $HolderHolder/TradeHolder
var dHolder

var productBox
var otherSelection #Used to sync a selection across all non-inventory box holders

var boxesCount = Vector2(0,0)

const TRADERINVSIZE = 8
var initialTraderValue
var currentTraderValue

enum iModes {default, craft, trade}
var mode = iModes.craft

func _ready(): #Broken with relics as a standalone scene, but works when the Map is a parent scene
	tHolder.assign_component_values()
	if global.itemDict.empty():
		global.itemDict = {"fang": 1, "wing": 2, "talon": 3, "sap": 4, "venom": 3, "fur": 2, "blade": 1, "bone": 2, "wood": 1, "moves": ["Test Relic"]}
	make_grid()
	make_actionboxes(CRAFTBOXES, true)
	make_actionboxes(TRADERINVSIZE)
	set_mode()
	if get_parent().name == "root" and global.storedParty.size() > 0: 
		dHolder = $HolderHolder/DisplayHolder
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < MOVESPACES:
				global.storedParty[i].moves.append("X")
			dHolder.setup_player(global.storedParty[i], i)
		for display in dHolder.get_children():
			display.get_node("Name").text = $Moves.get_classname(global.storedParty[display.get_index()].allowedType)
			for box in display.get_node("MoveBoxes").get_children():
				identify_product(box)
	else:
		dHolder = get_node_or_null("../HolderHolder/DisplayHolder")

func welcome_back(newMode):
	visible = true
	mode = newMode
	set_mode()
	for i in global.storedParty.size():
		for box in global.storedParty[i].boxHolder.get_children():
			box.visible = true
			identify_product(box)

func shuffle_trade_stock():
	var restock = []
	for i in global.storedParty.size():
		restock.append(rando_component())
		restock.append(rando_move(i))
	tHolder.stock = restock
	restock_trade()

func restock_trade():
	var box
	for i in tHolder.get_child_count():
		box = tHolder.get_child(i)
		box.get_node("Name").text = tHolder.stock[i] if tHolder.stock.size() > i else "X"
		identify_product(box)

func rando_component():
	var keys = $Crafting.c.keys()
	return keys[randi() % keys.size()]

func rando_move(index):
	var list = $Moves.moveList
	var rando = []
	for move in list: #populate rando with viable moves
		if list[move].has("type"): 
			if list[move]["type"] == global.storedParty[index].allowedType:
				rando.append(move)
	return rando[randi() % rando.size()]

func set_mode():
	cHolder.visible = true if mode == iModes.craft else false
	if mode == iModes.trade:
		toggle_trade_visibility(true)
		initialTraderValue = tHolder.get_inventory_value(tHolder.stock)
		currentTraderValue = initialTraderValue
		set_text($Initial, initialTraderValue)
		set_text($Current, currentTraderValue)
	else:
		toggle_trade_visibility(false)

func toggle_trade_visibility(toggle):
	tHolder.visible = toggle
	#$ResetButton.visible = toggle
	$Initial.visible = toggle
	$Current.visible = toggle

func set_text(tag, value, visibility = true):
	tag.text = String(value)
	tag.visible = visibility

func make_grid():
	for item in global.itemDict:
		if item == MOVEHOLDER:
			for move in global.itemDict[MOVEHOLDER]:
				identify_product(make_inventorybox(move))
		else:
			for i in global.itemDict[item]:
				make_inventorybox(item)
	while YMAX > boxesCount.y: #fill out the rest of the grid
		make_inventorybox("X")

func make_inventorybox(boxName):
	var box = ItemBox.instance()
	iHolder.add_child(box)
	box.position.x = XSTART + (boxesCount.x * XINCREMENT)
	box.position.y = YSTART + (boxesCount.y * YINCREMENT)
	box.get_node("Name").text = boxName
	box.get_node("Info").text = String(tHolder.get_item_value(boxName))
	incrementBoxCount()
	return box
	
func incrementBoxCount():
	boxesCount.x += 1
	if boxesCount.x >= XMAX:
		boxesCount.x = 0
		boxesCount.y +=1

func make_actionboxes(boxCount, isCraft = false):
	var box
	var usedHolder = cHolder if isCraft else tHolder
	for i in boxCount:
		box = ItemBox.instance()
		usedHolder.add_child(box)
		box.position.y = YSTART*2.5
		if isCraft: 
			box.position.x = XSTART*1.25 + (i*i*XINCREMENT) #different spacing for crafting/trading
			if i == boxCount - 1: #The crafting product box shouldn't be clickable
				box.get_node("Button").visible = false
				productBox = box
		else: 
			box.position.x = XSTART + (i * XINCREMENT)
			box.get_node("Name").text = usedHolder.stock[i] if usedHolder.stock.size() > i else "X"
			identify_product(box)

func select_box(box = null):
	box.get_parent().selectedBox = box
	box.get_node("ColorRect").color = Color(.5,.1,.5,1)
	check_swap(box)

func deselect_box(box):
	if box: 
		identify_product(box)
		box.get_parent().selectedBox = null
	#else: print("no box")

func deselect_multi(boxes):
	for box in boxes:
		deselect_box(box)
	otherSelection = null

func check_swap(selectedBox):
	if !otherSelection:
		otherSelection = selectedBox
	else:
		if selectedBox.get_parent() == cHolder: check_crafts(selectedBox, otherSelection) #crafting related checks
		elif otherSelection.get_parent() == cHolder: check_crafts(otherSelection, selectedBox)
		elif selectedBox.get_parent().name == "MoveBoxes": player_inv_check(selectedBox, otherSelection)
		elif otherSelection.get_parent().name == "MoveBoxes": player_inv_check(otherSelection, selectedBox)
		else: swap_boxes(selectedBox, otherSelection)

func player_inv_check(playerBox, otherBox):
	var checkName = otherBox.get_node("Name").text
	var playerName = playerBox.get_node("Name").text
	if $Crafting.c.get(checkName) == null: #can't move in crafting material
		var playerType = $Moves.moveList[playerName]["type"]
		var checkType = $Moves.moveList[checkName]["type"]
		#swapping into the attack/defend boxes, cannot swap an X from other players but can from inventory
		if ((playerType == $Moves.moveType.relic or playerType == $Moves.moveType.basic) 
		and (checkType == $Moves.moveType.relic or checkType == $Moves.moveType.basic or (checkType == $Moves.moveType.none and otherBox.get_parent().name != "MoveBoxes"))):
			return swap_boxes(playerBox, otherBox, true) #restore attack/defend on boxes if necessary
		
		#swapping into player's class inventory boxes
		var playerClass = global.storedParty[playerBox.get_node("../../").get_index()].allowedType #Grandpa ia a PlayerProfile, its index matches the global index
		if checkType == playerClass or checkType == $Moves.moveType.none: #The correct move type or an empty spot can be swapped
			return swap_boxes(playerBox, otherBox)
	deselect_multi([playerBox, otherBox])

func check_crafts(craftBox, otherBox):
	if !$Crafting.c.get(otherBox.get_node("Name").text) == null: 
		swap_boxes(craftBox, otherBox)
		var components = [] #Now check if both craft boxes have an entry, and if so show product and confirm button
		var productName = productBox.get_node("Name")
		if productName.text != "X":
			productName.text = "X" #Reset the field in case something was already there from prior
			productBox.get_node("ColorRect").color = DEFAULTCOLOR
		for box in cHolder.get_children():
			if box.get_node("Name").text != "X": #Product box cannot be appended as it was reset
				components.append(box.get_node("Name").text)
		if components.size() > 1: #both boxes filled
			if components[0] == components[1]:
				if global.itemDict[components[0]] < 2: #cannot merge component with itself if you only have 1 of it
					cHolder.get_child(1).get_node("Name").text = "X"
					return
			productName.text = $Crafting.sort_then_combine($Crafting.c.get(components[0]), $Crafting.c.get(components[1])) #Get result from table
			#productName.text = product #Put result name in product box
			identify_product(productBox)
			$CraftButton.visible = true
		else: #replacing a valid box with an invalid one would yield this result
			$CraftButton.visible = false

func swap_boxes(one, two, check = false):
	var temp = one.get_node("Name").text
	one.get_node("Name").text = two.get_node("Name").text
	two.get_node("Name").text = temp
	deselect_multi([one, two])
	if tHolder.visible: assess_trade_value()
	if check: restore_basics([one, two])

func restore_basics(boxes): #puts attack/defend back on non-relic boxes and remove them from inventory box
	for box in boxes:
		if box.get_parent().name == "MoveBoxes": #player box
			if $Moves.moveList[box.get_node("Name").text]["type"] <= $Moves.moveType.basic: #X or attack/defend
				if box.get_index() == 0: #attack
					box.get_node("Name").text = "Attack"
				else: #defend
					box.get_node("Name").text = "Defend"
		else: #inventory box
			if $Moves.moveList[box.get_node("Name").text]["type"] == $Moves.moveType.basic:
				box.get_node("Name").text = "X"

func assess_trade_value():
	var newStock = []
	for child in tHolder.get_children():
		if child.get_child_count() > 0: #if it has a name node
			newStock.append(child.get_node("Name").text)
	currentTraderValue = tHolder.get_inventory_value(newStock)
	$Current.text = String(currentTraderValue)
	$ExitButton.visible = true if currentTraderValue >= initialTraderValue else false

func identify_product(box):
	var skipValue = false
	var boxName = box.get_node("Name").text
	if $Moves.moveList.has(boxName):
		var productType = $Moves.moveList[boxName]["type"]
		box.moveType = productType
		if productType == $Moves.moveType.special: box.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
		elif productType == $Moves.moveType.trick: box.get_node("ColorRect").color = Color(.3,.7,.3,1) #G
		elif productType == $Moves.moveType.magic: box.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
		else: #attack/defend/X/other
			box.get_node("ColorRect").color = DEFAULTCOLOR
			skipValue = true
	else: box.get_node("ColorRect").color = DEFAULTCOLOR #component
	box.get_node("Info").text = "0" if skipValue else String(tHolder.get_item_value(boxName))


func confirm_craft(): #Subtract one from each ingredient from inventory and put in the new product
	for cBox in cHolder.get_children():
		if !cBox.get_node("Button").visible: #Button is only visible on the non-result boxes, so this runs once on the result box
			cBox.get_node("ColorRect").color = DEFAULTCOLOR
			var iName
			for iBox in iHolder.get_children():
				iName = iBox.get_node("Name").text
				if iName == "X":
					iBox.get_node("Name").text = cBox.get_node("Name").text #Put product in there
					identify_product(iBox)
					break
		cBox.get_node("Name").text = "X"
		cBox.get_node("Info").text = ""
	$CraftButton.visible = false

func exit(): #Save inventory and leave
	var unit
	var moveName
	var moveData
	var checkType
	for i in global.storedParty.size():
		unit = global.storedParty[i]
		unit.moves.clear()
		unit.passives.clear()
		for box in dHolder.get_child(i).get_node("MoveBoxes").get_children(): #Accessing the moveboxes
			moveName = box.get_node("Name").text
			moveData = $Moves.moveList[moveName]
			checkType = moveData["type"]
			if checkType != $Moves.moveType.relic and checkType != $Moves.moveType.basic:
				unit.moves.append(moveName)
			if moveData.has("passive"):
				unit.passives[moveData["passive"][0]] = moveData["passive"][1]
	for item in global.itemDict:
		global.itemDict[item] = 0
	global.itemDict[MOVEHOLDER] = [] #Redoing the moveholder with potential new moves
	for iBox in iHolder.get_children():
		var iName = iBox.get_node("Name").text
		if iName == "X": continue #do not want to do anything with the Xs
		if global.itemDict.has(iName): #it's a move and goes in the holder
			global.itemDict[iName] += 1
		else: #it's a move and goes in the holder
			global.itemDict[MOVEHOLDER].append(iName)
	done()

func done():
	if get_parent().name == "root":
		return get_tree().change_scene("res://src/Project/Debug.tscn")
	else:
		for i in global.storedParty.size():
			dHolder.cleanup_moves(global.storedParty[i], DEFAULTCOLOR)
		visible = false

func reset_trade():
	return get_tree().reload_current_scene()
