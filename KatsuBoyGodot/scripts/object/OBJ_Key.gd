class_name OBJ_Key
extends Entity
## Java: object/OBJ_Key.java

const OBJ_NAME := "Key"


func _init(gp) -> void:
	super(gp)

	type = TYPE_CONSUMABLE
	name = OBJ_NAME
	down1 = setup("/objects/key", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nWhat this will open?"
	price = 10
	stackable = true
	set_dialogue()


func set_dialogue() -> void:
	dialogues[0][0] = "The " + name + " opened the door!"
	dialogues[1][0] = "What are you doing?"


func use(entity) -> bool:
	sound_number = 20
	set_sound()
	var obj_index: int = get_detected(entity, gp.obj, "Door")

	if obj_index != 999:
		start_dialogue(self, 0)
		gp.play_se(3)
		gp.obj[gp.current_map][obj_index] = null
		return true
	else:
		start_dialogue(self, 1)
		return false
