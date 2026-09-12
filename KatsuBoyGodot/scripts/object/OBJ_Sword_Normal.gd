class_name OBJ_Sword_Normal
extends Entity
## Java: object/OBJ_Sword_Normal.java

const OBJ_NAME := "Normal Sword"


func _init(gp) -> void:
	super(gp)

	type = TYPE_SWORD
	name = OBJ_NAME
	down1 = setup("/objects/sword", gp.tile_size, gp.tile_size)
	attack_value = 1
	attack_area.width = 36
	attack_area.height = 36
	description = "[" + name + "]\nKatsu boy's sword."
	price = 10
	knock_back_power = 3
	motion1_duration = 5
	motion2_duration = 25
