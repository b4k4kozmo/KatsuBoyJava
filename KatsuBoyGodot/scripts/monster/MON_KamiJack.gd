class_name MON_KamiJack
extends Entity
## Java: monster/MON_KamiJack.java


const STATS := preload("res://assets/data/monsters/kamijack.tres")


func _init(gp) -> void:
	super(gp)

	# Numbers live in the resource so they can be tuned in the Inspector.
	#
	# They were retuned in the Godot port. The Java version gave this thing
	# 111 life, 6 defence, 20 attack and speed 12, which against a starting
	# player - 3 hearts, attack 1 - meant it could not be damaged at all, could
	# not be outrun, and killed in one touch. Five of them wander the world map
	# near the start. Edit kamijack.tres to take it back the other way.
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
	# Reels for two seconds after a hit. Entity.tick_slow_down() puts the speed
	# back - Java set this counter and never counted it down, so one hit left a
	# Kamijack crawling for the rest of its life.
	speed = 2
	slow_down = 120


## The dangerous one on the starting map, so it is also the profitable one -
## clearing the three by the shore is most of a boat ticket.
func check_drop() -> void:

	var i: int = randi() % 100 + 1

	if i <= 45:
		drop_item(OBJ_Coin.worth(gp, randi_range(15, 25)))
	elif i <= 75:
		drop_item(OBJ_Coin.worth(gp, 8))
	elif i <= 90:
		drop_item(OBJ_Potion_Green.new(gp))
	else:
		drop_item(OBJ_Heart.new(gp))
