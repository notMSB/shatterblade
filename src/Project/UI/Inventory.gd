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

var productBox
var otherSelection #Used to sync a selection across all non-inventory box holders

var boxesCount = Vector2(0,0)

func _ready():
	if global.itemDict.empty():
		global.itemDict = {"fang": 1, "wing": 2, "talon": 9, "sap": 7, "venom": 2, "fur": 3, "blade": 4, "bone": 2, "wood": 1, "moves": []}
	make_grid()
	make_craftboxes()
	if global.storedParty.size() > 0: 
		for i in global.storedParty.size():
			while global.storedParty[i].moves.size() < MOVESPACES:
				global.storedParty[i].moves.append("X")
			$HolderHolder/DisplayHolder.setup_player(global.storedParty[i], i)
		for display in $HolderHolder/DisplayHolder.get_children():
			display.get_node("Name").text = $Moves.get_classname(global.storedParty[display.get_index()].allowedType)
			for box in display.get_node("MoveBoxes").get_children():
				identify_product(box)

func make_grid():
	for item in global.itemDict:
		if item == MOVEHOLDER:
			for move in global.itemDict[MOVEHOLDER]:
				identify_product(make_inventorybox(move))
		else:
			make_inventorybox(item)
	while YMAX > boxesCount.y: #fill out the rest of the grid
		make_inventorybox("X")

func make_inventorybox(boxName):
	var box = ItemBox.instance()
	iHolder.add_child(box)
	box.position.x = XSTART + (boxesCount.x * XINCREMENT)
	box.position.y = YSTART + (boxesCount.y * YINCREMENT)
	box.get_node("Name").text = boxName
	if global.itemDict.has(boxName): box.get_node("Info").text = String(global.itemDict[boxName])
	else: box.get_node("Info").text = ""
	incrementBoxCount()
	return box
	
func incrementBoxCount():
	boxesCount.x += 1
	if boxesCount.x >= XMAX:
		boxesCount.x = 0
		boxesCount.y +=1

func make_craftboxes():
	var box
	for i in CRAFTBOXES:
		box = ItemBox.instance()
		cHolder.add_child(box)
		box.position.x = XSTART*1.25 + (i*i*XINCREMENT)
		box.position.y = YSTART*2.5
		box.get_node("Info").visible = false
		if i == CRAFTBOXES - 1:
			box.get_node("Button").visible = false
			productBox = box
	
func select_box(box = null):
	if box.moveType != $Moves.moveType.basic:
		var boxParent = box.get_parent()
		deselect_box(boxParent.selectedBox)
		box.get_parent().selectedBox = box
		if boxParent != iHolder: otherSelection = box
		box.get_node("ColorRect").color = Color(.5,.1,.5,1)
		check_crafts()
	
func deselect_box(box):
	if box: 
		identify_product(box)
		box.get_parent().selectedBox = null
		if otherSelection: otherSelection = null #if the box and the otherselection are the same they should both be nulled out
	elif otherSelection: #if the otherselection is not in the same region as the box
		identify_product(otherSelection)
		otherSelection.get_parent().selectedBox = null
	
func check_crafts():
	if iHolder.selectedBox and otherSelection: #if both sections have a selection
		var iName = iHolder.selectedBox.get_node("Name").text
		if otherSelection.get_parent() == cHolder: #craft
			deselect_box(iHolder.selectedBox) #going to happen no matter what, even if component is valid
			if $Crafting.c.get(iName) == null: 
				deselect_box(otherSelection)
				return #stop if component is not valid, need to specifically check null as c[0] shows as false
			cHolder.selectedBox.get_node("Name").text = iName #if component is valid, put it in the craftbox
			deselect_box(cHolder.selectedBox) #now that the name is in, the craftbox can be deselected
			
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
		else: #move into inventory
			if $Crafting.c.get(iName) == null: #Can only swap in actual moves, skip if it's a component
				var playerType = global.storedParty[otherSelection.get_node("../../").get_index()].allowedType
				#If the types match, allow the swap. None case is for putting a move back in inventory with no swap
				if $Moves.moveList[iName]["type"] == playerType or $Moves.moveList[iName]["type"] == $Moves.moveType.none: 
					var oName = otherSelection.get_node("Name").text
					iHolder.selectedBox.get_node("Name").text = oName
					otherSelection.get_node("Name").text = iName 
				deselect_box(otherSelection)
				deselect_box(iHolder.selectedBox)
				

func identify_product(box):
	var boxName = box.get_node("Name").text
	if $Moves.moveList.has(boxName):
		var productType = $Moves.moveList[boxName]["type"]
		box.moveType = productType
		if productType == $Moves.moveType.special: box.get_node("ColorRect").color = Color(.9,.3,.3,1) #R
		elif productType == $Moves.moveType.trick: box.get_node("ColorRect").color = Color(.3,.7,.3,1) #G
		elif productType == $Moves.moveType.magic: box.get_node("ColorRect").color = Color(.3,.3,.9,1) #B
		else: box.get_node("ColorRect").color = DEFAULTCOLOR
	else: box.get_node("ColorRect").color = DEFAULTCOLOR


func confirm_craft(): #Subtract one from each ingredient from inventory and put in the new product
	var one
	var two
	var iTasks = 0
	var putProduct = false
	for cBox in cHolder.get_children():
		if cBox.get_node("Button").visible: #Button is only visible on the non-result boxes
			if !one: one = cBox.get_node("Name").text
			else: two = cBox.get_node("Name").text
		else: #this will only run once, as the last part of the original loop
			cBox.get_node("ColorRect").color = DEFAULTCOLOR
			var iName
			for iBox in iHolder.get_children():
				iName = iBox.get_node("Name").text
				if iName == one or iName == two:
					global.itemDict[iName] -= 1 #item used
					if one == two: #gotta do it twice if it's merged with itself
						global.itemDict[iName] -= 1
						iTasks += 1
					if global.itemDict[iName] > 0:
						iBox.get_node("Info").text = String(global.itemDict[iName])
					else: #all out
						iBox.get_node("Name").text = "X"
						iBox.get_node("Info").text = ""
						global.itemDict.erase(iName)
					iTasks += 1
				elif iName == "X" and !putProduct: #Find empty space in inventory
					iBox.get_node("Name").text = cBox.get_node("Name").text #Put product in there
					identify_product(iBox)
					putProduct = true #do not put the product multiple times
				if iTasks >= 2 and putProduct: break #all done
		cBox.get_node("Name").text = "X"
	$CraftButton.visible = false

func exit():
	for i in global.storedParty.size():
		global.storedParty[i].moves.clear()
		for box in $HolderHolder/DisplayHolder.get_child(i).get_node("MoveBoxes").get_children(): #Just accessing the moveboxes
			var moveName = box.get_node("Name").text
			if $Moves.moveList[moveName]["type"] > $Moves.moveType.basic:
				 global.storedParty[i].moves.append(moveName)
	global.itemDict[MOVEHOLDER].clear() #Redoing the moveholder with potential new moves
	for iBox in iHolder.get_children():
		var iName = iBox.get_node("Name").text
		if iName == "X": continue #do not want to do anything with the Xs
		if !global.itemDict.has(iName): #it's a move and goes in the holder
			global.itemDict[MOVEHOLDER].append(iName)
	return get_tree().change_scene("res://src/Project/Debug.tscn")




