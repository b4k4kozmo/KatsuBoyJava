class_name MON_ShadowKatsu
extends Entity
## Java: monster/MON_ShadowKatsu.java


func _init(gp) -> void:
	super(gp)

	type = TYPE_MONSTER
	name = "Shadow"
	default_speed = 1
	speed = default_speed
	max_life = 200
	life = max_life
	attack = 7
	defense = 4
	exp = 600
	projectile = OBJ_Shuriken.new(gp)
	knock_back_power = 5

	solid_area.x = 4
	solid_area.y = 4
	solid_area.width = 40
	solid_area.height = 44
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
	attack_area.width = 48
	attack_area.height = 48
	motion1_duration = 40
	motion2_duration = 85

	get_image()
	get_attack_image()


func get_image() -> void:
	up1 = setup("/monster/shadowkatsu_up_1", gp.tile_size, gp.tile_size)
	up2 = setup("/monster/shadowkatsu_up_2", gp.tile_size, gp.tile_size)
	down1 = setup("/monster/shadowkatsu_down_1", gp.tile_size, gp.tile_size)
	down2 = setup("/monster/shadowkatsu_down_2", gp.tile_size, gp.tile_size)
	left1 = setup("/monster/shadowkatsu_left_1", gp.tile_size, gp.tile_size)
	left2 = setup("/monster/shadowkatsu_left_2", gp.tile_size, gp.tile_size)
	right1 = setup("/monster/shadowkatsu_right_1", gp.tile_size, gp.tile_size)
	right2 = setup("/monster/shadowkatsu_right_2", gp.tile_size, gp.tile_size)


func get_attack_image() -> void:
	attack_up1 = setup("/monster/shadow_up_attack_1", gp.tile_size, gp.tile_size * 2)
	attack_up2 = setup("/monster/shadow_up_attack_2", gp.tile_size, gp.tile_size * 2)
	attack_down1 = setup("/monster/shadow_down_attack_1", gp.tile_size, gp.tile_size * 2)
	attack_down2 = setup("/monster/shadow_down_attack_2", gp.tile_size, gp.tile_size * 2)
	attack_left1 = setup("/monster/shadow_left_attack_1", gp.tile_size * 2, gp.tile_size)
	attack_left2 = setup("/monster/shadow_left_attack_2", gp.tile_size * 2, gp.tile_size)
	attack_right1 = setup("/monster/shadow_right_attack_1", gp.tile_size * 2, gp.tile_size)
	attack_right2 = setup("/monster/shadow_right_attack_2", gp.tile_size * 2, gp.tile_size)


func set_action() -> void:

	if on_path == true:
		# Check if stop chasing
		check_stop_chasing(gp.player, 15, 100)

		# Search the direction to go
		search_path(get_goal_col(gp.player), get_goal_row(gp.player))

		# Check if it shoots a projectile
		check_shooting(200, 30)
	else:
		# Check if it starts chasing
		check_start_chasing(gp.player, 5, 100)

		# Get a random direction if not on path
		get_random_direction()

	# Check if it attacks
	if attacking == false:
		check_attacking(30, gp.tile_size * 4, gp.tile_size)


func damage_reaction() -> void:
	action_lock_counter = 0
	on_path = true


func check_drop() -> void:

	# CAST A DIE
	var i: int = randi() % 100 + 1

	# SET THE MONSTER DROP
	if i < 50:
		drop_item(OBJ_Coin.new(gp))
	if i >= 50 and i < 75:
		drop_item(OBJ_Potion_Green.new(gp))
	if i >= 75:
		drop_item(OBJ_Heart.new(gp))
