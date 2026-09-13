class_name CollisionChecker
extends RefCounted
## Java: main/CollisionChecker.java

var gp


func _init(gp) -> void:
	self.gp = gp


## Java indexed mapTileNum directly, so walking off the edge of the 100x100
## world threw an ArrayIndexOutOfBounds. Treating anything outside the world as
## solid turns that crash into a wall.
func tile_collision(col: int, row: int) -> bool:
	if col < 0 or col >= gp.max_world_col or row < 0 or row >= gp.max_world_row:
		return true
	var tile_num: int = gp.tile_m.map_tile_num[gp.current_map][col][row]
	return gp.tile_m.tile[tile_num].collision


## `assist` is off when something is only *asking* whether a direction is
## blocked (see Entity.probe_blocked): a question should not move anybody.
func check_tile(entity, assist := true) -> void:

	var entity_left_world_x: int = entity.world_x + entity.solid_area.x
	var entity_right_world_x: int = entity.world_x + entity.solid_area.x + entity.solid_area.width
	var entity_top_world_y: int = entity.world_y + entity.solid_area.y
	var entity_bottom_world_y: int = entity.world_y + entity.solid_area.y + entity.solid_area.height

	@warning_ignore_start("integer_division")
	var entity_left_col: int = entity_left_world_x / gp.tile_size
	var entity_right_col: int = entity_right_world_x / gp.tile_size
	var entity_top_row: int = entity_top_world_y / gp.tile_size
	var entity_bottom_row: int = entity_bottom_world_y / gp.tile_size

	# Temporal when it's being knockbacked
	var direction: String = entity.direction
	if entity.knock_back == true:
		direction = entity.knock_back_direction

	# Which of the two leading corners is inside a wall. Both blocked means the
	# entity is squarely facing one; only one means it is clipping a corner,
	# which is what corner_assist() below fixes.
	var near_blocked := false
	var far_blocked := false

	match direction:
		"up":
			entity_top_row = (entity_top_world_y - entity.speed) / gp.tile_size
			near_blocked = tile_collision(entity_left_col, entity_top_row)
			far_blocked = tile_collision(entity_right_col, entity_top_row)
		"down":
			entity_bottom_row = (entity_bottom_world_y + entity.speed) / gp.tile_size
			near_blocked = tile_collision(entity_left_col, entity_bottom_row)
			far_blocked = tile_collision(entity_right_col, entity_bottom_row)
		"left":
			entity_left_col = (entity_left_world_x - entity.speed) / gp.tile_size
			near_blocked = tile_collision(entity_left_col, entity_top_row)
			far_blocked = tile_collision(entity_left_col, entity_bottom_row)
		"right":
			entity_right_col = (entity_right_world_x + entity.speed) / gp.tile_size
			near_blocked = tile_collision(entity_right_col, entity_top_row)
			far_blocked = tile_collision(entity_right_col, entity_bottom_row)
	@warning_ignore_restore("integer_division")

	if near_blocked or far_blocked:
		entity.collision_on = true

	# Exactly one corner in the wall: nudge sideways so the entity can round it.
	if assist and near_blocked != far_blocked:
		corner_assist(entity, direction, near_blocked)


## Slide an entity off a corner it is barely clipping.
##
## A doorway is one tile wide and the player's solid box is 32 of those 48
## pixels, so walking into a corridor a few pixels off centre used to stop the
## player dead against the door frame with no way to tell why. When only one of
## the two leading corners is inside a wall, and only by a little, this shifts
## the entity towards the open side by a pixel or two per frame - the movement
## itself is still blocked, but a couple of frames later the way is clear and
## the entity walks through. It is the standard "corner correction" every
## tile-based game needs; the Java original had none.
##
## Deliberately small: a big nudge would teleport entities around walls they are
## squarely facing, which is why the assist only applies while the overlap is
## under half the entity's box.
const ASSIST_MAX_OVERLAP := 22   ## px of corner overlap we are willing to fix
const ASSIST_STEP := 2           ## px moved per frame while fixing it

func corner_assist(entity, direction: String, near_blocked: bool) -> void:

	var left_x: int = entity.world_x + entity.solid_area.x
	var right_x: int = left_x + entity.solid_area.width
	var top_y: int = entity.world_y + entity.solid_area.y
	var bottom_y: int = top_y + entity.solid_area.height

	@warning_ignore_start("integer_division")
	var vertical: bool = direction == "up" or direction == "down"

	if vertical:
		# near = the left corner, far = the right corner.
		var overlap: int
		var push: int
		if near_blocked:
			# The left edge is in the wall, so slide right.
			overlap = ((left_x / gp.tile_size) + 1) * gp.tile_size - left_x
			push = ASSIST_STEP
		else:
			overlap = right_x - (right_x / gp.tile_size) * gp.tile_size
			push = -ASSIST_STEP

		if overlap <= 0 or overlap > mini(ASSIST_MAX_OVERLAP, entity.solid_area.width / 2):
			return

		# Do not nudge into a different wall.
		var probe_x: int = (left_x + push) if push < 0 else (right_x + push)
		if (tile_collision(probe_x / gp.tile_size, top_y / gp.tile_size)
				or tile_collision(probe_x / gp.tile_size, bottom_y / gp.tile_size)):
			return
		entity.world_x += push if absi(push) < overlap else (overlap * signi(push))
	else:
		# near = the top corner, far = the bottom corner.
		var overlap: int
		var push: int
		if near_blocked:
			overlap = ((top_y / gp.tile_size) + 1) * gp.tile_size - top_y
			push = ASSIST_STEP
		else:
			overlap = bottom_y - (bottom_y / gp.tile_size) * gp.tile_size
			push = -ASSIST_STEP

		if overlap <= 0 or overlap > mini(ASSIST_MAX_OVERLAP, entity.solid_area.height / 2):
			return

		var probe_y: int = (top_y + push) if push < 0 else (bottom_y + push)
		if (tile_collision(left_x / gp.tile_size, probe_y / gp.tile_size)
				or tile_collision(right_x / gp.tile_size, probe_y / gp.tile_size)):
			return
		entity.world_y += push if absi(push) < overlap else (overlap * signi(push))
	@warning_ignore_restore("integer_division")


func check_object(entity, player: bool) -> int:

	var index := 999

	for i in range(gp.obj[1].size()):

		if gp.obj[gp.current_map][i] != null:

			# Get entity's solid area position
			entity.solid_area.x = entity.world_x + entity.solid_area.x
			entity.solid_area.y = entity.world_y + entity.solid_area.y

			# Get the object's solid area position
			gp.obj[gp.current_map][i].solid_area.x = gp.obj[gp.current_map][i].world_x + gp.obj[gp.current_map][i].solid_area.x
			gp.obj[gp.current_map][i].solid_area.y = gp.obj[gp.current_map][i].world_y + gp.obj[gp.current_map][i].solid_area.y

			match entity.direction:
				"up": entity.solid_area.y -= entity.speed
				"down": entity.solid_area.y += entity.speed
				"left": entity.solid_area.x -= entity.speed
				"right": entity.solid_area.x += entity.speed

			if entity.solid_area.intersects(gp.obj[gp.current_map][i].solid_area):
				if gp.obj[gp.current_map][i].collision == true:
					entity.collision_on = true
				if player == true:
					index = i

			entity.solid_area.x = entity.solid_area_default_x
			entity.solid_area.y = entity.solid_area_default_y

			gp.obj[gp.current_map][i].solid_area.x = gp.obj[gp.current_map][i].solid_area_default_x
			gp.obj[gp.current_map][i].solid_area.y = gp.obj[gp.current_map][i].solid_area_default_y

	return index


## NPC OR MONSTER
func check_entity(entity, target: Array) -> int:

	var index := 999

	# Temporal when it's being knockbacked
	var direction: String = entity.direction
	if entity.knock_back == true:
		direction = entity.knock_back_direction

	for i in range(target[1].size()):

		if target[gp.current_map][i] != null:

			# Get entity's solid area position
			entity.solid_area.x = entity.world_x + entity.solid_area.x
			entity.solid_area.y = entity.world_y + entity.solid_area.y

			# Get the target's solid area position
			target[gp.current_map][i].solid_area.x = target[gp.current_map][i].world_x + target[gp.current_map][i].solid_area.x
			target[gp.current_map][i].solid_area.y = target[gp.current_map][i].world_y + target[gp.current_map][i].solid_area.y

			match direction:
				"up": entity.solid_area.y -= entity.speed
				"down": entity.solid_area.y += entity.speed
				"left": entity.solid_area.x -= entity.speed
				"right": entity.solid_area.x += entity.speed

			if entity.solid_area.intersects(target[gp.current_map][i].solid_area):
				if target[gp.current_map][i] != entity:
					entity.collision_on = true
					index = i

			entity.solid_area.x = entity.solid_area_default_x
			entity.solid_area.y = entity.solid_area_default_y

			target[gp.current_map][i].solid_area.x = target[gp.current_map][i].solid_area_default_x
			target[gp.current_map][i].solid_area.y = target[gp.current_map][i].solid_area_default_y

	return index


func check_player(entity) -> bool:

	var contact_player := false

	# Get entity's solid area position
	entity.solid_area.x = entity.world_x + entity.solid_area.x
	entity.solid_area.y = entity.world_y + entity.solid_area.y

	# Get the player's solid area position
	gp.player.solid_area.x = gp.player.world_x + gp.player.solid_area.x
	gp.player.solid_area.y = gp.player.world_y + gp.player.solid_area.y

	match entity.direction:
		"up": entity.solid_area.y -= entity.speed
		"down": entity.solid_area.y += entity.speed
		"left": entity.solid_area.x -= entity.speed
		"right": entity.solid_area.x += entity.speed

	if entity.solid_area.intersects(gp.player.solid_area):
		entity.collision_on = true
		contact_player = true

	entity.solid_area.x = entity.solid_area_default_x
	entity.solid_area.y = entity.solid_area_default_y
	gp.player.solid_area.x = gp.player.solid_area_default_x
	gp.player.solid_area.y = gp.player.solid_area_default_y

	return contact_player
