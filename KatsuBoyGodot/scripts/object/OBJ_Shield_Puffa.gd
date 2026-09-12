class_name OBJ_Shield_Puffa
extends Entity
## Java: object/OBJ_Shield_Puffa.java

const OBJ_NAME := "Puffa Shield"


func _init(gp) -> void:
	super(gp)

	type = TYPE_SHIELD
	name = OBJ_NAME
	down1 = setup("/objects/puffa", gp.tile_size, gp.tile_size)
	defense_value = 1
	description = "[" + name + "]\nPuffa....J?"
	price = 10
