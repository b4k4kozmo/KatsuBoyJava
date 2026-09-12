class_name MON_KamiJack
extends Entity
## Java: monster/MON_KamiJack.java


func _init(gp) -> void:
	super(gp)

	type = TYPE_MONSTER
	name = "Kamijack"
	speed = 12
	max_life = 111
	life = max_life
	attack = 20
	defense = 6
	exp = 250

	solid_area.x = 3
	solid_area.y = 18
	solid_area.width = 42
	solid_area.height = 30
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	get_image()


func get_image() -> void:
	up1 = setup("/monster/kamijack_down_1", gp.tile_size * 2, gp.tile_size * 2)
	up2 = setup("/monster/kamijack_down_2", gp.tile_size * 2, gp.tile_size * 2)
	down1 = setup("/monster/kamijack_down_1", gp.tile_size * 2, gp.tile_size * 2)
	down2 = setup("/monster/kamijack_down_2", gp.tile_size * 2, gp.tile_size * 2)
	left1 = setup("/monster/kamijack_down_1", gp.tile_size * 2, gp.tile_size * 2)
	left2 = setup("/monster/kamijack_down_2", gp.tile_size * 2, gp.tile_size * 2)
	right1 = setup("/monster/kamijack_down_1", gp.tile_size * 2, gp.tile_size * 2)
	right2 = setup("/monster/kamijack_down_2", gp.tile_size * 2, gp.tile_size * 2)


func set_action() -> void:

	action_lock_counter += 1
	var slow_down_rate := 60

	if action_lock_counter == slow_down_rate:

		var i: int = randi() % 100 + 1  # pick a number between 1 and 100

		if i < 25: direction = "up"
		if i > 25 and i <= 50: direction = "down"
		if i > 50 and i <= 75: direction = "left"
		if i > 75 and i <= 100: direction = "right"

		action_lock_counter = 0


func damage_reaction() -> void:
	action_lock_counter = 0
	speed = 3
	slow_down = 120


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
