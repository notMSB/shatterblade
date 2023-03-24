extends Node

var Boons

const REWARD = 5
var level = [false, false]

var doubleUsed = false

func start_battle(_startingHealth, battle):
	battle.enemyBonus = true
	doubleUsed = false

func before_move(moveUser, _usedMoveBox, _real, moveTarget, battle):
	if level[0] and  moveUser.maxHealth < moveTarget.currentHealth:
		battle.damageBuff += 3

func check_hit(_usedBox, targetHealth, _moveUser, _real, battle):
	if level[1] and !doubleUsed and targetHealth <= 0:
		battle.doubleXP = true
		doubleUsed = true

func bar_filled():
	Boons.grant_favor(REWARD)
