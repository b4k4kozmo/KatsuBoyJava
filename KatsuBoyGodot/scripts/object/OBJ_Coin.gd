class_name OBJ_Coin
extends Entity
## Java: object/OBJ_Coin.java

const OBJ_NAME := "Kami Coin"


func _init(gp) -> void:
	super(gp)

	type = TYPE_PICKUP_ONLY
	name = OBJ_NAME
	value = 1
	down1 = setup("/objects/coin", gp.tile_size, gp.tile_size)


func use(_entity) -> bool:
	gp.play_se(SE.COIN)
	gp.ui.add_message("You found " + str(value) + " shiny " + name + "!")
	gp.player.coin += value
	return true
