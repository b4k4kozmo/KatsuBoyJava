class_name OBJ_Door
extends Entity
## Java: object/OBJ_Door.java

const OBJ_NAME := "Door"


func _init(gp) -> void:
	super(gp)

	type = TYPE_OBSTACLE
	name = OBJ_NAME
	down1 = setup("/objects/door", gp.tile_size, gp.tile_size)
	collision = true

	solid_area.x = 0
	solid_area.y = 16
	solid_area.width = 48
	solid_area.height = 32
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	set_dialogue()


func set_dialogue() -> void:
	dialogues[0][0] = "You need a key!"


func interact() -> void:
	sound_number = 20
	set_sound()
	start_dialogue(self, 0)
