@icon("res://assets/player/boy_down_1.png")
class_name PlayerClass
extends Resource
## One of the three people you can be.
##
## The class screen used to be three names that changed almost nothing: one
## handed you a weapon, the other two handed you the Boots. Everything a class
## is now lives in a resource, so the differences are tunable in the Inspector
## and visible on the class-select screen without editing code.
##
## The rule the numbers are built to: a class may be 30% better at something as
## long as it is worse at something else, and none of them may be locked out of
## any fight. A Ninja beats armour with shuriken and darkness instead of muscle;
## a Zilla walks slowly into it and takes the hits.
##
## Add a class: copy a .tres in assets/data/classes/, change the numbers, and
## drop it into GamePanel's "Player Classes" list. The title screen builds
## itself from that list.

## Stable key. Written into save files, so never rename one that exists.
@export var id: String = ""
@export var display_name: String = "New Class"
## One line under the name on the class screen.
@export var tagline: String = ""
## Two or three lines on the class screen, in character.
@export_multiline var blurb: String = ""

@export_group("Starting gear")
@export_enum("Normal Sword", "Kami no Bokken", "Kami Axe")
var starting_weapon: String = "Normal Sword"
@export_enum("Puffa Shield", "Kami Shield")
var starting_shield: String = "Puffa Shield"
@export_enum("Shuriken", "Snow-ball")
var starting_projectile: String = "Shuriken"
## Added to the base max mana from player.tres. More mana is more shuriken.
@export_range(0, 10) var bonus_mana: int = 0
@export_range(0, 20) var bonus_ammo: int = 0
## Free Boots. Off for everyone now - the Boots are a thing you find.
@export var starts_with_boots: bool = false

@export_group("Melee")
## Multiplies (strength + weapon). 1.0 is the baseline.
@export_range(0.5, 2.0, 0.05) var melee_multiplier: float = 1.0
## Multiplies the swing animation length, so below 1.0 swings FASTER. This is
## the biggest lever in the game: the axe hits twice as hard as the bokken and
## still loses on damage per second because it is slow.
@export_range(0.4, 2.0, 0.05) var swing_multiplier: float = 1.0
## Extra multiplier when holding this exact weapon, by OBJ_NAME. Empty for none.
@export var favoured_weapon: String = ""
@export_range(1.0, 2.0, 0.05) var favoured_bonus: float = 1.0
## Enemy defence this class simply ignores - a blade finding the gap in armour.
@export_range(0, 10) var defence_pierce: int = 0
## Melee multiplier between sunset and sunrise.
@export_range(0.5, 2.0, 0.05) var night_multiplier: float = 1.0

@export_group("Ranged")
## Multiplies thrown-weapon damage.
@export_range(0.5, 2.0, 0.05) var ranged_multiplier: float = 1.0

@export_group("Body")
## Multiplies the knock-back this class deals out.
@export_range(0.0, 3.0, 0.05) var knockback_dealt: float = 1.0
## Multiplies the knock-back it takes. Below 1.0 is a good stance.
@export_range(0.0, 2.0, 0.05) var knockback_taken: float = 1.0
## Flat defence on top of dexterity and the shield.
@export_range(0, 10) var bonus_defence: int = 0
## Walking speed in pixels per frame, overriding player.tres.
@export_range(1, 12) var walk_speed: int = 4

@export_group("Levelling")
## Overrides the same fields on PlayerStats for this class. Life is in half
## hearts, so 2 is one heart a level.
@export_range(1, 6) var life_per_level: int = 2
@export_range(1, 5) var strength_every: int = 1
@export_range(1, 5) var dexterity_every: int = 2
@export_range(1, 5) var mana_every: int = 2


func strength_at(level: int, base: int) -> int:
	@warning_ignore("integer_division")
	return base + (level - 1) / strength_every


func dexterity_at(level: int, base: int) -> int:
	@warning_ignore("integer_division")
	return base + (level - 1) / dexterity_every


func max_life_at(level: int, base: int) -> int:
	return base + life_per_level * (level - 1)


func max_mana_at(level: int, base: int) -> int:
	@warning_ignore("integer_division")
	return base + bonus_mana + (level - 1) / mana_every


## What this class hits for with `weapon` in hand at this strength. `night` is
## whether it is currently dark out.
func attack_with(strength: int, weapon, night: bool) -> int:
	if weapon == null:
		return strength
	var raw: float = float(strength + weapon.attack_value) * melee_multiplier
	if not favoured_weapon.is_empty() and weapon.name == favoured_weapon:
		raw *= favoured_bonus
	if night:
		raw *= night_multiplier
	return maxi(int(round(raw)), 1)


## The swing length this class gets out of a weapon, in frames.
func swing_frames(base_frames: int) -> int:
	return maxi(int(round(float(base_frames) * swing_multiplier)), 2)
