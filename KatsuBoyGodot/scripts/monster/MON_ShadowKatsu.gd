class_name MON_ShadowKatsu
extends Entity
## Java: monster/MON_ShadowKatsu.java


const STATS := preload("res://assets/data/monsters/shadow_katsu.tres")


func _init(gp) -> void:
	super(gp)

	# Numbers live in the resource so they can be tuned in the Inspector.
	STATS.apply_to(self)
	projectile = OBJ_Shuriken.new(gp)

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


## The hardest thing on the map pays like it. One of these is most of a ticket.
func check_drop() -> void:

	var i: int = randi() % 100 + 1

	if i <= 60:
		drop_item(OBJ_Coin.worth(gp, randi_range(25, 40)))
	elif i <= 80:
		drop_item(OBJ_Heart.new(gp))
	else:
		drop_item(OBJ_Potion_Green.new(gp))
