class_name MON_KamiJack
extends Entity
## Java: monster/MON_KamiJack.java


const STATS := preload("res://assets/data/monsters/kamijack.tres")


func _init(gp) -> void:
	super(gp)

	# Numbers live in the resource so they can be tuned in the Inspector.
	STATS.apply_to(self)

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
