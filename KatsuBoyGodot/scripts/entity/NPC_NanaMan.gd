class_name NPC_NanaMan
extends Entity
## Java: entity/NPC_NanaMan.java


func _init(gp) -> void:
	super(gp)

	name = "Nanaman"
	direction = "down"
	speed = 25
	sound_number = 19

	solid_area = Rect.new()
	solid_area.x = 3
	solid_area.y = 18
	solid_area.width = 42
	solid_area.height = 30
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	get_image()
	set_dialogue()


func get_image() -> void:
	up1 = setup("/npc/nanaman_1", gp.tile_size, gp.tile_size)
	up2 = setup("/npc/nanaman_2", gp.tile_size, gp.tile_size)
	down1 = setup("/npc/nanaman_3", gp.tile_size, gp.tile_size)
	down2 = setup("/npc/nanaman_4", gp.tile_size, gp.tile_size)
	left1 = setup("/npc/nanaman_4", gp.tile_size, gp.tile_size)
	left2 = setup("/npc/nanaman_3", gp.tile_size, gp.tile_size)
	right1 = setup("/npc/nanaman_1", gp.tile_size, gp.tile_size)
	right2 = setup("/npc/nanaman_2", gp.tile_size, gp.tile_size)


func set_dialogue() -> void:
	dialogues[0][0] = "Dude, it's me!"
	dialogues[0][1] = "Just call me Nanaman for now.."
	dialogues[0][2] = "777"
	dialogues[0][3] = "Hmmm... you don't remember?"
	dialogues[0][4] = "You're faster than I imagined."
	dialogues[0][5] = "I can wall grab!"


func set_action() -> void:

	action_lock_counter += 1
	if action_lock_counter == 45:
		var i: int = randi() % 100 + 1  # pick a number between 1 and 100

		if i < 25: direction = "up"
		if i > 25 and i <= 50: direction = "down"
		if i > 50 and i <= 75: direction = "left"
		if i > 75 and i <= 100: direction = "right"

		action_lock_counter = 0


func speak() -> void:

	# Character specific stuff
	set_sound()
	face_player()
	start_dialogue(self, dialogue_set)

	if gp.player.level <= 7:
		gp.player.exp += 444
		gp.player.is_cursed = false
		if gp.player.has_boots == false:
			gp.player.exp += 777
			gp.player.has_boots = true
		if gp.player.level == 1:
			gp.player.exp += 111

	gp.player.check_level_up()
