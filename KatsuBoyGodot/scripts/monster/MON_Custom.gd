class_name MON_Custom
extends Entity
## A monster built entirely from a MonsterStats resource - no script of its own.
##
## This is the answer to "how do I add a monster without touching code": make a
## .tres in assets/data/monsters/, fill in its numbers, drop two PNGs into the
## Looks group, pick a Behaviour, write a drop table, then drag the resource
## into a MonsterMarker's "Stats" slot with Monster set to "From Stats".
##
## The four behaviours below cover what the hand-written monsters do. Anything
## stranger than these - a boss with phases, something that splits when it dies
## - still wants its own script in this folder. That is the line: data for the
## shapes the engine already knows, code for a new shape.

var stats: MonsterStats


func _init(gp, monster_stats: MonsterStats) -> void:
	super(gp)

	stats = monster_stats
	if stats == null:
		# A marker with an empty Stats slot. Better a visible placeholder than
		# a crash or an invisible monster nothing can explain.
		name = "Unnamed"
		max_life = 1
		life = 1
		return

	stats.apply_to(self)
	stats.build_images(self, gp.tile_size)

	if stats.behaviour == "Shooter":
		projectile = (OBJ_Snowball.new(gp) if stats.projectile == "Snow-ball"
				else OBJ_Shuriken.new(gp))


func set_action() -> void:

	if stats == null:
		return

	match stats.behaviour:
		"Chaser", "Fighter", "Shooter":
			_hunt()
		_:
			_drift()


## Pick a new direction every two seconds and amble off in it.
func _drift() -> void:
	action_lock_counter += 1
	if action_lock_counter >= 120:
		get_random_direction()
		action_lock_counter = 0


## Walk the path to the player while they are close, swing when they are in
## reach, throw when the behaviour says to.
func _hunt() -> void:

	if on_path:
		check_stop_chasing(gp.player, stats.give_up_distance, 100)
		search_path(get_goal_col(gp.player), get_goal_row(gp.player))
		if stats.behaviour == "Shooter":
			check_shooting(200, stats.shot_interval)
	else:
		check_start_chasing(gp.player, stats.notice_distance, 100)
		get_random_direction()

	# Only something with a swing defined can swing. A Chaser leaves the melee
	# fields at zero and hurts by walking into you, like a Kamijack.
	if not attacking and stats.behaviour != "Chaser" and stats.attack_area.size.x > 0:
		check_attacking(stats.swing_interval, gp.tile_size * 4, gp.tile_size)


func damage_reaction() -> void:
	action_lock_counter = 0
	if stats != null and stats.behaviour != "Wander":
		on_path = true
	else:
		direction = gp.player.direction


func check_drop() -> void:
	if stats == null:
		return
	var loot: Entity = stats.roll_drop(gp)
	if loot != null:
		drop_item(loot)
