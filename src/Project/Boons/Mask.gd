extends Node

var Boons

const REWARD = 5
var level = 0

func start_battle(_startingHealth, battle):
	battle.enemyBonus = true

func before_move(moveUser, _usedMoveBox, _real, moveTarget, battle):
	if level >= 1 and  moveUser.maxHealth < moveTarget.currentHealth:
		battle.damageBuff += 3

func bar_filled():
	Boons.grant_favor(REWARD)
