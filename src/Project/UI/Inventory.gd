extends Node2D

export (PackedScene) var MoveBox

const XSTART = 50
const YSTART = 645
const TRADEXSTART = 440
const TRADEYSTART = 80

const XINCREMENT = 80
const YINCREMENT = 60
const GAPSIZE = 305

const NEWBOXES = 2

const XMAX = 12
const YMAX = 1
const CRAFTBOXES = 3
const DEFAULTCOLOR = Color(.53,.3,.3,1)
const MOVEHOLDER = "moves"
var MOVESPACES = 4

onready var iHolder = $HolderHolder/InventoryHolder
onready var tHolder = $HolderHolder/TradeHolder
onready var oHolder = "ChoiceUI"
onready var Trading = get_node("../Data/Trading")
onready var Moves = get_node("../Data/Moves")
onready var Crafting = get_node("../Data/Crafting")
onready var Boons = get_node("../Data/Boons")
var dHolder

var productBox
var otherSelection #Used to sync a selection across all non-inventory box holders

var boxesCount = Vector2(0,0)

var currentInvSize = 0

const TRADERINVSIZE = 12
const TRADERROWLIMIT = 6
var initialTraderValue
var currentTraderValue

enum oTypes {component, weapon, any}
var offerMode = oModes.reward
var offerType
var offerNeed
var quickActions = false

enum iModes {default, craft, trade, offer}
enum oModes {remove, repair, reward}
var mode = iModes.craft

var drag = false
var undrag = false

var repairBonus = false

func _ready():
	if global.itemDict.empty():
		global.itemDict = {"wing": 0, "fang": 0, "claw": 0, "sap": 0, "venom": 0, "fur": 0, "blade": 0, "bone": 0, "garbage": 0, "darkness": 0, "tentacle": 0, "flame": 0, "moves": ["Health Potion"]}
	MOVESPACES += Boons.call_boon("prep_inventory")
	dHolder = $HolderHolder/DisplayHolder
	make_grid()
	make_actionboxes(TRADERINVSIZE, TRADERROWLIMIT)
	if !get_parent().mapMode and global.storedParty.size() > 0: 
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

func check_undrag(_box): #when the mouse leaves a box
	if otherSelection != null: undrag = true

func check_drag(button): #dragging a box onto another box or a player profile
	if drag:
		button._on_Button_pressed()
		undrag = false
		drag = false
		#Input.set_custom_mouse_cursor(null)

func _process(_delta):
	if Input.is_action_just_released("left_click"):
		drag = false
		if undrag:
			if otherSelection != null: 
				if get_node("../Map").selectedMapMove != null:
					get_node("../Map").end_map_move()
				else:
					deselect_multi([otherSelection])
			undrag = false
		#Input.set_custom_mouse_cursor(null)

func welcome_back():
	toggle_trade_visibility(true)
	initialTraderValue = Trading.get_inventory_value(Trading.stock)
	currentTraderValue = initialTraderValue
	set_text($Initial, initialTraderValue)
	set_text($Current, currentTraderValue)

func name_exitButton():
	if mode == iModes.offer:
		if offerMode == oModes.reward: $ExitButton.text = "Offer"
		elif offerMode == oModes.repair: $ExitButton.text = "Repair"
		else: $ExitButton.text = "Toss"
	else: $ExitButton.text = "Exit"

func shuffle_trade_stock():
	var restock = []
	if !get_node("../Map").activePoint.traderStock:
		var maxItems = tHolder.get_child_count()
		for i in global.storedParty.size():
			restock.append(rando_move(i))
		restock.append(rando_relic())
		restock.append(rando_relic())
		restock.append(rando_item())
		restock.append(rando_item())
		restock.append(rando_component())
		restock.append(rando_component(true))
		restock.append("Coin")
		if get_parent().hardMode:
			while restock.size() < maxItems:
				restock.append("Coin")
		else:
			while restock.size() < maxItems:
				restock.append("X")
	else:
		restock = get_node("../Map").activePoint.traderStock
	Trading.stock = restock
	restock_trade()

func restock_trade():
	var box
	for i in tHolder.get_child_count():
		box = tHolder.get_child(i)
		if Trading.stock.size() > i:
			dHolder.box_move(box, Trading.stock[i])
			box.set_uses(Moves.get_uses(Trading.stock[i]))
		else:
			dHolder.box_move(box, "X")
		identify_product(box)

func rando_component(rare = false):
	var keys = Crafting.c.keys()
	var validComponents = []
	if rare:
		for component in keys:
			if Trading.values[component] >= 5: validComponents.append(component)
	else: validComponents = keys
	return validComponents[randi() % validComponents.size()]

func rando_item():
	var list = Moves.moveList
	var rando = []
	for move in list: #populate rando with viable moves
		if  list[move].has("type") and list[move]["type"] == Moves.moveType.item:
			rando.append(move)
	return rando[randi() % rando.size()]

func rando_move(index):
	var list = Moves.moveList
	var rando = []
	for move in list: #populate rando with viable moves
		if (!list[move].has("slot") or list[move]["slot"] == Moves.equipType.gear) and list[move].has("type"):
			if list[move]["type"] == global.storedParty[index].allowedType and list[move]["target"] != Moves.targetType.none: #reload/catch
				rando.append(move)
	return rando[randi() % rando.size()]

func rando_relic():
	var relics = Moves.get_relics()
	relics.erase("Silver")
	relics.erase("Silver")
	return relics[randi() % relics.size()]

func toggle_trade_visibility(toggle):
	tHolder.visible = toggle
	#if toggle: toggle_action_button(true, "Reset")
	$Initial.visible = toggle
	$Current.visible = toggle
	$BG.visible = toggle
	$ExitButton.visible = toggle

func set_text(tag, value, visibility = true):
	tag.text = String(value)
	tag.visible = visibility

func make_grid():
	dHolder.Moves = Moves
	while YMAX > boxesCount.y: #fill out the rest of the grid
		make_inventorybox("X", true)
	for item in global.itemDict:
		if item == MOVEHOLDER:
			for move in global.itemDict[MOVEHOLDER]:
				add_item(move, true)
		else:
			for i in global.itemDict[item]:
				add_item(item)

func make_inventorybox(boxName, useGap = false):
	var box = MoveBox.instance()
	if useGap:
		var hotkey = InputEventKey.new()
		hotkey.set_scancode(get_scancode(int(boxesCount.x)))
		if boxesCount.x >= XMAX * .5: hotkey.set_shift(true)
		box.get_node("Button").shortcut = ShortCut.new()
		box.get_node("Button").shortcut.set_shortcut(hotkey)
		if boxesCount.x < NEWBOXES or XMAX - boxesCount.x <= NEWBOXES: box.visible = false
		
	iHolder.add_child(box)
	box.position.x = XSTART + (boxesCount.x * XINCREMENT)
	if boxesCount.x >= XMAX * .5 and useGap: box.position.x += GAPSIZE
	box.position.y = YSTART + (boxesCount.y * YINCREMENT)
	box.get_node("Name").text = boxName
	box.get_node("Info").text = String(Trading.get_item_value(boxName))
	incrementBoxCount()
	dHolder.box_move(box, boxName)
	box.set_uses(Moves.get_uses(boxName))
	return box

func get_scancode(boxIndex):
	if boxIndex == 0 or boxIndex == 11: return KEY_H
	if boxIndex == 1 or boxIndex == 10: return KEY_G
	if boxIndex == 2 or boxIndex == 9: return KEY_F
	if boxIndex == 3 or boxIndex == 8: return KEY_D
	if boxIndex == 4 or boxIndex == 7: return KEY_S
	if boxIndex == 5 or boxIndex == 6: return KEY_A

func incrementBoxCount():
	boxesCount.x += 1
	if boxesCount.x >= XMAX:
		boxesCount.x = 0
		boxesCount.y +=1

func make_actionboxes(boxCount, rowLimit):
	for i in boxCount:
		var box = MoveBox.instance()
		tHolder.add_child(box)
		box.position.y = TRADEYSTART*2 if i < rowLimit else TRADEYSTART*2 + YINCREMENT
		box.position.x = TRADEXSTART + (i * XINCREMENT) if i < rowLimit else TRADEXSTART + ((i - rowLimit) * XINCREMENT)
		if Trading.stock.size() > i: dHolder.box_move(box, Trading.stock[i])
		else: dHolder.box_move(box, "X")
		identify_product(box)

func unhide_boxes():
	var hiddenBoxes = []
	for iBox in iHolder.get_children():
		if !iBox.visible:
			hiddenBoxes.append(iBox)
	if hiddenBoxes.size() > NEWBOXES:
		hiddenBoxes[1].visible = true
		hiddenBoxes[-2].visible = true
	else:
		hiddenBoxes[0].visible = true
		hiddenBoxes[-1].visible = true

func select_box(box = null):
	box.get_node("ColorRect").color = Color(.5,.1,.5,.3)
	box.get_node("ColorRect").visible = true
	check_swap(box)

func deselect_box(box):
	if box:
		identify_product(box)
	#else: print("no box")

func deselect_multi(boxes):
	for box in boxes:
		deselect_box(box)
	otherSelection = null
	player_blackouts()

func quick_repair(moveBox, componentBox):
	var craftingRestriction = Crafting.break_down(moveBox.get_node("Name").text)
	if craftingRestriction.has(componentBox.get_node("Name").text):
		if moveBox.currentUses < moveBox.maxUses: #do not repair a full weapon
			clear_box(componentBox)
			moveBox.repair_uses(repairBonus)
			set_box_value(moveBox, moveBox.moves[0])
			return true
	else:
		return false

func inventory_blackouts(toggle):
	for box in iHolder.get_children():
		box.get_node("Blackout").visible = toggle

func player_blackouts(checkBox = null):
	for display in dHolder.get_children():
		for box in display.get_node("MoveBoxes").get_children():
			if checkBox and !player_inv_check(box, checkBox, false):
				box.get_node("Blackout").visible = true
			else:
				box.get_node("Blackout").visible = false

func check_swap(selectedBox):
	if !otherSelection:
		otherSelection = selectedBox
		player_blackouts(selectedBox)
	elif otherSelection == selectedBox: 
		deselect_multi([selectedBox])
		if get_node("../Map").selectedMapBox: get_node("../Map").end_map_move()
	else:
		var canOffer = false 
		var checkingOffering = false
		if selectedBox.name == "Offerbox": 
			checkingOffering = true
			canOffer = check_offering(otherSelection)
		elif otherSelection.name == "Offerbox":
			checkingOffering = true
			canOffer = check_offering(selectedBox)
		if !canOffer and checkingOffering:
			deselect_multi([selectedBox, otherSelection])
			return
		if quickActions and otherSelection.get_parent() != tHolder and selectedBox.get_parent() != tHolder: #this is for quick crafts/repairs, disabled by default
			var potentialProduct = Crafting.sort_then_combine(Crafting.c.get(otherSelection.get_node("Name").text), Crafting.c.get(selectedBox.get_node("Name").text))
			if potentialProduct.length() > 1:
				clear_box(selectedBox)
				clear_box(otherSelection)
				deselect_multi([selectedBox, otherSelection])
				add_item(potentialProduct, true)
				return
			var quickCheck = false
			if isValidMove(selectedBox.get_node("Name").text): quickCheck = quick_repair(selectedBox, otherSelection)
			elif isValidMove(otherSelection.get_node("Name").text): quickCheck = quick_repair(otherSelection, selectedBox)
			if quickCheck:
				deselect_multi([selectedBox, otherSelection])
				return
		if selectedBox.get_parent().name == "MoveBoxes": player_inv_check(selectedBox, otherSelection)
		elif otherSelection.get_parent().name == "MoveBoxes": player_inv_check(otherSelection, selectedBox)
		else: swap_boxes(selectedBox, otherSelection)

func player_inv_check(playerBox, otherBox, doSwap = true): #returns true/false depending on if it swaps or not
	var checkName = otherBox.get_node("Name").text
	var playerName = playerBox.get_node("Name").text
	var playerClass = global.storedParty[playerBox.get_node("../../").get_index()].allowedType #Grandpa ia a PlayerProfile, its index matches the global index
	if Crafting.c.get(checkName) == null: #can't move in crafting material
		if Moves.moveList[checkName].has("unequippable"): 
			if doSwap: deselect_multi([playerBox, otherBox])
			return false
		#var playerType = Moves.moveList[playerName]["type"]
		var checkType = Moves.moveList[checkName]["type"]
		var playerSlot = Moves.moveList[playerName]["slot"]
		var checkSlot = Moves.moveList[checkName]["slot"]
		#swapping into the attack/defend boxes, cannot swap an X from other players but can from inventory
		if playerSlot == Moves.equipType.relic:
			if checkSlot == Moves.equipType.relic or (checkSlot == Moves.equipType.any and otherBox.get_parent().name != "MoveBoxes"):
				if checkType < Moves.moveType.item or checkType == playerClass:
					if doSwap: swap_boxes(playerBox, otherBox, true) #restore attack/defend on boxes if necessary
					return true
		else: #swapping into player's class inventory boxes
			if (checkType == playerClass or checkType == Moves.moveType.none or checkType == Moves.moveType.item) and checkSlot != Moves.equipType.relic: #The correct move type, an item, or an empty spot can be swapped
				if doSwap: swap_boxes(playerBox, otherBox)
				return true
	if doSwap: deselect_multi([playerBox, otherBox])
	return false

func add_to_player(itemName):
	var checkType = Moves.moveList[itemName]["type"]
	for player in global.storedParty:
		var playerClass = player.allowedType
		for box in player.boxHolder.get_children():
			if box.get_node("Name").text == "X" and (checkType == Moves.moveType.item or checkType == playerClass):
				dHolder.box_move(box, itemName)
				identify_product(box)
				box.set_uses(Moves.get_uses(itemName))
				reset_and_update_itemDict()
				return box
	return add_item(itemName, true) #if no player slots open, add to inventory

func isValidMove(boxName):
	if Moves.moveList.has(boxName):
		var checkType = Moves.moveList[boxName]["type"]
		if checkType > Moves.moveType.basic:
			return true
	return false

func check_offering(offeringBox):
	var oName = offeringBox.get_node("Name").text
	if oName == "X": return true
	elif offerType == oTypes.component:
		if oName != offerNeed:
			return false
	elif offerType == oTypes.weapon:
		if Moves.moveList.has(oName):
			if Moves.moveList[oName]["type"] != Moves.moveType.get(offerNeed):
				return false
	else: #anything that isn't cursed
		if Moves.moveList.has(oName) and Moves.moveList[oName].has("cursed"):
			return false
	#toggle_action_button(true, "Offer")
	return true

func toggle_action_button(toggle, buttonText = ""):
	$ActionButton.visible = toggle
	$ActionButton.text = buttonText

func swap_boxes(one, two, check = false):
	get_node("../Map").hide_undo()
	one.get_node("Tooltip").visible = false
	two.get_node("Tooltip").visible = false
	var temp = [one.get_node("Name").text, one.maxUses, one.currentUses]
	flip_values(one, [two.get_node("Name").text, two.maxUses, two.currentUses])
	flip_values(two, temp)
	one.set_uses() #set the uses so the bar is updated appropriately
	two.set_uses()
	dHolder.set_boxes([one, two])
	if check: restore_basics([one, two])
	deselect_multi([one, two])
	if tHolder.visible: assess_trade_value()
	
	if one.get_parent().name == "MoveBoxes": assess_unit_passives(one.get_parent().get_parent().get_index())
	if two.get_parent().name == "MoveBoxes": assess_unit_passives(two.get_parent().get_parent().get_index())
	if one.name == "Offerbox": finalize_offering(one)
	elif two.name == "Offerbox": finalize_offering(two)
	if tHolder.visible: reset_and_update_itemDict() #make sure quick panels are accurate while trading
	if get_node("../Map").selectedMapBox: get_node("../Map").end_map_move()

func finalize_offering(offeringBox):
	if offeringBox.get_node("Name").text != "X":
		offeringBox.get_node("../Button").visible = true
	else:
		offeringBox.get_node("../Button").visible = false

func flip_values(box, values): #values are: name, max uses, current uses
	box.get_node("Name").text = values[0]
	box.maxUses = values[1]
	box.currentUses = values[2]
	box.set_uses()

func restore_basics(boxes): #puts attack/defend back on non-relic boxes and remove them from inventory box
	var moveInfo
	for box in boxes:
		moveInfo = Moves.moveList[box.get_node("Name").text]
		if box.get_parent().name == "MoveBoxes": #player box
			if (box.get_index() <= 1 #X or attack/defend
			and (moveInfo["type"] == Moves.moveType.basic or moveInfo["slot"] == Moves.equipType.any)): 
				if box.get_index() == 0: #attack
					dHolder.box_move(box, "Attack")
				else: #defend
					dHolder.box_move(box, "Defend")
			elif moveInfo.has("morph"):
				dHolder.box_move(box, moveInfo["morph"][box.get_index()])
			if Moves.get_uses(box.moves[0]) <= 0:
				box.set_uses(-1)
		else: #inventory box
			if Moves.moveList[box.get_node("Name").text]["type"] == Moves.moveType.basic:
				dHolder.box_move(box, "X")
			elif moveInfo.has("morph") and moveInfo["morph"].size() >= 2:
				dHolder.box_move(box, moveInfo["morph"][2])

func get_trader_components():
	var tComponents = []
	if tHolder.visible:
		for box in tHolder.get_children():
			if global.itemDict.has(box.get_node("Name").text):
				tComponents.append(box.get_node("Name").text)
	return tComponents

func assess_trade_value():
	var newStock = []
	var stockBoxes = []
	for child in tHolder.get_children():
		if child.get_child_count() > 0: #if it has a name node
			newStock.append(child.get_node("Name").text)
			stockBoxes.append(child)
	currentTraderValue = Trading.get_inventory_value(newStock, stockBoxes)
	$Current.text = String(currentTraderValue)
	$ExitButton.visible = true if currentTraderValue >= initialTraderValue else false
	if $ExitButton.visible: $ExitButton.visible = check_for_curses(newStock)

func check_for_curses(stock):
	for item in stock:
		if Moves.moveList.has(item) and Moves.moveList[item].has("cursed"): return false
	return true

func identify_product(box): #updates box color and trade value
	var boxName = box.get_node("Name").text
	if Moves.moveList.has(boxName) and !box.get_node("Sprite").visible:
		var productType = Moves.moveList[boxName]["type"]
		box.moveType = productType
		if productType == Moves.moveType.special: box.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
		elif productType == Moves.moveType.trick: box.get_node("ColorRect").color = Color(.3,.7,.3,1) #G
		elif productType == Moves.moveType.magic: box.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
		elif productType == Moves.moveType.item or Moves.moveList[boxName]["slot"] == Moves.equipType.relic:  box.get_node("ColorRect").color = Color(.9,.7, 0,1) #Y
		elif Moves.moveList[boxName].has("unequippable"): box.get_node("ColorRect").color = Color.orangered
		else: #X/other
			box.get_node("ColorRect").color = DEFAULTCOLOR
	else: 
		if box.get_node("Sprite").visible:
			box.get_node("ColorRect").visible = false
		else:
			box.get_node("ColorRect").color = DEFAULTCOLOR
	set_box_value(box, boxName)

func revalue_all_gear():
	for box in iHolder.get_children():
		set_box_value(box, box.get_node("Name").text)
	for display in dHolder.get_children():
		for box in display.get_node("MoveBoxes").get_children():
			set_box_value(box, box.moves[0])

func set_box_value(box, boxName):
	var boxInfo = box.get_node("Info")
	boxInfo.text = String(Trading.get_item_value(boxName, box))
	boxInfo.visible = false if boxInfo.text == "0" else true

func get_all_gear():
	var allGear = []
	for player in global.storedParty:
		for box in player.boxHolder.get_children():
			var boxName = box.get_node("Name").text
			if Moves.moveList[boxName]["slot"] == Moves.equipType.gear and box.currentUses < box.maxUses and box.currentUses > 0:
				allGear.append(box)
	for iBox in iHolder.get_children():
		if is_box_damaged(iBox): allGear.append(iBox)
	if tHolder.visible: for tBox in tHolder.get_children():
		if is_box_damaged(tBox): allGear.append(tBox)
	return allGear

func is_box_damaged(box):
	var iName = box.get_node("Name").text
	if Moves.moveList.has(iName) and Moves.moveList[iName]["slot"] == Moves.equipType.gear and box.currentUses < box.maxUses: return true
	else: return false

func find_box(boxName):
	for iBox in iHolder.get_children():
		if iBox.get_node("Name").text == boxName: return iBox

func xCheck(count = false): #returns an empty inventory space, todo: scenario for full inventory
	var xCount = 0
	for iBox in iHolder.get_children():
		if iBox.visible:
			var iName = iBox.get_node("Name").text
			if iName == "X":
				if count: xCount += 1
				else: return iBox
	return xCount

func clear_box(box):
	dHolder.box_move(box, "X")
	box.set_uses(-1)
	identify_product(box)

func add_multi(items):
	var spaces = xCheck(true)
	if spaces < items.size():
		pass
	else:
		for item in items:
			add_item(item, true)

func add_item(itemName, newUses = false): #todo: case for full inventory
	var openBox = xCheck()
	if openBox: #normal use case
		dHolder.box_move(openBox, itemName)
		identify_product(openBox)
		if newUses: openBox.set_uses(Moves.get_uses(itemName))
		if global.storedParty[0].boxHolder != null: reset_and_update_itemDict()
		return openBox
	else: #full inventory
		pass #owned lol
		#activate_offer(itemName)

func remove_component(componentName): #some redundancy with xCheck
	for iBox in iHolder.get_children():
		if iBox.get_node("Name").text == componentName:
			clear_box(iBox)
			return true
	if tHolder.visible: for tBox in tHolder.get_children():
		if tBox.get_node("Name").text == componentName:
			clear_box(tBox)
			assess_trade_value()
			return true
	return false

func update_itemDict(itemName):
	currentInvSize += 1
	if currentInvSize > XMAX * YMAX: 
		print("inventory overflow")
	else:
		if global.itemDict.has(itemName): #it's a component
			global.itemDict[itemName] += 1
		else: #it's a move and goes in the holder
			global.itemDict[MOVEHOLDER].append(itemName)

func get_component_count():
	var total = 0
	for item in global.itemDict:
		if item != "moves": #components only
			if global.itemDict[item] >= 1:
				total += global.itemDict[item]
	return total

func check_and_award_component(box, flip = false):
	#if get_component_count() <= 1: #potential balance fix that prevents component hoarding
	if flip: add_item(Crafting.break_down(box.moves[0])[1])
	else: add_item(Crafting.break_down(box.moves[0])[0])

func exit(): #Save trader inventory and leave
	deselect_multi([otherSelection])
	var tStock = []
	for box in tHolder.get_children():
		tStock.append(box.get_node("Name").text)
	get_node("../Map").activePoint.traderStock = tStock
	reset_and_update_itemDict()
	done()

func assess_unit_passives(i):
	var unit = global.storedParty[i]
	unit.startingStrength = 0
	unit.baseHealing = 0
	unit.moves.clear()
	unit.passives.clear()
	unit.discounts.clear()
	for box in dHolder.get_child(i).get_node("MoveBoxes").get_children(): #Accessing the moveboxes
		var moveName = box.get_node("Name").text
		var moveData = Moves.moveList[moveName]
		var checkType = moveData["type"]
		var checkSlot = moveData["type"]
		if checkSlot != Moves.equipType.relic and checkType != Moves.moveType.basic:
			unit.moves.append(moveName)
		if moveData.has("passive"):
			unit.passives[moveData["passive"][0]] = moveData["passive"][1]
		if moveData.has("discount"):
			unit.set_discount(moveData["discount"])
		if moveData.has("strength"):
			unit.startingStrength += moveData["strength"]
		if moveData.has("healing"):
			unit.baseHealing += moveData["healing"]

func reset_and_update_itemDict():
	for item in global.itemDict:
		global.itemDict[item] = 0
	global.itemDict[MOVEHOLDER] = [] #Redoing the moveholder with potential new moves
	currentInvSize = 0
	for iBox in iHolder.get_children():
		var iName = iBox.get_node("Name").text
		if iName == "X": continue #do not want to do anything with the Xs
		update_itemDict(iName)
	get_node("../Map").set_quick_panels()

func done():
	if !get_parent().mapMode:
		return get_tree().reload_current_scene()
	else:
		for i in global.storedParty.size():
			dHolder.manage_and_color_boxes(global.storedParty[i])
		toggle_trade_visibility(false)
		get_node("../Map").check_delay()

func reset_trade():
	return get_tree().reload_current_scene()

