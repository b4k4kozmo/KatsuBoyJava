class_name OBJ_Kami_Shield
extends Entity
## Java: object/OBJ_Kami_Shield.java

const OBJ_NAME := "Kami Shield"


func _init(gp) -> void:
	super(gp)

	type = TYPE_SHIELD
	name = OBJ_NAME
	down1 = setup("/objects/kamishield", gp.tile_size, gp.tile_size)
	defense_value = 2
	description = "[" + name + "]\nHeavy shield crafted\nby Kami-mon."
	price = 100
