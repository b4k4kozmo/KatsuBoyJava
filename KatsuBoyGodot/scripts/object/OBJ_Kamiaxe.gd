class_name OBJ_Kamiaxe
extends Entity
## Java: object/OBJ_Kamiaxe.java

const OBJ_NAME := "Kami Axe"


func _init(gp) -> void:
	super(gp)

	type = TYPE_AXE
	name = OBJ_NAME
	down1 = setup("/objects/axe", gp.tile_size, gp.tile_size)
	attack_value = 8
	attack_area.width = 24
	attack_area.height = 24
	description = "[" + name + "]\nA strong axe forged\nby dreams."
	price = 10
	knock_back_power = 12
	motion1_duration = 30
	motion2_duration = 50
