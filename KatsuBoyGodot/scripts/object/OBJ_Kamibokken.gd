class_name OBJ_Kamibokken
extends Entity
## Java: object/OBJ_Kamibokken.java

const OBJ_NAME := "Kami no Bokken"


func _init(gp) -> void:
	super(gp)

	type = TYPE_SWORD
	name = OBJ_NAME
	down1 = setup("/objects/kamibokken", gp.tile_size, gp.tile_size)
	attack_value = 6
	attack_area.width = 48
	attack_area.height = 52
	description = "[" + name + "]\nWooden training sword.\nStronger than it looks."
	price = 210
	knock_back_power = 6
	motion1_duration = 3
	motion2_duration = 11
