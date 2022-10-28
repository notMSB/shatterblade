extends "res://src/Project/Units/Unit.gd"

var maxAP = 100
var energy = 6
var maxEnergy = 6
var mana = 120
var maxMana = 120
var boxHolder

var allowedType
var types
var title
var discounts = {} #probably only works with reload for now

func _ready():
	isPlayer = true
	types = Battle.Moves.moveType

func update_resource(resValue, type, isGain: bool):
	if type == types.special:
		if isGain: ap = min(ap + resValue, maxap)
		else: ap -= resValue
	elif type == types.magic:
		if isGain: mana = min(mana + resValue, maxMana)
		else: mana -= resValue
	elif type == types.trick:
		if isGain: energy = min(energy + resValue, maxEnergy)
		else: energy -= resValue
	#else: #unused
	update_box_bars()

func update_box_bars(): #this one needs a refactor at some point
	for box in boxHolder.get_children():
		if !box.trackerBar: continue
		if allowedType == types.special:
			box.trackerBar.value = ap
			box.trackerBar.get_child(0).text = str(ap, "/", maxAP)
		elif allowedType == types.magic:
			box.trackerBar.value = mana
			box.trackerBar.get_child(0).text = str(mana, "/", maxMana)
		elif allowedType == types.trick:
			box.trackerBar.value = energy
			box.trackerBar.get_child(0).text = str(energy, "/", maxEnergy)
		else: #unused
			#box.trackerBar.value = charges[box.resValue]
			#box.trackerBar.get_child(0).text = str(charges[box.resValue], "/", maxCharges[box.resValue])
			pass

func set_discount(discounts2D):
	for discountArray in discounts2D:
		var discountedMove = discountArray[0]
		var discountAmount = discountArray[1]
		if discounts.has(discountedMove):
			discounts[discountedMove] += discountAmount
		else:
			discounts[discountedMove] = discountAmount

func apply_discount(move):
	if discounts.has(move):
		return discounts[move]
	return 0

func update_bar(bar, value, limit):
	bar.get_child(0).text = str(value, "/", limit)
