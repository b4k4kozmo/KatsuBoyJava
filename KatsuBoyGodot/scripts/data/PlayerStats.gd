class_name PlayerStats
extends Resource
## Katsu Boy's starting numbers and movement speeds.
## Edit assets/data/player.tres in the Inspector - no code needed.

@export_group("Starting stats")
@export var level: int = 1
@export var max_life: int = 6
@export var max_mana: int = 4
@export var ammo: int = 10
## More strength = more damage dealt.
@export var strength: int = 1
## More dexterity = less damage taken.
@export var dexterity: int = 1
@export var coin: int = 0

@export_group("Levelling")
## The exp curve, as total exp needed to reach a level:
##
##     total(level) = exp_base * level ^ exp_curve
##
## A power curve rather than a multiplier, because multiplying the requirement
## each level (the Java version tripled it) means the first few levels arrive in
## one kill and the rest never arrive at all. At the defaults, level 2 costs 11
## exp, level 5 costs 112 in total, level 10 costs 632 and level 20 costs 3578 -
## each level a little dearer than the last, none of them a wall.
##
## Raise exp_base to slow the whole game down evenly; raise exp_curve to make
## the late game slower without touching the early game.
@export_range(0.5, 20.0, 0.5) var exp_base: float = 2.0
@export_range(1.0, 4.0, 0.05) var exp_curve: float = 2.5

## What each level adds. Life is in half hearts, so 2 is one whole heart.
@export_range(0, 10) var life_per_level: int = 2
@export_range(1, 5) var strength_every: int = 1     ## +1 strength every N levels
@export_range(1, 5) var dexterity_every: int = 2    ## +1 dexterity every N levels
@export_range(1, 5) var mana_every: int = 2         ## +1 max mana every N levels


## Total exp needed to reach `level`. Level 1 is free.
func exp_to_reach(level: int) -> int:
	if level <= 1:
		return 0
	return int(round(exp_base * pow(float(level), exp_curve)))


## What the player's stats should be at a given level. One place, so the level
## up code, the character screen and the tests can never disagree.
func strength_at(level: int) -> int:
	@warning_ignore("integer_division")
	return strength + (level - 1) / strength_every


func dexterity_at(level: int) -> int:
	@warning_ignore("integer_division")
	return dexterity + (level - 1) / dexterity_every


func max_life_at(level: int) -> int:
	return max_life + life_per_level * (level - 1)


func max_mana_at(level: int) -> int:
	@warning_ignore("integer_division")
	return max_mana + (level - 1) / mana_every

@export_group("Movement")
## Walking speed, in pixels per frame.
@export var walk_speed: int = 4
## Walking speed once the player has the Boots.
@export var boots_walk_speed: int = 6
## Speed while holding the Run key.
@export var run_speed: int = 10
## When on, the player can only run after picking up the Boots. Turn this off
## to let them sprint from the start.
@export var requires_boots_to_run: bool = true

@export_group("Starting gear")
@export_enum("Normal Sword", "Kami no Bokken", "Kami Axe")
var starting_weapon: String = "Normal Sword"
@export_enum("Puffa Shield", "Kami Shield")
var starting_shield: String = "Puffa Shield"
## The thing the Shoot key throws. Shuriken costs mana, Snow-ball costs ammo.
@export_enum("Shuriken", "Snow-ball")
var starting_projectile: String = "Shuriken"
