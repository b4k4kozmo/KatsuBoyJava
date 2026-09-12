class_name OBJ_Carbo
extends Entity
## Java: object/OBJ_Carbo.java

const OBJ_NAME := "Carbuncle"


func _init(gp) -> void:
	super(gp)

	name = OBJ_NAME
	down1 = setup("/objects/carbuncle_green_1", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nA curious little\ngreen creature."
	price = 10
