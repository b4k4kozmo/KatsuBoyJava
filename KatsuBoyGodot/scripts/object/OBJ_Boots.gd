class_name OBJ_Boots
extends Entity
## Java: object/OBJ_Boots.java

const OBJ_NAME := "Boots"


func _init(gp) -> void:
	super(gp)

	name = OBJ_NAME
	down1 = setup("/objects/boots", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nGotta go fast!"
	price = 10
