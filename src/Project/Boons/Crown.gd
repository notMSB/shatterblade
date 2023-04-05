extends Node

var Boons

const REWARD = 5
var level = [false, false]

func prep_inventory():
	global.itemDict["moves"].append("Crown")

func added_boon(invNode):
	invNode.add_item("Crown", true)

func level_up(invNode, upgradeIndex): #find the crown and upgrade it
	if upgradeIndex == 0:
		for i in global.storedParty.size():
			var boxHolder = invNode.dHolder.get_child(i).get_node("MoveBoxes")
			for box in boxHolder.get_children():
				if box.get_node("Name").text == "Crown": invNode.dHolder.box_move(box, "Crown+")
		for iBox in invNode.iHolder.get_children():
			var iName = iBox.get_node("Name").text
			if iName == "Crown": invNode.dHolder.box_move(iBox, "Crown+")
	else:
		if level[0]:invNode.add_item("Crown+", true)
		else: invNode.add_item("Crown", true)

func check_hit(usedBox, targetHealth, _moveUser, real, _battle):
	if usedBox != null and real:
		if targetHealth <= 0 and (usedBox.moves[0] == "Crown" or usedBox.moves[0] == "Crown+"):
			#print("cool")
			Boons.grant_favor(REWARD)
