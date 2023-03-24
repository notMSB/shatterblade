extends Node2D

export (PackedScene) var BoonSelect
onready var Map = get_node("../../../")
onready var Boons = Map.Boons
onready var Moves = Map.Moves
onready var Inventory = Map.inventoryWindow

const XSTART = -175
const INCREMENT = 150
const YSTART = 50

func setup():
	var vBoons = Boons.get_virtue_boons()
	var ownedBoons = 0
	var newBoons = 0
	for i in vBoons.size():
		var newSelect = BoonSelect.instance()
		var boonName = vBoons[i]
		$Holder.add_child(newSelect)
		newSelect.name = boonName
		newSelect.get_node("Button").text = boonName
		get_price(newSelect, boonName)
		if newSelect.clickCost == Boons.boonList[boonName]["costs"][0]:
			if Boons.playerBoons.size() >= 3:
				newSelect.visible = false
			else:
				newSelect.position.x = XSTART + (newBoons * INCREMENT)
				newSelect.position.y = YSTART
				newBoons += 1
		else:
			newSelect.position.x = XSTART + (ownedBoons * INCREMENT)
			newSelect.position.y = YSTART + 100
			ownedBoons += 1
		newSelect.set_tooltip(Boons.generate_tooltip(boonName))

func find_node_and_price(boonName):
	for select in $Holder.get_children():
		if select.name == boonName:
			get_price(select, boonName)

func get_price(selectNode, boonName):
	var level = Boons.get_level(boonName)
	var costVal = 0
	if level != null: 
		if level[0] and level[1]: costVal = null
		else:
			if level[0]: costVal = 2
			elif level[1]: costVal = 1
			else: #random upgrade
				selectNode.offeredUpgrade = randi() % 2
				costVal = selectNode.offeredUpgrade + 1
			if costVal == 1: selectNode.get_node("Button").modulate = Color.silver
			else: selectNode.get_node("Button").modulate = Color.gold
	if costVal == null: 
		selectNode.get_node("Button").modulate = Color.paleturquoise
		disable_select(selectNode)
	else:
		if Map.get_parent().hardMode:
			selectNode.clickCost = Boons.boonList[boonName]["hardCosts"][costVal]
		else:
			selectNode.clickCost = Boons.boonList[boonName]["costs"][costVal]
	if selectNode.clickCost: selectNode.get_node("Price").text = String(selectNode.clickCost)

func offer_made(box):
	if Inventory.check_for_curses([box.get_node("Name").text]): #if the offer is not cursed
		Boons.grant_favor(int(box.get_node("Info").text) * 3)
		Inventory.clear_box(box)
	else:
		pass

func enter():
	visible = true
	Map.currentTemple = self

func disable_select(boonSelect):
	boonSelect.get_node("Button").disabled = true
	boonSelect.get_node("Price").visible = false

func select_pressed(boonSelect):
	var boonName = boonSelect.name
	var upgrade = false
	if boonSelect.clickCost and Boons.favor >= boonSelect.clickCost:
		disable_select(boonSelect)
		Boons.grant_favor(-1 * boonSelect.clickCost)
		for i in Boons.playerBoons.size():
			if Boons.playerBoons[i] == boonName:
				Boons.get_node(boonName).level[boonSelect.offeredUpgrade] = true
				Boons.call_specific("level_up", [Map.inventoryWindow, boonSelect.offeredUpgrade], boonName)
				Map.recolor_boon_ui(i)
				upgrade = true
		if !upgrade:
			Boons.create_boon(boonName)
			Boons.call_specific("added_boon", [Map.inventoryWindow], boonName)
			Map.set_boon_text()
		get_price(boonSelect, boonName)
		if Boons.playerBoons.size() >= 3:
				for select in $Holder.get_children():
					var selectName = select.get_node("Button").text
					if select.clickCost == Boons.boonList[selectName]["costs"][0]:
						select.visible = false

func _on_HealButton_pressed():
	for unit in global.storedParty:
		if unit.currentHealth < unit.maxHealth and Boons.favor > 0:
			unit.heal(1)
			Boons.grant_favor(-1)

func _on_OfferButton_pressed():
	offer_made($Templebox)

func _on_ExitButton_pressed():
	visible = false
	Map.currentTemple = null
	if $Templebox/Name.text != "X":
		Inventory.swap_boxes($Templebox, Inventory.xCheck())
