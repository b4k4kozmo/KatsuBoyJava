class_name DayEffect
extends Resource
## What a particular day of the week does to the game.
##
## One resource per day in assets/data/days/, wired into GamePanel's
## "Days of the week" list in Sunday-to-Saturday order. Everything is a
## multiplier on an existing number, so a day with all the defaults is simply
## an ordinary day.
##
## The multipliers are applied with rounding, so they do very little while your
## numbers are tiny (1 damage stays 1 damage) and matter more as you level up
## and find better gear. That is deliberate - a brand new character should not
## be twice as fragile because it happens to be Monday.

@export var display_name: String = ""
## Shown to the player when this day starts. Leave blank for an ordinary day.
@export var note: String = ""

@export_group("Combat")
## Scales the damage the player deals.
@export_range(0.1, 3.0, 0.05) var damage_dealt_multiplier: float = 1.0
## Scales the damage the player takes.
@export_range(0.1, 3.0, 0.05) var damage_taken_multiplier: float = 1.0

@export_group("Shop")
## When off, the merchant turns the player away.
@export var shop_open: bool = true
## Scales what the merchant charges. Below 1.0 is a sale.
@export_range(0.1, 3.0, 0.05) var shop_price_multiplier: float = 1.0

@export_group("Recovery")
## Scales health and mana restored by pickups.
@export_range(0.1, 3.0, 0.05) var healing_multiplier: float = 1.0


## Apply a multiplier to a whole number, never going below zero.
static func apply(value: int, multiplier: float) -> int:
	if is_equal_approx(multiplier, 1.0):
		return value
	return maxi(roundi(value * multiplier), 0)


## A day with no effects, used when nothing is configured.
static func neutral() -> DayEffect:
	return DayEffect.new()
