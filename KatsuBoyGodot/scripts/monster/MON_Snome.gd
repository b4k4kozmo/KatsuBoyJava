class_name MON_Snome
extends Entity
## Java: monster/MON_Snome.java


const STATS := preload("res://assets/data/monsters/snome.tres")


func _init(gp) -> void:
	super(gp)

	# Numbers live in the resource so they can be tuned in the Inspector.
	STATS.apply_to(self)
	projectile = OBJ_Snowball.new(gp)

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


## Worth going out of your way for: four times a slime's health, four times the
## money.
func check_drop() -> void:

	var i: int = randi() % 100 + 1

	if i <= 45:
		drop_item(OBJ_Coin.worth(gp, randi_range(3, 6)))
	elif i <= 70:
		drop_item(OBJ_Coin.worth(gp, 10))
	elif i <= 90:
		drop_item(OBJ_Potion_Green.new(gp))
	else:
		drop_item(OBJ_Heart.new(gp))
