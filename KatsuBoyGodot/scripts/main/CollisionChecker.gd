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


func check_tile(entity) -> void:

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

	match direction:
		"up":
			entity_top_row = (entity_top_world_y - entity.speed) / gp.tile_size
			if (tile_collision(entity_left_col, entity_top_row)
					or tile_collision(entity_right_col, entity_top_row)):
				entity.collision_on = true
		"down":
			entity_bottom_row = (entity_bottom_world_y + entity.speed) / gp.tile_size
			if (tile_collision(entity_left_col, entity_bottom_row)
					or tile_collision(entity_right_col, entity_bottom_row)):
				entity.collision_on = true
		"left":
			entity_left_col = (entity_left_world_x - entity.speed) / gp.tile_size
			if (tile_collision(entity_left_col, entity_top_row)
					or tile_collision(entity_left_col, entity_bottom_row)):
				entity.collision_on = true
		"right":
			entity_right_col = (entity_right_world_x + entity.speed) / gp.tile_size
			if (tile_collision(entity_right_col, entity_top_row)
					or tile_collision(entity_right_col, entity_bottom_row)):
				entity.collision_on = true
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
