@icon("res://assets/objects/coin.png")
@tool
class_name MonsterDrop
extends Resource
## One line of a monster's drop table.
##
## A monster's loot used to be a ladder of `if randi() <= 55` inside its script,
## which meant tuning the economy was a code edit and adding a monster meant
## writing that ladder again. Now a drop is a row you fill in: what falls, how
## likely it is relative to the other rows, and how much of it.
##
## Weights are relative, not percentages. Three rows weighted 55 / 20 / 25 give
## the same odds as 11 / 4 / 5 - so you can add a row without re-doing the
## arithmetic on the ones already there.
##
## "Nothing" is a real row. Use it for the share of kills that pay out nothing
## at all, rather than leaving the weights short of 100.

@export_enum("Coin", "Heart", "Green Potion", "Mana Crystal", "Nothing")
var item: String = "Coin"

## How often this row comes up, relative to the other rows on the same monster.
@export_range(0, 1000) var weight: int = 10

@export_group("Coins only")
## A coin drop rolls somewhere in this range, inclusive. Set both to the same
## number for a fixed payout. See OBJ_Coin for what the denominations are worth
## and ROADMAP.md for what a sweep of a map should come to.
@export_range(1, 500) var coin_min: int = 1
@export_range(1, 500) var coin_max: int = 3


## Build the thing this row drops, or null for a "Nothing" row.
func make(gp) -> Entity:
	match item:
		"Coin": return OBJ_Coin.worth(gp, randi_range(mini(coin_min, coin_max), maxi(coin_min, coin_max)))
		"Heart": return OBJ_Heart.new(gp)
		"Green Potion": return OBJ_Potion_Green.new(gp)
		"Mana Crystal": return OBJ_ManaCrystal.new(gp)
	return null


func summary() -> String:
	if item == "Coin":
		return "Coin %d-%d (weight %d)" % [coin_min, coin_max, weight]
	return "%s (weight %d)" % [item, weight]
