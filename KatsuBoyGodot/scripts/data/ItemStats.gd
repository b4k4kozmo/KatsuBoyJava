@icon("res://assets/objects/chest.png")
class_name ItemStats
extends Resource
## One item, as a file rather than a script.
##
## Every item in the Java version was its own class: a name, a sprite path, a
## few numbers and sometimes a `use()`. Nineteen scripts that were nearly the
## same script. This resource is the shape they all shared, so a new sword, a
## new potion or a new lamp is a .tres and two minutes in the Inspector.
##
## Make one: copy a file from assets/data/items/, change it, then add it to
## GamePanel's "Items" list so save files can find it by name. After that it can
## be dropped on a map with an ObjectMarker set to "From Stats", put in a chest,
## or put on the shop's shelf.
##
## What still wants a script: an item whose effect is a new rule rather than a
## new number - something that changes how a fight works, or opens a screen.
## See scripts/object/ for the ones that do.

## Stable key. Written into save files, so never rename one that exists.
## This is also what the item is called on screen.
@export var display_name: String = "New Item"

## What it looks like on the ground and in the bag. One 48x48 PNG.
@export var sprite: Texture2D

## Shown in the inventory when this item is highlighted. Keep the lines short -
## the box is about 30 characters wide, and \n breaks a line.
@export_multiline var description: String = ""

## What Kami Mart charges, and half of it is what the shop pays to buy it back.
@export_range(0, 9999) var price: int = 0

## What kind of thing it is, which decides what happens when you pick it up or
## select it in the bag.
##
##   Sword / Axe    a weapon. Equipping it sets your attack. An Axe also fells
##                  dry trees, which is the only difference between the two.
##   Shield         equipping it sets your defence.
##   Light          carry it and it lights the dark. Toggled from the bag.
##   Consumable     select it in the bag to use it. See the Effect group.
##   Pickup         used the instant you walk over it, never carried.
@export_enum("Sword", "Axe", "Shield", "Light", "Consumable", "Pickup")
var kind: String = "Consumable"

@export_group("Weapon")
## Added to your strength, then multiplied by your class's melee skill.
@export_range(0, 100) var attack_value: int = 0
## The reach of the swing, in pixels. 24x24 is a bokken, 30x30 an axe.
@export var attack_area: Vector2i = Vector2i(24, 24)
## How hard a hit shoves a monster back. 0 is no shove.
@export_range(0, 40) var knock_back_power: int = 0
## Frames of wind-up, then frames until the swing ends. Together these are the
## biggest lever on a weapon: the axe hits twice as hard as the bokken and
## still loses on damage per second because it is slow.
@export_range(1, 60) var motion1_duration: int = 5
@export_range(1, 60) var motion2_duration: int = 15

@export_group("Shield")
## Subtracted from incoming damage, along with dexterity.
@export_range(0, 100) var defense_value: int = 0

@export_group("Light")
## How far the light reaches, in pixels. The candle is 250.
@export_range(0, 1000) var light_radius: int = 0

@export_group("Effect")
## What using it does. Tick as many as apply - a tent heals, restores, cures
## and rests, all at once.
@export_flags("Heal life", "Restore mana", "Cure the curse",
		"Rest until sunrise", "Unlock running")
var effects: int = 0
## Flat life restored. Added to the share below.
@export_range(0, 200) var heal_amount: int = 0
## Life restored as a percentage of your maximum, so a potion is still worth
## buying at level 15. The Green Potion is 50.
@export_range(0, 100) var heal_share: int = 0
## Flat mana restored, and the same as a percentage of your maximum.
@export_range(0, 200) var mana_amount: int = 0
@export_range(0, 100) var mana_share: int = 0
## Shown in a message box when it is used. Leave empty for the default.
@export var use_message: String = ""

@export_group("Inventory")
## Can several of these share one slot? True for potions and tents.
@export var stackable: bool = false
## Sound effect number from the sound bank. 20 is the power-up chime.
@export_range(0, 40) var use_sound: int = 20

const HEAL_LIFE := 1
const RESTORE_MANA := 2
const CURE_CURSE := 4
const REST := 8
const UNLOCK_RUNNING := 16


func does(flag: int) -> bool:
	return (effects & flag) != 0


## The Entity type constant this kind maps to.
func entity_type() -> int:
	match kind:
		"Sword": return Entity.TYPE_SWORD
		"Axe": return Entity.TYPE_AXE
		"Shield": return Entity.TYPE_SHIELD
		"Light": return Entity.TYPE_LIGHT
		"Pickup": return Entity.TYPE_PICKUP_ONLY
	return Entity.TYPE_CONSUMABLE


## How much life this restores for a player at this maximum. Flat plus share,
## so an item can be "4 HP" or "half your life" or both.
func life_restored(max_life: int) -> int:
	if not does(HEAL_LIFE):
		return 0
	@warning_ignore("integer_division")
	return heal_amount + (max_life * heal_share) / 100


func mana_restored(max_mana: int) -> int:
	if not does(RESTORE_MANA):
		return 0
	@warning_ignore("integer_division")
	return mana_amount + (max_mana * mana_share) / 100


## One line for the editor and for whoever is reading the .tres, saying what
## this item actually is. Used by the marker label and the warning triangle.
func summary() -> String:
	match kind:
		"Sword", "Axe":
			return "%s, attack %d" % [kind.to_lower(), attack_value]
		"Shield":
			return "shield, defence %d" % defense_value
		"Light":
			return "light, radius %d" % light_radius
	var bits: Array[String] = []
	if does(HEAL_LIFE): bits.append("heals")
	if does(RESTORE_MANA): bits.append("mana")
	if does(CURE_CURSE): bits.append("cures")
	if does(REST): bits.append("rests")
	if does(UNLOCK_RUNNING): bits.append("running")
	if bits.is_empty():
		return kind.to_lower() + ", no effect"
	return "%s, %s" % [kind.to_lower(), ", ".join(bits)]
