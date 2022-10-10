extends Node2D

export (PackedScene) var MoveBox

const XSTART = 360
const YSTART = 125

const XINCREMENT = 80
const YINCREMENT = 60

const XMAX = 8
const YMAX = 4
const CRAFTBOXES = 3
const DEFAULTCOLOR = Color(.53,.3,.3,1)
const MOVEHOLDER = "moves"
var MOVESPACES = 4

onready var iHolder = $HolderHolder/InventoryHolder
onready var cHolder = $HolderHolder/CraftboxHolder
onready var tHolder = $HolderHolder/TradeHolder
onready var oHolder = $HolderHolder/OfferingHolder
onready var Trading = get_node("../Data/Trading")
onready var Moves = get_node("../Data/Moves")
onready var Crafting = get_node("../Data/Crafting")
onready var Boons = get_node("../Data/Boons")
var dHolder

var productBox
var otherSelection #Used to sync a selection across all non-inventory box holders

var boxesCount = Vector2(0,0)

var currentInvSize = 0

var craftingRestriction = null

const TRADERINVSIZE = 8
var initialTraderValue
var currentTraderValue

enum oTypes {component, weapon}
var offerType
var offerNeed

enum iModes {default, craft, trade, offer}
var mode = iModes.craft

func _ready(): #Broken with relics as a standalone scene, but works when the Map is a parent scene
	MOVESPACES += Boons.call_boon("prep_inventory")
	if !Trading.assigned: Trading.assign_component_values()
	if global.itemDict.empty():
		global.itemDict = {"fang": 2, "wing": 2, "talon": 3, "sap": 4, "venom": 3, "fur": 2, "blade": 2, "bone": 2, "wood": 1, "moves": ["Test Relic", "Coin", "Coin", "Coin"]}
	make_grid()
	make_actionboxes(CRAFTBOXES, iModes.craft)
	make_actionboxes(TRADERINVSIZE, iModes.trade)
	make_actionboxes(1, iModes.offer)
	set_mode()
	if !get_parent().mapMode and global.storedParty.size() > 0: 
		dHolder = $HolderHolder/DisplayHolder
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < MOVESPACES:
				global.storedParty[i].moves.append("X")
			dHolder.setup_player(global.storedParty[i], i)
		for display in dHolder.get_children():
			display.get_node("Name").text = Moves.get_classname(global.storedParty[display.get_index()].allowedType)
			for box in display.get_node("MoveBoxes").get_children():
				identify_product(box)
	else:
		dHolder = get_node_or_null("../Map/HolderHolder/DisplayHolder")

func welcome_back(newMode):
	mode = newMode
	set_mode()
	for i in global.storedParty.size():
		for box in global.storedParty[i].boxHolder.get_children():
			box.visible = true
			identify_product(box)
	visible = true

func shuffle_trade_stock():
	var restock = []
	for i in global.storedParty.size():
		restock.append(rando_component())
		restock.append(rando_move(i))
	Trading.stock = restock
	restock_trade()

func restock_trade():
	var box
	for i in tHolder.get_child_count():
		box = tHolder.get_child(i)
		box.get_node("Name").text = Trading.stock[i] if Trading.stock.size() > i else "X"
		identify_product(box)

func rando_component():
	var keys = Crafting.c.keys()
	return keys[randi() % keys.size()]

func rando_move(index):
	var list = Moves.moveList
	var rando = []
	for move in list: #populate rando with viable moves
		if list[move].has("type"): 
			if list[move]["type"] == global.storedParty[index].allowedType:
				rando.append(move)
	return rando[randi() % rando.size()]

func set_mode():
	cHolder.visible = true if mode == iModes.craft else false
	oHolder.visible = true if mode == iModes.offer else false
	if mode == iModes.trade:
		toggle_trade_visibility(true)
		initialTraderValue = Trading.get_inventory_value(Trading.stock)
		currentTraderValue = initialTraderValue
		set_text($Initial, initialTraderValue)
		set_text($Current, currentTraderValue)
	else:
		toggle_trade_visibility(false)

func toggle_trade_visibility(toggle):
	tHolder.visible = toggle
	if toggle: toggle_action_button(true, "Reset")
	else: toggle_action_button(false)
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
	var box = MoveBox.instance()
	iHolder.add_child(box)
	box.position.x = XSTART + (boxesCount.x * XINCREMENT)
	box.position.y = YSTART + (boxesCount.y * YINCREMENT)
	box.get_node("Name").text = boxName
	box.get_node("Info").text = String(Trading.get_item_value(boxName))
	incrementBoxCount()
	box.set_uses(Moves.get_uses(boxName))
	return box
	
func incrementBoxCount():
	boxesCount.x += 1
	if boxesCount.x >= XMAX:
		boxesCount.x = 0
		boxesCount.y +=1

func make_actionboxes(boxCount, boxMode):
	var box
	var usedHolder 
	if boxMode == iModes.craft:
		usedHolder = cHolder
	elif boxMode == iModes.trade:
		usedHolder = tHolder
	else:
		usedHolder = oHolder
	for i in boxCount:
		box = MoveBox.instance()
		usedHolder.add_child(box)
		box.position.y = YSTART*3.25
		if boxMode == iModes.craft: 
			box.position.x = XSTART*1.25 + (i*i*XINCREMENT) #different spacing for crafting/trading
			if i == boxCount - 1: #The crafting product box shouldn't be clickable
				box.get_node("Button").visible = false
				productBox = box
		elif boxMode == iModes.trade: 
			box.position.x = XSTART + (i * XINCREMENT)
			box.get_node("Name").text = Trading.stock[i] if Trading.stock.size() > i else "X"
			identify_product(box)
		else: #offer
			box.position.x = XSTART * 1.77

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
		if mode == iModes.offer:
			var canOffer = false
			if selectedBox.get_parent() == oHolder: canOffer = check_offering(otherSelection)
			elif otherSelection.get_parent() == oHolder: canOffer = check_offering(selectedBox)
			if !canOffer: 
				deselect_multi([selectedBox, otherSelection])
				return
		elif mode == iModes.craft:
			if selectedBox.get_parent() == cHolder: 
				check_crafts(selectedBox, otherSelection) #crafting related checks
				return
			elif otherSelection.get_parent() == cHolder: 
				check_crafts(otherSelection, selectedBox)
				return
		if selectedBox.get_parent().name == "MoveBoxes": player_inv_check(selectedBox, otherSelection)
		elif otherSelection.get_parent().name == "MoveBoxes": player_inv_check(otherSelection, selectedBox)
		else: swap_boxes(selectedBox, otherSelection)

func player_inv_check(playerBox, otherBox): #returns true/false depending on if it swaps or not
	var checkName = otherBox.get_node("Name").text
	var playerName = playerBox.get_node("Name").text
	if Crafting.c.get(checkName) == null: #can't move in crafting material
		if Moves.moveList[checkName].has("unequippable"): 
			deselect_multi([playerBox, otherBox])
			return false
		var playerType = Moves.moveList[playerName]["type"]
		var checkType = Moves.moveList[checkName]["type"]
		#swapping into the attack/defend boxes, cannot swap an X from other players but can from inventory
		if ((playerType == Moves.moveType.relic or playerType == Moves.moveType.basic) 
		and (checkType == Moves.moveType.relic or checkType == Moves.moveType.basic or (checkType == Moves.moveType.none and otherBox.get_parent().name != "MoveBoxes"))):
			swap_boxes(playerBox, otherBox, true) #restore attack/defend on boxes if necessary
			return true
		
		#swapping into player's class inventory boxes
		var playerClass = global.storedParty[playerBox.get_node("../../").get_index()].allowedType #Grandpa ia a PlayerProfile, its index matches the global index
		if checkType == playerClass or checkType == Moves.moveType.none or checkType == Moves.moveType.item: #The correct move type, an item, or an empty spot can be swapped
			swap_boxes(playerBox, otherBox)
			return true
	deselect_multi([playerBox, otherBox])
	return false

func isValidMove(boxName):
	if Moves.moveList.has(boxName):
		var checkType = Moves.moveList[boxName]["type"]
		if checkType > Moves.moveType.relic:
			return true
	return false

#todo - section this into multiple funcs for different methods, run a player inv check for weapons
func check_crafts(craftBox, otherBox):
	var didSwap = false
	var boxName = otherBox.get_node("Name").text
	if Crafting.c.get(boxName): 
		swap_boxes(craftBox, otherBox)
		didSwap = true
	if isValidMove(boxName) or boxName == "X":
		if otherBox.get_parent().name == "MoveBoxes":
			didSwap = player_inv_check(otherBox, craftBox) #returns true/false and does a swap
			craftingRestriction = Crafting.break_down(boxName)
		else:
			swap_boxes(craftBox, otherBox)
			didSwap = true
			craftingRestriction = Crafting.break_down(boxName)
	if didSwap:
		var productName = productBox.get_node("Name")
		if productName.text != "X":
			productName.text = "X" #Reset the field in case something was already there from prior
			productBox.get_node("ColorRect").color = DEFAULTCOLOR
		
		var components = [] #Now check if both craft boxes have an entry, and if so show product and confirm button
		for box in cHolder.get_children():
			if box.get_node("Name").text != "X": #Product box cannot be appended as it was reset
				components.append(box.get_node("Name").text)
		if components.size() > 1: #both boxes filled
			if craftingRestriction: #weapon repair check
				for i in components.size():
					if Crafting.c.get(components[i]) != null and craftingRestriction.has(components[i]):
						var weaponBox = cHolder.get_child(abs(i-1))
						flip_values(productBox, [weaponBox.get_node("Name").text, weaponBox.maxUses, weaponBox.currentUses])
						productBox.repair_uses()
						identify_product(productBox)
						toggle_action_button(true, "Repair")
						break
					if i == 1: #only gets in this if it's an invalid repair
						toggle_action_button(false)
			else:
				productName.text = Crafting.sort_then_combine(Crafting.c.get(components[0]), Crafting.c.get(components[1])) #Get result from table
				#productName.text = product #Put result name in product box
				identify_product(productBox)
				productBox.set_uses(Moves.get_uses(productName.text))
				toggle_action_button(true, "Craft")
		else: #replacing a valid box with an invalid one would yield this result
			toggle_action_button(false)
	else:
		deselect_multi([craftBox, otherBox])

func check_offering(offeringBox):
	if offeringBox.get_node("Name").text == "X": return true
	elif offerType == oTypes.component:
		if offeringBox.get_node("Name").text != offerNeed:
			return false
	elif offerType == oTypes.weapon:
		var boxName = offeringBox.get_node("Name").text
		if Moves.moveList.has(boxName):
			if Moves.moveList[boxName]["type"] != Moves.moveType.get(offerNeed):
				return false
	toggle_action_button(true, "Offer")
	return true

func toggle_action_button(toggle, buttonText = ""):
	$ActionButton.visible = toggle
	$ActionButton.text = buttonText

func swap_boxes(one, two, check = false):
	var temp = [one.get_node("Name").text, one.maxUses, one.currentUses]
	flip_values(one, [two.get_node("Name").text, two.maxUses, two.currentUses])
	flip_values(two, temp)
	dHolder.set_boxes([one, two])
	deselect_multi([one, two])
	if tHolder.visible: assess_trade_value()
	if check: restore_basics([one, two])

func flip_values(box, values):
	box.get_node("Name").text = values[0]
	box.maxUses = values[1]
	box.currentUses = values[2]
	box.set_uses()

func restore_basics(boxes): #puts attack/defend back on non-relic boxes and remove them from inventory box
	for box in boxes:
		if box.get_parent().name == "MoveBoxes": #player box
			if Moves.moveList[box.get_node("Name").text]["type"] <= Moves.moveType.basic: #X or attack/defend
				if box.get_index() == 0: #attack
					box.get_node("Name").text = "Attack"
				else: #defend
					box.get_node("Name").text = "Defend"
		else: #inventory box
			if Moves.moveList[box.get_node("Name").text]["type"] == Moves.moveType.basic:
				box.get_node("Name").text = "X"

func assess_trade_value():
	var newStock = []
	for child in tHolder.get_children():
		if child.get_child_count() > 0: #if it has a name node
			newStock.append(child.get_node("Name").text)
	currentTraderValue = Trading.get_inventory_value(newStock)
	$Current.text = String(currentTraderValue)
	$ExitButton.visible = true if currentTraderValue >= initialTraderValue else false

func identify_product(box): #updates box color and trade value
	var skipValue = false
	var boxName = box.get_node("Name").text
	if Moves.moveList.has(boxName):
		var productType = Moves.moveList[boxName]["type"]
		box.moveType = productType
		if productType == Moves.moveType.special: box.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
		elif productType == Moves.moveType.trick: box.get_node("ColorRect").color = Color(.3,.7,.3,1) #G
		elif productType == Moves.moveType.magic: box.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
		elif productType == Moves.moveType.item:  box.get_node("ColorRect").color = Color(.9,.7, 0,1) #Y
		elif productType == Moves.moveType.relic: box.get_node("ColorRect").color = DEFAULTCOLOR #relics need a color
		else: #attack/defend/X/other
			box.get_node("ColorRect").color = DEFAULTCOLOR
			skipValue = true
	else: box.get_node("ColorRect").color = DEFAULTCOLOR #component
	box.get_node("Info").text = "0" if skipValue else String(Trading.get_item_value(boxName))

func xCheck(): #returns an empty inventory space, todo: scenario for full inventory
	var iName
	for iBox in iHolder.get_children():
		iName = iBox.get_node("Name").text
		if iName == "X":
			return iBox

func clear_box(box):
	box.get_node("Name").text = "X" 
	box.get_node("Info").text = ""
	box.set_uses(-1)
	identify_product(box)

func confirm_craft():
	for cBox in cHolder.get_children():
		if !cBox.get_node("Button").visible: #Button is only visible on the non-result boxes, so this runs once on the result box
			swap_boxes(cBox, xCheck())
		else:
			clear_box(cBox)
	toggle_action_button(false)

func add_item(itemName, newUses = false): #todo: case for full inventory
	var openBox = xCheck()
	openBox.get_node("Name").text = itemName #Put product in there
	identify_product(openBox)
	if newUses: openBox.set_uses(Moves.get_uses(itemName))
	update_itemDict(itemName)

func update_itemDict(itemName):
	currentInvSize += 1
	if currentInvSize > XMAX * YMAX: 
		print("inventory overflow")
	else:
		if global.itemDict.has(itemName): #it's a component
			global.itemDict[itemName] += 1
		else: #it's a move and goes in the holder
			global.itemDict[MOVEHOLDER].append(itemName)

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
			moveData = Moves.moveList[moveName]
			checkType = moveData["type"]
			if checkType != Moves.moveType.relic and checkType != Moves.moveType.basic:
				unit.moves.append(moveName)
			if moveData.has("passive"):
				unit.passives[moveData["passive"][0]] = moveData["passive"][1]
	for item in global.itemDict:
		global.itemDict[item] = 0
	global.itemDict[MOVEHOLDER] = [] #Redoing the moveholder with potential new moves
	currentInvSize = 0
	for iBox in iHolder.get_children():
		var iName = iBox.get_node("Name").text
		if iName == "X": continue #do not want to do anything with the Xs
		update_itemDict(iName)
	done()

func done():
	if !get_parent().mapMode:
		return get_tree().reload_current_scene()
	else:
		for i in global.storedParty.size():
			dHolder.manage_and_color_boxes(global.storedParty[i])
		visible = false

func reset_trade():
	return get_tree().reload_current_scene()

func _on_ActionButton_pressed():
	if mode == iModes.craft:
		confirm_craft()
	elif mode == iModes.trade:
		reset_trade()
	elif mode == iModes.offer:
		exit()
		get_node("../Map/Events").give_reward()
