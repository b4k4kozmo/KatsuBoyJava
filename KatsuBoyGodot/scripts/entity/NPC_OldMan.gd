class_name NPC_OldMan
extends Entity
## Java: entity/NPC_OldMan.java


func _init(gp) -> void:
	super(gp)

	direction = "down"
	speed = 1

	solid_area = Rect.new()
	solid_area.x = 8
	solid_area.y = 16
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
	solid_area.width = 28
	solid_area.height = 28

	# Starts at -1 so that the first speak() lands on dialogue set 0.
	dialogue_set = -1
	sound_number = 17

	get_image()
	set_dialogue()


func get_image() -> void:
	up1 = setup("/npc/oldman_up_01", gp.tile_size, gp.tile_size)
	up2 = setup("/npc/oldman_up_02", gp.tile_size, gp.tile_size)
	down1 = setup("/npc/oldman_down_01", gp.tile_size, gp.tile_size)
	down2 = setup("/npc/oldman_down_02", gp.tile_size, gp.tile_size)
	left1 = setup("/npc/oldman_left_01", gp.tile_size, gp.tile_size)
	left2 = setup("/npc/oldman_left_02", gp.tile_size, gp.tile_size)
	right1 = setup("/npc/oldman_right_01", gp.tile_size, gp.tile_size)
	right2 = setup("/npc/oldman_right_02", gp.tile_size, gp.tile_size)


func set_dialogue() -> void:
	dialogues[0][0] = "Hello, Katsu boy!\nAre you ready for your adventure?"
	dialogues[0][1] = "There's something useful in the\nforest."
	dialogues[0][2] = "Welcome to the lost hood."
	dialogues[0][3] = "Hmmm... you don't remember?"
	dialogues[0][4] = "Try going up north."
	dialogues[0][5] = "I'm here as long as you need me.."

	dialogues[1][0] = "Between you and me theres \na secret teleporter nearby \nthat takes you to a save point!"
	dialogues[1][1] = "Don't tell anyone i told you though..."
	dialogues[1][2] = "Seriously.. DON'T"
	dialogues[1][3] = "You can also reset that \nweird night curse at the KamiMart"
	dialogues[1][4] = "I think I can trust you."
	dialogues[1][5] = "Sell your items at night. \nCatch that stinkin' gnome..."

	dialogues[2][0] = "Well, if it isn't the well known adventurer!"
	dialogues[2][1] = "KATSU BOY!"


func set_action() -> void:

	if on_path == true:
		var goal_col := 75
		var goal_row := 95
		search_path(goal_col, goal_row)
	else:
		action_lock_counter += 1

		if action_lock_counter == 120:
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

	dialogue_set += 1
	if dialogues[dialogue_set][0] == null:
		dialogue_set = 0

	on_path = true
