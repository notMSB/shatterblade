extends Node2D

export (PackedScene) var BoonSelect
onready var Map = get_node("../../../")
onready var Boons = Map.Boons
onready var Moves = Map.Moves
onready var Inventory = Map.inventoryWindow

const MAXLEVEL = 1

const XSTART = -250
const INCREMENT = 500
const YSTART = 50

func setup():
	var vBoons = Boons.get_virtue_boons()
	for i in vBoons.size():
		var newSelect = BoonSelect.instance()
		var boonName = vBoons[i]
		$Holder.add_child(newSelect)
		newSelect.name = boonName
		newSelect.get_node("Button").text = boonName
		get_price(newSelect, boonName)
		newSelect.position.x = XSTART + (i * INCREMENT)
		newSelect.position.y = YSTART

func find_node_and_price(boonName):
	for select in $Holder.get_children():
		if select.name == boonName:
			get_price(select, boonName)

func get_price(selectNode, boonName):
	var level = Boons.get_level(boonName)
	if level == MAXLEVEL:
		selectNode.get_node("Price").text = "Max"
		selectNode.clickCost = null
	else:
		selectNode.clickCost = Boons.boonList[boonName]["costs"][level + 1]
	if selectNode.clickCost: selectNode.get_node("Price").text = String(selectNode.clickCost)

func offer_made(box):
	if !Inventory.check_for_curses([box.get_node("Name").text]): #if the offer is not cursed
		Boons.grant_favor(int(box.get_node("Info").text))
	else: #give it back
		Inventory.activate_offer(box.get_node("Name").text)

func enter():
	visible = true
	Map.currentTemple = self

func select_pressed(boonSelect):
	var boonName = boonSelect.name
	var upgrade = false
	if boonSelect.clickCost and Boons.favor >= boonSelect.clickCost:
		Boons.grant_favor(-1 * boonSelect.clickCost)
		for i in Boons.playerBoons.size():
			if Boons.playerBoons[i] == boonName:
				Boons.get_node(boonName).level += 1
				Boons.call_specific("level_up", [Map.inventoryWindow], boonName)
				upgrade = true
		if !upgrade:
			Boons.create_boon(boonName)
			Boons.call_specific("added_boon", [Map.inventoryWindow], boonName)
		get_price(boonSelect, boonName)
		Map.set_boon_text()

func _on_HealButton_pressed():
	for unit in global.storedParty:
		if unit.currentHealth < unit.maxHealth and Boons.favor > 0:
			unit.heal(1)
			Boons.grant_favor(-1)

func _on_OfferButton_pressed():
	Inventory.activate_offer()

func _on_ExitButton_pressed():
	visible = false
	Map.currentTemple = null
