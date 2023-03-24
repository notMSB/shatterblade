extends Node2D

const DEFAULTUSESDAMAGE = 6
const DEFAULTUSESOTHER = 8

var Battle
var moveList
enum rarities {unobtainable, rare, uncommon, common}
enum timings {before, after}
enum moveType {none, basic, item, special, magic, trick}
enum equipType {any, none, relic, gear}
enum targetType {enemy, enemies, enemyTargets, ally, allies, user, everyone, none}
enum statBoosts {health, resource}

func _ready():
	moveList = {
	"Attack": {"target": targetType.enemy, "damage": 4, "resVal": 0, "slot": equipType.relic, "type": moveType.basic},
	"Defend": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 6], "description": "Shields 6", "slot": equipType.relic, "type": moveType.basic},
	
	"Earthshaker": {"target": targetType.enemies, "damage": 10, "resVal": 60, "status": "Stun", "value": 1, "type": 1},
	"Special Boy": {"target": targetType.enemy, "damage": 5, "resVal": 50, "hits": "moveUser:specials", "description": "One hit for every known special", "type": 1},
	
	
	"Careful Strike": {"target": targetType.enemy, "damage": 8, "resVal": 20, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 5], "timing": timings.before, "description": "Shields 5 before attacking.", "slot": equipType.gear, "type": moveType.special},
	"Cleave": {"target": targetType.enemies, "damage": 9, "resVal": 30, "slot": equipType.gear, "type": moveType.special},
	"Dive Bomb": {"target": targetType.enemy, "damage": 16, "resVal": 15, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .2], "description": "20% recoil", "slot": equipType.gear, "type": moveType.special},
	"Pierce": {"target": targetType.enemyTargets, "damage": 10, "resVal": 15, "slot": equipType.gear, "type": moveType.special},
	"Poison Strike": {"target": targetType.enemy, "damage": 1, "resVal": 15, "status": "Poison", "value": 5, "quick": true, "slot": equipType.gear, "type": moveType.special},
	"Power Attack": {"target": targetType.enemy, "damage": 13, "resVal": 20, "slot": equipType.gear, "type": moveType.special},
	"Take Down": {"target": targetType.enemy, "damage": 7, "resVal": 30, "status": "Stun", "value": 1, "slot": equipType.gear, "type": moveType.special},
	"Triple Hit": {"target": targetType.enemy, "damage": 3, "resVal": 20, "hits": 3, "slot": equipType.gear, "type": moveType.special},
	"Vampire": {"target": targetType.enemy, "damage": 8, "resVal": 15, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", -.25], "description": "25% lifesteal", "slot": equipType.gear, "type": moveType.special},
	"Tasty Bite": {"target": targetType.enemy, "damage": 5, "resVal": 10, "status": "Poison", "value": 5, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "give_status"), "args": ["moveUser", "Poison", 5]},
	"Bone Club": {"target": targetType.enemy, "damage": 30, "resVal": 20, "slot": equipType.gear, "type": moveType.special, "charge": true, "channel": true ,"cycle": ["Charge"]},
	"Feeding Frenzy": {"target": targetType.enemy, "damage": 8, "resVal": 15, "timing": timings.before, "effect": funcref(self, "hits_for_hp_percentage"), "args": ["moveTarget", .01, 1, 1], "description": "Extra hit if enemy is damaged.", "slot": equipType.gear, "type": moveType.special},
	"Breaker Slash": {"target": targetType.enemy, "damage": 9, "resVal": 20, "timing": timings.before, "effect": funcref(self, "hits_for_durability"), "args": ["usedMoveBox", .5, 1], "description": "Extra hit if this weapon is at half or less uses", "slot": equipType.gear, "type": moveType.special},
	"Dark Dive": {"target": targetType.enemy, "damage": 12, "resVal": 15, "timing": timings.before, "effect": funcref(self, "hits_for_hp_percentage"), "args": ["moveUser", .75, 1], "secondEffect": funcref(self, "take_recoil"), "secondArgs": ["moveUser", "damageCalc", .30], "description": "Extra hit if user is below 25% HP. 30% recoil.", "slot": equipType.gear, "type": moveType.special},
	"Grapple": {"target": targetType.enemy, "damage": 4, "resVal": 15, "status": "Stun", "value": 2, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "give_status"), "args": ["moveUser", "Stun", 2], "description": "Stuns both the user and the target."},
	"Deep Cut": {"target": targetType.enemyTargets, "damage": 14, "resVal": 25, "slot": equipType.gear, "type": moveType.special, "charge": true, "cycle": ["Charge"]},
	"Meat Harvest": {"target": targetType.enemy, "damage": 6, "resVal": 2, "timing": timings.before, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "damage_amp"), "args": ["moveUser:currentHealth", .5], "secondEffect": funcref(self, "take_recoil"), "secondArgs": ["moveUser", "damageCalc", .50], "description": "Damage increased by 50% current health. 50% Recoil."},
	"Monument": {"target": targetType.enemy, "damage": 8, "resVal": 30, "status": "Burn", "value": 8, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "taunt_burns"), "args": ["moveUser"], "charge": true, "cycle": ["Quick Charge"], "description": "All burned enemies target the user."},
	
	"Flex": {"target": targetType.user, "resVal": 25, "status": "Double Damage", "value": 1, "quick": true, "slot": equipType.gear, "type": moveType.special},
	"Protect": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "switch_intents"), "args": ["moveTarget", "moveUser"], "quick": true, "slot": equipType.gear, "type": moveType.special, "description": "Enemy attacks intended for target change to user"},
	"Turtle Up": {"target": targetType.user, "resVal": 15, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 6, funcref(self, "get_enemy_targeters")], "description": "Shields 6 for each enemy targeting the user", "slot": equipType.gear, "type": moveType.special},
	"Goblin Dodge": {"target": targetType.enemies, "resVal": 15, "quick": true, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "taunt"), "args": [], "description": "All enemies target the user"},
	"Spit Shine": {"target": targetType.ally, "resVal": 5, "healing": 6, "slot": equipType.gear, "type": moveType.special, "quick": true, "status": "Poison", "value": 5},
	"Bulwark": {"target": targetType.ally, "resVal": 15, "slot": equipType.gear, "type": moveType.special, "effect": funcref(self, "change_attribute"), "args": ["moveTarget", "shield", 15], "charge": true, "cycle": ["Quick Charge"], "description": "Shield an ally 15."},
	
	"Charge": {"target": targetType.none, "resVal": 10, "cycle": true, "slot": equipType.none, "type": moveType.special},
	"Quick Charge": {"target": targetType.none, "resVal": 20, "cycle": true, "slot": equipType.none, "type": moveType.special},
	
	"Constrict": {"target": targetType.enemy, "damage": 5, "resVal": 15, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Stun", funcref(self, "is_unit_poisoned")], "description": "Stuns target if they are poisoned", "slot": equipType.gear, "type": moveType.magic},
	"Frostfang": {"target": targetType.enemy, "damage": 5, "resVal": 20, "status": "Chill", "value": 5, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", .5, true], "description": "Multiplies target chill by 1.5 after the hit", "slot": equipType.gear, "type": moveType.magic},
	"Plague": {"target": targetType.enemies, "damaging": true, "resVal": 30, "status": "Poison", "value": 5, "slot": equipType.gear, "type": moveType.magic, "uses": 6},
	"Venoshock": {"target": targetType.enemy, "damaging": true, "resVal": 15, "status": "Poison", "value": 6, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", funcref(self, "get_unit_poison")],"description": "Shield 1 for every poison that enemy has.", "slot": equipType.gear, "type": moveType.magic},
	"Belch": {"target": targetType.enemy, "resVal": 20, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Poison", funcref(self, "get_unit_poison")], "description": "Poisons enemy as much as the user is poisoned", "slot": equipType.gear, "type": moveType.magic},
	"Mass Infection": {"target": targetType.everyone, "damaging": true, "resVal": 30, "status": "Poison", "value": 10, "slot": equipType.gear, "type": moveType.magic, "uses": 6, "condition": funcref(self, "is_damaged"), "description": "Only affects damaged enemies."},
	"Dark Spikes": {"target": targetType.enemy, "damage": 6, "resVal": 20, "barrage": true, "hits": 3, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", 1], "killeffect": funcref(self, "change_attribute"), "killargs": ["moveUser", "shield", 12], "description": "12 shield on kill, 100% recoil", "slot": equipType.gear, "type": moveType.magic},
	"Seeker Volley": {"target": targetType.enemy, "damage": 3, "resVal": 20, "barrage": true, "hits": 4, "slot": equipType.gear, "type": moveType.magic, "condition": funcref(self, "is_damaged"), "description": "Followup hits only bounce to damaged enemies."},
	"Soul Sample": {"target": targetType.enemy, "damage": 2, "resVal": 15, "slot": equipType.gear, "type": moveType.magic, "hits": 4, "barrage": true, "killeffect": funcref(self, "heal_team"), "killargs": ["moveUser", 5]},
	"Fireball": {"target": targetType.enemies, "damage": 6, "resVal": 30, "slot": equipType.gear, "type": moveType.magic, "status": "Burn", "value": 6},
	"Combust": {"target": targetType.enemy, "damage": 6, "resVal": 20, "slot": equipType.gear, "type": moveType.magic, "effect": funcref(self, "status_to_damage"), "args": ["moveTarget", "Burn"], "description": "Consumes enemy burn as additional damage."},
	
	"Dodge": {"target": targetType.ally, "resVal": 20, "status": "Dodgy", "value": 1, "slot": equipType.gear, "type": moveType.magic},
	"Growth": {"target": targetType.ally, "resVal": 10, "effect": funcref(self, "change_attribute"), "args": ["moveTarget", "strength", 3], "description": "Ally strength +3", "slot": equipType.gear, "type": moveType.magic, "uselimit": 1},
	"Hide": {"target": targetType.ally, "resVal": 5, "effect": funcref(self, "switch_intents"), "args": ["moveUser", "moveTarget"], "slot": equipType.gear, "type": moveType.magic, "quick": true, "description": "Enemy attacks intended for user change to target"},
	"Restore": {"target": targetType.ally, "resVal": 5, "healing": 5, "slot": equipType.gear, "type": moveType.magic, "quick": true, "mapUsable": true},
	"Invisibility": {"target": targetType.ally, "resVal": 15, "status": "Stealth", "value": 2, "slot": equipType.gear, "type": moveType.magic, "quick": true},
	"Midnight Flare": {"target": targetType.none, "resVal": 15, "quick": true, "slot": equipType.gear, "type": moveType.magic, "effect": funcref(self, "midnight_flare"), "args": ["moveUser"], "description": "All enemies target the lowest health ally."},
	"Defensive Pact": {"target": targetType.ally, "resVal": 10, "damage": 5 ,"effect": funcref(self, "change_attribute"), "args": ["moveTarget", "shield", 15], "description": "Adds 15 shield", "slot": equipType.gear, "type": moveType.magic},
	"Cold Spring": {"target": targetType.allies, "healing": 6, "resVal": 25, "slot": equipType.gear, "type": moveType.magic, "status": "Chill", "value": 10},
	"Submersion": {"target": targetType.everyone, "resVal": 25, "status": "Chill", "value": 10, "slot": equipType.gear, "type": moveType.magic},
	"Firewall": {"target": targetType.ally, "resVal": 20, "status": "Firewall", "value": 1, "slot": equipType.gear, "type": moveType.magic, "effect": funcref(self, "change_attribute"), "args": ["moveTarget", "shield", 7], "description": "Shields 7. When shield is damaged, remaining shield is dealt to attacker."},
	"Icarus": {"target": targetType.ally, "resVal": 30, "slot": equipType.gear, "type": moveType.magic, "status": "Icarus", "value": 2, "description": "Target absorbs all damage while Icarus status is active. If it is not active, take all the absorbed damage at turn start."},
	
	"Coldsteel": {"target": targetType.enemy, "damage": 3, "resVal": 3, "hits": 2, "slot": equipType.gear, "type": moveType.trick, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Chill", "damageCalc"], "description": "Each hit inflicts chill equal to total damage dealt."},
	"Crusher Claw": {"target": targetType.enemy, "damage": 8, "resVal": 2, "timing": timings.before, "effect": funcref(self, "crusher_claw"), "args": ["moveTarget", 1], "description": "Extra hit if the target has shields or dodge", "slot": equipType.gear, "type": moveType.trick},
	"Piercing Sting": {"target": targetType.enemy, "damage": 11, "resVal": 4, "status": "Poison", "value": 6, "slot": equipType.gear, "type": moveType.trick},
	"Quick Attack": {"target": targetType.enemy, "damage": 6, "resVal": 3, "quick": true, "slot": equipType.gear, "type": moveType.trick},
	"Sucker Punch": {"target": targetType.enemy, "damage": 7, "resVal": 3, "timing": timings.before, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 1], "description": "Extra hit if enemy targets user", "slot": equipType.gear, "type": moveType.trick},
	"Bonemerang": {"target": targetType.enemy, "damage": 4, "resVal": 2, "quick": true, "cycle": ["Catch"], "slot": equipType.gear, "type": moveType.trick, "description": "Must be caught or else it is lost"},
	"Shiv": {"target": targetType.enemy, "damage": 2, "resVal": 1, "timing": timings.before, "effect": funcref(self, "hits_for_hp_percentage"), "args": ["moveUser", .15, 1], "description": "Extra hit for each 15% user is below max HP", "slot": equipType.gear, "type": moveType.trick},
	"Taste Test": {"target": targetType.enemy, "damage": 5, "resVal": 3, "killeffect": funcref(self, "take_recoil"), "killargs": ["moveUser", "damageCalc", -1], "description": "100% lifesteal on kill", "slot": equipType.gear, "type": moveType.trick},
	"Sideswipe": {"target": targetType.enemy, "damage": 7, "resVal": 3, "timing": timings.before, "hits": 0 ,"effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 1], "secondEffect": funcref(self, "give_status"), "secondArgs": ["moveUser", "Dodgy", 1], "description": "Add hit if target is targeting user. On hit, add 1 Dodge.", "slot": equipType.gear, "type": moveType.trick},
	"Below Blow": {"target": targetType.enemy, "damage": 6, "resVal": 2, "slot": equipType.gear, "type": moveType.trick, "timing": timings.before, "effect": funcref(self, "below_blow"), "args": ["moveUser"], "description": "Gains an extra hit for each enemy NOT targeting the user."},
	"Eldritch Forces": {"target": targetType.enemy, "damage": 11, "resVal": 4, "hits": 4, "barrage": true, "bounceEveryone": true, "slot": equipType.gear, "type": moveType.trick, "description": "Hits bounce to EVERYONE."},
	"Flametongue": {"target": targetType.enemyTargets, "damage": 7, "resVal": 4, "status": "Burn", "value": 5, "type": moveType.trick, "slot": equipType.gear},
	"Brand": {"target": targetType.enemy, "damage": 5, "status": "Burn", "value": 5, "resVal": 3, "slot": equipType.gear, "type": moveType.trick, "effect": funcref(self, "taunt"), "args": [], "description": "Taunts enemy."},
	"Squalorbomb": {"target": targetType.enemy, "damaging": true, "resVal": 4, "slot": equipType.gear, "type": moveType.trick, "status": "Poison", "value": 7, "effect": funcref(self, "give_status"), "args": ["moveTarget", "Burn", 7], "description": "Poisons and burns."},
	
	"Taunt": {"target": targetType.enemy, "resVal": 2, "quick": true, "slot": equipType.gear, "type": moveType.trick, "effect": funcref(self, "taunt"), "args": []},
	"Eye Poke": {"target": targetType.enemy,"resVal": 3, "timing": timings.before, "status": "Stun", "value": 1, "effect": funcref(self, "add_hits"), "args": ["moveTarget:storedTarget", "moveUser", 1], "description": "Inflict stun if enemy is targeting the user.", "slot": equipType.gear, "type": moveType.trick, "quick": true, "hits": 0},
	"Play Dead": {"target": targetType.user, "resVal": 4, "timing": timings.before, "status": "Dodgy", "value": 2, "effect": funcref(self, "hits_for_hp_percentage"), "args": ["moveUser", .25, 1], "description": "2 dodge if at or below 25% HP.", "slot": equipType.gear, "type": moveType.trick, "hits": 0},
	"Back Rake": {"target": targetType.enemy,"resVal": 3, "quick": true, "timing": timings.before, "status": "Stun", "value": 1, "effect": funcref(self, "hits_for_hp_percentage"), "args": ["moveUser", .75, 1], "description": "Inflict stun if user is at 25% HP or less.", "slot": equipType.gear, "type": moveType.trick, "hits": 0},
	"Firedance": {"target": targetType.enemy, "resVal": 2, "slot": equipType.gear, "type": moveType.trick, "quick": true, "status": "Burn", "value": 5, "effect": funcref(self, "give_status"), "args": ["moveUser", "Burn", 5], "description": "Burns both the user and the target."},
	"Wildfire": {"target": targetType.enemy, "resVal": 4, "status": "Burn", "value": 4, "hits": 9, "barrage": true, "bounceEveryone": true, "slot": equipType.gear, "type": moveType.trick, "description": "Hits bounce to EVERYONE."},
	
	"Reload": {"target": targetType.none, "resVal": 2, "cycle": true, "quick": true, "slot": equipType.none, "type": moveType.trick},
	"Catch": {"target": targetType.none, "resVal": 2, "cycle": true, "quick": true, "slot": equipType.none, "type": moveType.trick, "turnlimit": 1, "description": "Use it or lose it."},
	
	"Speed Potion": {"target": targetType.user, "resVal": 0, "effect": funcref(self, "give_status"), "args": ["moveUser", "Dodgy", funcref(self, "get_enemy_targeters")], "description": "Gives 1 dodge for every enemy targeting user", "slot": equipType.gear, "type": moveType.item, "quick": true},
	"Throwing Knife": {"target": targetType.enemy, "damage": 4, "resVal": 0, "slot": equipType.gear, "type": moveType.item, "quick": true},
	"Brass Knuckles": {"target": targetType.enemy, "status": "Stun", "value": 1, "resVal": 0, "slot": equipType.gear, "type": moveType.item},
	"Health Potion": {"target": targetType.ally, "resVal": 0, "healing": 15, "slot": equipType.gear, "type": moveType.item, "mapUsable": true},
	"Poison Potion": {"target": targetType.enemy, "resVal": 0, "status": "Poison", "value": 10, "slot": equipType.gear, "type": moveType.item},
	"Leather Buckler": {"target": targetType.ally, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 12], "description": "Adds 12 shield.", "slot": equipType.gear, "type": moveType.item},
	"Storm of Steel": {"target": targetType.enemy, "damage": 2, "resVal": 0, "slot": equipType.gear, "type": moveType.item, "hits": 10, "barrage": true},
	"Bone Zone": {"target": targetType.user, "resVal": 0, "quick": true ,"effect": funcref(self, "fill_boxes"), "args": ["moveUser", "Bone Attack"], "description": "bones", "slot": equipType.gear, "type": moveType.item, "uses": 2},
	"Bone Attack": {"slot": equipType.none, "resVal": 0 ,"type": moveType.none, "uselimit": 1, "fleeting": true, "target": targetType.enemy, "damage": 7, "quick": true, "uses": 1},
	"Concoction": {"target": targetType.enemies, "damage": 8, "resVal": 0, "effect": funcref(self, "take_recoil"), "args": ["moveUser", "damageCalc", .5], "description": "50% recoil", "slot": equipType.gear, "type": moveType.item},
	"Dark Matter": {"target": targetType.everyone, "damage": 15, "resVal": 0, "slot": equipType.gear, "type": moveType.item},
	"Tentacle Jar": {"target": targetType.enemyTargets, "damage": 8, "status": "Chill", "value": 6, "slot": equipType.gear, "type": moveType.item},
	"Ring of Fire": {"target": targetType.enemy, "damage": 8, "resVal": 0, "hits": 10, "barrage": true, "bounceEveryone": true ,"slot": equipType.gear, "type": moveType.item, "description": "Hits bounce to EVERYONE."},
	
	"Snapshot": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Line Drive"], "target": targetType.enemy, "damage": 2, "quick": true, "cursed": true},
	"Snapshot+": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Line Drive+"], "target": targetType.enemy, "damage": 4, "quick": true, "cursed": true},
	"Line Drive": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Snapshot"], "target": targetType.enemyTargets, "damage": 6, "cursed": true},
	"Line Drive+": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Snapshot+"], "target": targetType.enemyTargets, "damage": 9, "cursed": true},
	"Sidewinder": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Snapshot, Line Drive"], "target": targetType.enemy, "damage": 5, "barrage": true, "hits": 2, "cursed": true},
	"Sidewinder+": {"slot": equipType.none, "type": moveType.none, "resVal": 0, "uselimit": 1, "cycle": ["Snapshot+, Line Drive+"], "target": targetType.enemy, "damage": 7, "barrage": true, "hits": 3, "cursed": true},
	
	"Health Seed": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true, "price": 6, "mapUsable": true, "statBoost": statBoosts.health, "uses": 1, "obtainable": true, "rarity": rarities.uncommon, "description": "Raises max health of unit by 5."},
	"Resource Seed": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true, "price": 6, "mapUsable": true, "statBoost": statBoosts.resource, "uses": 1, "obtainable": true, "rarity": rarities.uncommon, "description": "Raises resource capacity of unit."},
	
	"Coin": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true ,"price": 1},
	"Silver": {"slot": equipType.none, "type": moveType.none, "unusable": true, "unequippable": true ,"price": 10, "obtainable": true, "rarity": rarities.uncommon},
	
	"Bracers": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "strength": 1, "price": 5, "description": "+1 strength"},
	"Cape": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "passive": ["Dodgy", 1], "price": 5},
	"Stabilizer": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.rare, "uses": 8, "target": targetType.user, "resVal": 0, "status": "Durability Redirect", "value": 1, "quick": true, "description": "When used, soaks all spent durability for the turn"},
	"Cloak of Visibility": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.common, "unusable": true, "passive": ["Provoke", 0], "description": "Enemies are more likely to target the wearer"},
	
	"Power Glove": {"slot": equipType.relic, "type": moveType.none, "rarity": rarities.uncommon, "morph": ["Attack+", "Defend+"], "description": "Upgrades the basic moveslot it's placed in"},
	"Attack+": {"slot": equipType.relic, "type": moveType.none, "morph": ["Attack+", "Defend+", "Power Glove"], "target": targetType.enemy, "damage": 8, "resVal": 0, "price": 0},
	"Defend+": {"slot": equipType.relic, "type": moveType.none, "morph": ["Attack+", "Defend+", "Power Glove"], "target": targetType.user, "resVal": 0, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "shield", 12], "description": "Adds 12 shield", "price": 0},
	
	"War Horn": {"target": targetType.user, "rarity": rarities.uncommon, "resVal": 0, "channel": true, "quick": true, "uselimit": 1, "effect": funcref(self, "change_attribute"), "args": ["moveUser", "tempStrength", 1, "turnCount"], "description": "Attacks used this turn deal extra damage, which increases every turn.", "slot": equipType.relic, "type": moveType.special},
	"Osmosis Device": {"slot": equipType.relic, "type": moveType.magic, "rarity": rarities.uncommon, "unusable": true, "passive": ["Gain Mana", 1], "description": "Kills restore mana"},
	"Power Loader": {"slot": equipType.relic, "type": moveType.trick, "rarity": rarities.uncommon, "unusable": true, "discount": [["Reload", 1], ["Catch", 1]], "description": "Reloads cost 1 less."},
	
	"Crown": {"slot": equipType.relic, "type": moveType.none, "cursed": true, "resVal": 0, "channel": true, "damage": 12, "target": targetType.enemy, "uselimit": 1, "price": 0, "description": "definitely not cursed"},
	"Crown+": {"slot": equipType.relic, "type": moveType.none, "cursed": true, "resVal": 0, "channel": true, "damage": 12, "target": targetType.enemyTargets, "uselimit": 1, "price": 0},
	
	"X": {"slot": equipType.any, "type": moveType.none, "resVal": 999, "uses": 0} #temp
}

func get_classname(type):
	if type == moveType.special: return "Fighter"
	elif type == moveType.magic: return "Mage"
	elif type == moveType.trick: return "Rogue"
	
func random_moveType():
	var typeList = [moveType.special, moveType.magic, moveType.trick]
	return typeList[randi() % typeList.size()]
	
func get_relics():
	var relics = []
	var moveData
	var weight
	for move in moveList:
		moveData = moveList[move]
		if (moveData.has("slot") and moveData["slot"] == equipType.relic) or moveData.has("obtainable"):
			if moveData.has("rarity"):
				weight = moveData["rarity"]
			else: weight = 0
			for i in weight:
				relics.append(move)
	return relics

func get_uses(moveName):
	var uses = 0
	if !moveList.has(moveName): uses = -1
	elif moveList[moveName].has("uses"): uses = moveList[moveName]["uses"]
	elif moveList[moveName]["type"] <= moveType.basic: uses = -1
	elif moveList[moveName]["slot"] == equipType.relic: uses = -1
	elif moveList[moveName]["type"] == moveType.item: uses = 3
	elif moveList[moveName].has("damage") or moveList[moveName].has("damaging"): uses = DEFAULTUSESDAMAGE
	else: uses = DEFAULTUSESOTHER
	if get_parent().get_parent().hardMode and uses > 1:
		if moveList[moveName]["type"] == moveType.item: uses -=1
		else: uses -= 2
	return uses

func get_description(moveName):
	if moveName == "X" or !moveList.has(moveName): return ""
	var moveData = moveList[moveName]
	if moveData.has("unequippable"): return moveName
	var desc = moveName
	if moveData.has("resVal") and moveData["resVal"] > 0: desc += " [" + String(moveData["resVal"]) + "]"
	if moveData.has("target"):
		if moveData["target"] == targetType.enemy: desc += "\n" + "Single Enemy"
		elif moveData["target"] == targetType.enemies: desc += "\n" + "All Enemies"
		elif moveData["target"] == targetType.enemyTargets: desc += "\n" + "Same Target Enemies"
		elif moveData["target"] == targetType.ally: desc += "\n" + "Single Ally"
		elif moveData["target"] == targetType.allies: desc += "\n" + "All Allies"
		elif moveData["target"] == targetType.everyone: desc += "\n" + "EVERYONE"
		elif moveData["target"] == targetType.user: desc += "\n" + "Self"
	if moveData.has("damage") or moveData.has("healing"): desc += " / "
	if moveData.has("damage"): desc += "Base Damage: " + String(moveData["damage"])# + " + " + String(Battle.currentUnit.strength)
	if moveData.has("healing"): desc += "Healing: " + String(moveData["healing"])
	var tags = []
	if moveData.has("channel"): tags.append("Channel")
	if moveData.has("charge"): tags.append("Charge")
	if moveData.has("quick"): tags.append("Quick")
	if moveData.has("hits") and moveData["hits"] != 1: tags.append(str(moveData["hits"], " Hits"))
	if moveData.has("barrage"): tags.append("Barrage")
	if moveData.has("uselimit"): tags.append("Once Per Battle")
	if !tags.empty():
		desc += "\n"
		for tag in tags:
			desc += tag + ", "
		desc.erase(desc.length() - 2, 2)
	if moveData.has("status") or moveData.has("description"): desc += "\n"
	if moveData.has("status"):
		desc += "Status: " + moveData["status"]
		if moveData.has("value"): desc += " " + String(moveData["value"])
		if moveData.has("description"): desc += " | "
	if moveData.has("description"): desc += String(moveData["description"])
	return desc

#Effects
func get_enemy_targeters(unit):
	var targeters = []
	for enemy in Battle.get_team(false, true, unit.real):
		if typeof(enemy.storedTarget) != TYPE_STRING:
			if enemy.storedTarget == unit:
				targeters.append(enemy)
	return targeters

func is_enemy_targeting_user(enemy):
	var targetType = typeof(enemy.storedTarget)
	if (targetType == TYPE_STRING and (enemy.storedTarget == "Party" or enemy.storedTarget == "everyone")) or (enemy.storedTarget == Battle.moveUser):
		return 1
	return 0

func switch_intents(oldTarget, newTarget):
	var targeters = get_enemy_targeters(oldTarget)
	for enemy in targeters:
		Battle.set_intent(enemy, newTarget)

func taunt():
	Battle.set_intent(Battle.moveTarget, Battle.moveUser)

func midnight_flare(user):
	var damagedAlly = null
	for unit in Battle.get_team(true, true, user.real):
		if !damagedAlly: damagedAlly = unit
		elif unit.currentHealth < damagedAlly.currentHealth: damagedAlly = unit
	var allEnemies = Battle.get_team(false, true, user.real)
	for enemy in allEnemies:
		Battle.set_intent(enemy, damagedAlly)

func status_to_damage(target, statusName, multiplier = 1, removeAfter = true):
	var StatusManager = get_node("../StatusManager")
	var targetInfo = StatusManager.find_status(target, statusName, true)
	if targetInfo:
		var targetList = targetInfo[0]
		var targetStatus = targetInfo[1]
		target.take_damage(targetStatus["value"] * multiplier)
		if removeAfter: StatusManager.remove_status(target, targetList, targetStatus)

func taunt_burns(user):
	var StatusManager = get_node("../StatusManager")
	var allEnemies = Battle.get_team(false, true, user.real)
	for enemy in allEnemies:
		if StatusManager.find_status(enemy, "Burn"):
			Battle.set_intent(enemy, user)

func heal_team(user, value):
	var team = Battle.get_team(true, true, user.real)
	for unit in team:
		unit.heal(value)

func restore_ap(unit, gain):
	if unit.isPlayer: unit.update_resource(gain, Battle.moveType.special, true)

func give_status(unit, status, value = 0, stack = null, altZero = false): #for when a status goes on someone besides the target
	var StatusManager = get_node("../StatusManager")
	if stack: #Multiply status based on its current value instead of adding
		var statusInfo = StatusManager.find_status(unit, status)
		StatusManager.add_status(unit, status, statusInfo["value"] * value)
	else:
		if typeof(value) ==  TYPE_ARRAY: value = value.size() #the usual
		if value > 0:
			StatusManager.add_status(unit, status, value) 
		else:
			if altZero: StatusManager.add_status(unit, status, 0) #altzero decides whether a 0 means a status goes on forever or not at all

func take_recoil(unit, damage, modifier):
	if unit.currentHealth > 0: #thorns weirdness
		if modifier >= 0:
			unit.take_damage(ceil(damage * modifier))
		else:
			unit.heal(ceil(damage * modifier * -1))

func change_attribute(unit, attribute, amount, multiplier = 1):
	if typeof(multiplier) == TYPE_ARRAY: #for when i am getting weird with passing arguments
		multiplier = multiplier.size()
	var temp = unit.get(attribute) + (amount * multiplier)
	unit.set(attribute, temp)
	if attribute == "shield": unit.update_hp()
	if attribute == "strength" or attribute == "tempStrength": unit.update_strength()

func is_unit_poisoned(unit): #a little overly specific
	var StatusManager = get_node("../StatusManager")
	if StatusManager.find_status(unit, "Poison"): return 1
	else: return 0

func get_unit_poison(unit): #kinda redundant, definitely a stopgap
	var poisonedUnit
	if unit == Battle.moveTarget: poisonedUnit = Battle.moveUser
	elif unit == Battle.moveUser: poisonedUnit = Battle.moveTarget
	else: poisonedUnit = unit
	var StatusManager = get_node("../StatusManager")
	var statusInfo = StatusManager.find_status(poisonedUnit, "Poison")
	if statusInfo: return statusInfo["value"]
	else: return 0

func is_damaged(target):
	if target.currentHealth < target.maxHealth: return true
	else: return false

func add_hits(firstCond, secondCond, hitCount, equal = true):
	if typeof(firstCond) == TYPE_STRING or (equal and firstCond == secondCond) or (!equal and firstCond != secondCond):
		Battle.hits += hitCount

func below_blow(unit):
	var enemies = Battle.get_team(false, true, unit.real)
	var targeters = 0
	for enemy in enemies:
		if typeof(enemy.storedTarget) != TYPE_STRING:
			if enemy.storedTarget == unit:
				targeters+=1
	Battle.hits += enemies.size() - targeters 

func crusher_claw(moveTarget, hitCount):
	var StatusManager = get_node("../StatusManager")
	if moveTarget.shield > 0 or StatusManager.find_status(moveTarget, "Dodgy"):
		Battle.hits += hitCount

func hits_for_hp_percentage(unit, percentage, hitCount, maxGain = 30):
	var checkVal = unit.maxHealth * percentage
	var i = 1
	while unit.currentHealth <= unit.maxHealth - (checkVal * i):
		Battle.hits += hitCount
		i+=1
		if i >= maxGain: break

func hits_for_durability(box, percentage, hitCount):
	if float(box.currentUses)/box.maxUses <= percentage:
		Battle.hits += hitCount

func fill_boxes(player, moveName):
	for box in player.boxHolder.get_children():
		var boxMove = box.moves[0]
		if boxMove == "X" or (moveList[boxMove].type == moveType.item and box.currentUses == 0):
			box.get_node("../../../").box_move(box, moveName)
			box.set_uses(-1)
			box.timesUsed = 0

func damage_amp(value, modifier = 1):
	Battle.damageBuff = floor(value * modifier)
