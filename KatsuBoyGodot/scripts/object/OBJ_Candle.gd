class_name OBJ_Candle
extends Entity
## Java: object/OBJ_Candle.java

const OBJ_NAME := "Candle"


func _init(gp) -> void:
	super(gp)

	type = TYPE_LIGHT
	name = OBJ_NAME
	down1 = setup("/objects/candle", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nLights up your world \ncan burn for an eternity."
	price = 200
	light_radius = 250
