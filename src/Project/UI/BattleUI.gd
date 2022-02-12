extends Node2D

export (PackedScene) var UnitUI
export (PackedScene) var UnitOrder

const UNITXSTART = 100
const UNITYSTART = 50
const POINTERSTART = 10

const XINCREMENT = 250
const YINCREMENT = 105

const ORDERYSTART = 10
const ORDERXSTART = 350
const ORDERXINCREMENT = 50

onready var Battle = get_parent()
onready var Moves = get_node("../Moves")

var targetsVisible = false

var playerCount = 0
var enemyCount = 0

func move_pointer(index):
	$Pointer.margin_left = POINTERSTART + ORDERXSTART + ORDERXINCREMENT * index
	
func setup_display(unit, index):
	var display = UnitUI.instance()
	display.get_node("Name").text = unit.name
	display.get_node("HP").text = String(unit.currentHealth)
	if unit.shield > 0:
		display.get_node("HP").text += "[" + String(unit.shield) + "]"
	display.get_node("Stats").text = String(unit.strength) + "/" + String(unit.defense) + "/" + String(unit.speed)
	
	if !unit.isPlayer:
		display.get_node("Sprite").visible = true
		var spritePath = str("res://src/Assets/Enemies/", unit.identity, ".png")
		var tempFile = File.new()
		if(tempFile.file_exists(spritePath)):
			display.get_node("Sprite").texture = load(spritePath)
	
	if unit.isPlayer:
		display.position.x = UNITXSTART + 3 * XINCREMENT
		display.position.y = UNITYSTART + YINCREMENT * playerCount
		playerCount += 1
	else:
		if enemyCount % 2 == 0:
			display.position.x = UNITXSTART
		else:
			display.position.x = UNITXSTART + XINCREMENT
		display.position.y = UNITYSTART + YINCREMENT * enemyCount
		enemyCount += 1
	
	$ColorRect.add_child(display)
	unit.ui = display
	
	
	var orderDisplay = UnitOrder.instance()
	orderDisplay.get_node("Name").text = unit.name
	$Order.add_child(orderDisplay)
	orderDisplay.position.x = ORDERXSTART + index * ORDERXINCREMENT
	orderDisplay.position.y = ORDERYSTART

func open_commands():
	$CommandList.add_item("Attack")
	$CommandList.add_item("Defend")
	$CommandList.add_item("Special")
	#$CommandList.add_item("Magic")
	#$CommandList.add_item("Item")

func open_submenu(menu):
	$Submenu.clear()
	var list = []
	if menu == "Special": 
		list = Battle.currentUnit.specials
		Battle.menuNode = get_node("../Moves")
	elif menu == "Item": 
		list = Battle.currentUnit.items
		Battle.menuNode = get_node("../Items")
	elif menu == "Magic": 
		list = Battle.currentUnit.spells
		Battle.menuNode = get_node("../Magic")
	for entry in list:
		$Submenu.add_item(entry)

func clear_menus():
	$CommandList.clear()
	$Submenu.clear()
	$Description.text = ""

func toggle_buttons(toggle, units = []):
	for child in $ColorRect.get_children():
			child.get_node("Button").visible = false
	if toggle:
		for unit in units:
			$ColorRect.get_child(unit.get_index()).get_node("Button").visible = toggle
		targetsVisible = true

func set_description(moveName, move):
	var desc = moveName
	if Battle.menuNode == get_node("../Items"): desc += " x" + String(Battle.currentUnit.items[moveName])
	if move["target"] == Battle.targetType.enemy: desc += "\n" + "Single Enemy"
	elif move["target"] == Battle.targetType.enemies: desc += "\n" + "All Enemies"
	elif move["target"] == Battle.targetType.enemyTargets: desc += "\n" + "Same Target Enemies"
	elif move["target"] == Battle.targetType.ally: desc += "\n" + "Single Ally"
	elif move["target"] == Battle.targetType.allies: desc += "\n" + "All Allies"
	elif move["target"] == Battle.targetType.user: desc += "\n" + "Self"
	if move.has("quick"): desc += "\n Quick Action "
	if move.has("cost"): desc += "\n Cost: " + String(move["cost"])
	if move.has("damage"): desc += "\n Base Damage: " + String(move["damage"]) + " + " + String(Battle.currentUnit.strength)
	if move.has("healing"): desc += "\n Healing: " + String(move["healing"])
	if move.has("hits"): desc += "\n Repeats: " + String(move["hits"])
	if move.has("level"): desc += "\n Level: " + String(move["level"]) + " / Charges: " + String(Battle.currentUnit.charges[move["level"]])
	if move.has("status"):
		desc += "\n Status: " + move["status"]
		if move.has("value"): desc += " " + String(move["value"])
	if move.has("description"): desc += "\n " + String(move["description"])
	$Description.text = desc

func _on_CommandList_item_activated(index):
	if index > 1:
		open_submenu($CommandList.get_item_text(index))
	else: #Attack/Defend
		Battle.menuNode = get_node("../Moves")
		Battle.evaluate_targets($CommandList.get_item_text(index), Battle.currentUnit)

func _on_Submenu_item_activated(index):
	Battle.evaluate_targets($Submenu.get_item_text(index), Battle.currentUnit)
