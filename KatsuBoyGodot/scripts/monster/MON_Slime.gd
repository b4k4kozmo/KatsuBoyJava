class_name MON_Slime
extends Entity
## Java: monster/MON_Slime.java


const STATS := preload("res://assets/data/monsters/slime.tres")


func _init(gp) -> void:
	super(gp)

	# Numbers live in the resource so they can be tuned in the Inspector.
	STATS.apply_to(self)

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


## The bottom of the money ladder: small change, often, from something that
## dies in two hits. See ROADMAP.md for what a sweep of the map is worth.
func check_drop() -> void:

	var i: int = randi() % 100 + 1

	if i <= 55:
		drop_item(OBJ_Coin.worth(gp, randi_range(1, 3)))
	elif i <= 65:
		drop_item(OBJ_Coin.worth(gp, OBJ_Coin.PURSE))
	elif i <= 85:
		drop_item(OBJ_Potion_Green.new(gp))
	else:
		drop_item(OBJ_ManaCrystal.new(gp))
