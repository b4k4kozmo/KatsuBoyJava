class_name MON_Slime
extends Entity
## Java: monster/MON_Slime.java


func _init(gp) -> void:
	super(gp)

	type = TYPE_MONSTER
	name = "Slime"
	speed = 1
	max_life = 3
	life = max_life
	attack = 5
	defense = 0
	exp = 1

	solid_area.x = 3
	solid_area.y = 18
	solid_area.width = 42
	solid_area.height = 30
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	get_image()


func get_image() -> void:
	up1 = setup("/monster/slime_down01", gp.tile_size, gp.tile_size)
	up2 = setup("/monster/slime_down02", gp.tile_size, gp.tile_size)
	down1 = setup("/monster/slime_down01", gp.tile_size, gp.tile_size)
	down2 = setup("/monster/slime_down02", gp.tile_size, gp.tile_size)
	left1 = setup("/monster/slime_down01", gp.tile_size, gp.tile_size)
	left2 = setup("/monster/slime_down02", gp.tile_size, gp.tile_size)
	right1 = setup("/monster/slime_down01", gp.tile_size, gp.tile_size)
	right2 = setup("/monster/slime_down02", gp.tile_size, gp.tile_size)


func set_action() -> void:

	action_lock_counter += 1

	if action_lock_counter == 120:
		var i: int = randi() % 100 + 1  # pick a number between 1 and 100

		if i < 25: direction = "up"
		if i > 25 and i <= 50: direction = "down"
		if i > 50 and i <= 75: direction = "left"
		if i > 75 and i <= 100: direction = "right"

		action_lock_counter = 0


func damage_reaction() -> void:
	action_lock_counter = 0
	direction = gp.player.direction


func check_drop() -> void:

	# CAST A DIE
	var i: int = randi() % 100 + 1

	# SET THE MONSTER DROP
	if i < 50:
		drop_item(OBJ_Coin.new(gp))
	if i >= 50 and i < 75:
		drop_item(OBJ_Potion_Green.new(gp))
	if i >= 75:
		drop_item(OBJ_ManaCrystal.new(gp))
