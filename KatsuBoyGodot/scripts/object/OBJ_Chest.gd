class_name OBJ_Chest
extends Entity
## Java: object/OBJ_Chest.java

const OBJ_NAME := "Chest"


func _init(gp) -> void:
	super(gp)

	type = TYPE_OBSTACLE
	name = OBJ_NAME
	image = setup("/objects/chest", gp.tile_size, gp.tile_size)
	image2 = setup("/objects/chest_open", gp.tile_size, gp.tile_size)
	down1 = image
	collision = true

	solid_area.x = 4
	solid_area.y = 16
	solid_area.width = 40
	solid_area.height = 32
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y


func set_dialogue() -> void:
	dialogues[0][0] = "You find a " + loot.name + " in the chest!" + "\n...Let's empty our pockets first!"
	dialogues[1][0] = "You find a " + loot.name + " in the chest!" + "\nAdded " + loot.name + " to the inventory!"
	dialogues[2][0] = "You look, but to no avail.."


func set_loot(loot) -> void:
	self.loot = loot
	set_dialogue()


func interact() -> void:

	sound_number = 20
	set_sound()
	if opened == false:
		gp.play_se(3)

		if gp.player.can_obtain_item(loot) == false:
			start_dialogue(self, 0)
		else:
			start_dialogue(self, 1)
			down1 = image2
			opened = true
	else:
		start_dialogue(self, 2)
