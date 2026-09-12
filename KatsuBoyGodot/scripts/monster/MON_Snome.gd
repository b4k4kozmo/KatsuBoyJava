class_name MON_Snome
extends Entity
## Java: monster/MON_Snome.java


func _init(gp) -> void:
	super(gp)

	type = TYPE_MONSTER
	name = "Snome"
	default_speed = 1
	speed = default_speed
	max_life = 12
	life = max_life
	attack = 2
	defense = 2
	exp = 3
	projectile = OBJ_Snowball.new(gp)

	solid_area.x = 3
	solid_area.y = 18
	solid_area.width = 42
	solid_area.height = 30
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	get_image()


func get_image() -> void:
	up1 = setup("/monster/snome_down_1", gp.tile_size, gp.tile_size)
	up2 = setup("/monster/snome_down_2", gp.tile_size, gp.tile_size)
	down1 = setup("/monster/snome_down_1", gp.tile_size, gp.tile_size)
	down2 = setup("/monster/snome_down_2", gp.tile_size, gp.tile_size)
	left1 = setup("/monster/snome_down_1", gp.tile_size, gp.tile_size)
	left2 = setup("/monster/snome_down_2", gp.tile_size, gp.tile_size)
	right1 = setup("/monster/snome_down_1", gp.tile_size, gp.tile_size)
	right2 = setup("/monster/snome_down_2", gp.tile_size, gp.tile_size)


func set_action() -> void:

	if on_path == true:
		# Check if stop chasing
		check_stop_chasing(gp.player, 15, 100)

		# Search the direction to go
		search_path(get_goal_col(gp.player), get_goal_row(gp.player))

		# Check if it shoots a projectile
		check_shooting(100, 30)
	else:
		# Check if it starts chasing
		check_start_chasing(gp.player, 5, 100)

		# Get a random direction if not on path
		get_random_direction()


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
