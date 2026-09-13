class_name OBJ_Coin
extends Entity
## Java: object/OBJ_Coin.java
##
## Money. One class covers every denomination: the value is a field, and the
## coin is drawn bigger the more it is worth, so a fat drop reads as a fat drop
## from across the room.
##
## Make one with OBJ_Coin.worth(gp, 20) rather than new() wherever the amount
## matters. Drops use worth(); a coin placed on a map takes its value from the
## ObjectMarker's "Coin Value".

const OBJ_NAME := "Kami Coin"

## Roughly the three Zelda denominations, which is what the drop tables and the
## scattered pickups are built around.
const SMALL := 1
const PURSE := 5
const HOARD := 20


func _init(gp) -> void:
	super(gp)

	type = TYPE_PICKUP_ONLY
	name = OBJ_NAME
	value = SMALL
	get_image()


## A coin worth `amount`.
static func worth(gp, amount: int) -> OBJ_Coin:
	var coin := OBJ_Coin.new(gp)
	coin.set_value(amount)
	return coin


func set_value(amount: int) -> void:
	value = maxi(amount, 1)
	get_image()


## Bigger piles are bigger coins. Three sizes, all well inside a tile.
func get_image() -> void:
	var size: int = int(gp.tile_size * 0.7)
	if value >= HOARD:
		size = int(gp.tile_size * 1.0)
	elif value >= PURSE:
		size = int(gp.tile_size * 0.85)
	down1 = setup("/objects/coin", size, size)


func use(_entity) -> bool:
	gp.play_se(SE.COIN)
	if value == 1:
		gp.ui.add_message("You found a shiny Kami Coin!")
	else:
		gp.ui.add_message("You found %d Kami Coins!" % value)
	gp.player.coin += value
	return true
