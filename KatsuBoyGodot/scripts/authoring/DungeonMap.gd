@icon("res://assets/tiles/wunderboat1.png")
@tool
class_name DungeonMap
extends Node2D
## The root of a map scene. Put this script on the root node and the rest of the
## map builds and checks itself.
##
## Without it a map is a bare Node2D with five child nodes whose names have to be
## spelled exactly right, a TileMapLayer that has to be called "Tiles", a tile
## set that has to be dragged in by hand, and a DungeonInfo somewhere else whose
## map index and arrival tile have to be typed in and kept in step. Every one of
## those is a way to build a map that loads fine and then does not work.
##
## With it:
##
##   * **Set up this map** creates the Tiles layer with the shared tile set and
##     the five group nodes, if they are not there already.
##   * **Check this map** walks everything and reports what is wrong, in the
##     Output panel and as a warning triangle on the node.
##   * **Paint the border** fills the edges so the camera never shows void.
##   * Dropping a DungeonInfo into **Dungeon Info** is all the boat needs: the
##     map number and the arrival tile are worked out from the scene itself.
##
## Nothing here runs in the game. It is all editor furniture, like the markers.

const TILE := 48
const TILESET_PATH := "res://assets/tiles/katsuboy_tileset.tres"
## The five nodes AssetSetter looks for, in the order they should appear.
const GROUPS := ["Objects", "NPCs", "Monsters", "InteractiveTiles", "Events"]

## Which place on the boat's timetable this map is, if it is one. Drop a
## resource from assets/data/dungeons/ in here and the map number and the
## arrival tile stop being something you have to type: the map number is where
## this scene sits in GamePanel's Map Scenes list, and the arrival tile is
## wherever the Boat marker is.
##
## Leave it empty for a map the boat does not go to, like a shop interior.
@export var dungeon_info: DungeonInfo:
	set(value):
		dungeon_info = value
		update_configuration_warnings()

@export_group("Tools")
## Creates the Tiles layer and the five group nodes if they are missing.
@export_tool_button("Set up this map", "Add") var setup_action = _setup_map
## Reports everything wrong with this map in the Output panel.
@export_tool_button("Check this map", "Search") var check_action = _report
## Fills the outside edges so the camera never shows empty space. Water where
## the map already has water at the edge, trees otherwise.
@export_tool_button("Paint the border", "TileMap") var border_action = _paint_border
## Snaps every marker on the map to the nearest tile.
@export_tool_button("Tidy up the markers", "Snap") var tidy_action = _tidy_up

@export_group("Border painting")
## How many tiles of border to paint outside the map's own edges.
@export_range(1, 12) var border_width: int = 6
## What to frame the map with.
##
##   Match the edge  repeats whichever tile is already at the nearest edge, so
##                   water runs out to sea and a forest keeps being forest.
##   One tile        uses Border Tile below for the whole frame.
@export_enum("Match the edge", "One tile")
var border_style: String = "Match the edge"

## The tile to frame with when Border Style is "One tile", as a column and row
## in the sheet. Coordinates rather than a tile number, because a number means
## something different the moment the sheet changes width - and a sheet is a
## picture somebody redraws.
@export var border_tile: Vector2i = Vector2i(7, 1)


# ---------------------------------------------------------------- the tools

func _setup_map() -> void:

	var made: Array[String] = []

	if tiles_layer() == null:
		var layer := TileMapLayer.new()
		layer.name = "Tiles"
		if ResourceLoader.exists(TILESET_PATH):
			layer.tile_set = load(TILESET_PATH)
		add_child(layer)
		move_child(layer, 0)
		layer.owner = _scene_owner()
		made.append("Tiles")

	for group_name in GROUPS:
		if get_node_or_null(group_name) == null:
			var g := Node2D.new()
			g.name = group_name
			add_child(g)
			g.owner = _scene_owner()
			made.append(group_name)

	if made.is_empty():
		print("[%s] already set up - nothing to add." % name)
	else:
		print("[%s] added: %s" % [name, ", ".join(made)])
	update_configuration_warnings()


func _report() -> void:
	var problems: PackedStringArray = _problems()
	if problems.is_empty():
		print("[%s] looks good: %d markers, %d painted tiles." % [
			name, _all_markers().size(), _painted_count()])
	else:
		print("[%s] %d problem(s):" % [name, problems.size()])
		for p in problems:
			print("   - " + p)
	update_configuration_warnings()


## Paint a frame of scenery around whatever has been painted, so the camera
## never shows the void past the edge of the map. Out of bounds already counts
## as solid, so this is decoration, not collision.
func _paint_border() -> void:

	var layer := tiles_layer()
	if layer == null:
		print("[%s] no Tiles layer - press 'Set up this map' first." % name)
		return

	var used: Rect2i = layer.get_used_rect()
	if used.size == Vector2i.ZERO:
		print("[%s] nothing painted yet - paint some floor first." % name)
		return

	var source_id: int = layer.get_cell_source_id(used.position)
	if source_id == -1:
		source_id = 0

	var painted := 0
	for row in range(used.position.y - border_width, used.end.y + border_width):
		for col in range(used.position.x - border_width, used.end.x + border_width):
			if layer.get_cell_source_id(Vector2i(col, row)) != -1:
				continue

			var tile_coords: Vector2i = border_tile
			if border_style == "Match the edge":
				# Whatever is painted at the nearest point inside the map. No
				# list of which tile numbers count as water: the map already
				# knows what its own edge looks like.
				var near := Vector2i(clampi(col, used.position.x, used.end.x - 1),
						clampi(row, used.position.y, used.end.y - 1))
				var found: Vector2i = layer.get_cell_atlas_coords(near)
				if found != Vector2i(-1, -1):
					tile_coords = found

			layer.set_cell(Vector2i(col, row), source_id, tile_coords)
			painted += 1

	print("[%s] painted %d border tiles, %s." % [name, painted,
			"matching the edge" if border_style == "Match the edge"
			else "all %s" % str(border_tile)])


## Snap every marker to the tile it is nearest, so what the editor shows is
## what the game builds. Markers a few pixels off look aligned and are not, and
## that is how two things quietly end up on one tile.
func _tidy_up() -> void:

	var moved := 0
	for m in _all_markers():
		if not m.is_on_grid():
			m.snap_to_grid()
			moved += 1

	var start := get_node_or_null("PlayerStart")
	if start is PlacementMarker and not start.is_on_grid():
		start.snap_to_grid()
		moved += 1

	print("[%s] snapped %d marker(s) to the grid." % [name, moved])
	update_configuration_warnings()


# ---------------------------------------------------------------- checking

func _get_configuration_warnings() -> PackedStringArray:
	return _problems()


## Everything wrong with this map, in plain words.
func _problems() -> PackedStringArray:

	var out := PackedStringArray()
	var layer := tiles_layer()

	if layer == null:
		out.append("No TileMapLayer called 'Tiles'. Press 'Set up this map'.")
	elif layer.tile_set == null:
		out.append("The Tiles layer has no tile set. Press 'Set up this map'.")
	elif layer.get_used_rect().size == Vector2i.ZERO:
		out.append("Nothing is painted yet.")

	for group_name in GROUPS:
		if get_node_or_null(group_name) == null:
			out.append("Missing the '%s' node. Press 'Set up this map'." % group_name)

	# Slots per map, matching the arrays GamePanel builds.
	var limits := {"Objects": 40, "NPCs": 10, "Monsters": 80, "InteractiveTiles": 50}
	for group_name in limits.keys():
		var n: int = _markers_in(group_name).size()
		if n > int(limits[group_name]):
			out.append("%d markers under %s, but only %d fit. The rest are ignored." % [
				n, group_name, limits[group_name]])

	# Two things on one tile, where one of them is solid.
	var seen := {}
	for m in _all_markers():
		var key: String = "%d,%d" % [m.tile_col(), m.tile_row()]
		if seen.has(key):
			var other = seen[key]
			if is_solid_marker(m) or is_solid_marker(other):
				out.append("%s and %s are on the same tile (%s) and one of them is solid." % [
					other.name, m.name, key])
		else:
			seen[key] = m

	# Anything standing in a wall, over its whole footprint - a two-tile monster
	# with its head in the open and its body in a wall cannot move.
	if layer != null:
		for m in _all_markers():
			if m is EventMarker:
				continue    # a teleport under a wall is odd but legal
			var span: int = maxi(m.marker_tiles(), 1)
			for dx in range(span):
				for dy in range(span):
					var col: int = m.tile_col() + dx
					var row: int = m.tile_row() + dy
					if tile_is_solid(col, row):
						out.append("%s is on a solid tile (%d,%d) - nothing can reach it."
								% [m.name, col, row])
						dx = span
						break

	# A door with no key on the map, wherever the key is hiding.
	var doors := 0
	for m in _markers_in("Objects"):
		if m is ObjectMarker and m.item == "Door":
			doors += 1
	if doors > 0 and not has_object("Key") and not has_chest_loot("Key"):
		out.append("%d locked door(s) and no Key on this map." % doors)

	if dungeon_info != null:
		if dungeon_info.id.is_empty():
			out.append("The DungeonInfo has no id.")
		if boat_dock() == null and not dungeon_info.is_home_port:
			out.append("No Boat marker, so there is no way off this map. Add an "
					+ "EventMarker with Kind = Boat and Dock Of = '%s'." % dungeon_info.id)
		elif boat_dock() != null and boat_dock().dock_of != dungeon_info.id:
			out.append("The Boat marker says Dock Of = '%s' but this map is '%s'." % [
				boat_dock().dock_of, dungeon_info.id])

		# A dungeon with no boss can never be ticked off, so the game waits
		# forever for it and the ending never unlocks.
		if not dungeon_info.is_home_port and not dungeon_info.is_victory:
			var boss := boss_marker()
			if boss == null:
				out.append("No Boss marker, so '%s' can never be cleared and the "
						% dungeon_info.id + "ending never unlocks.")
			elif boss.boss_dungeon_id != dungeon_info.id:
				out.append("The Boss says it guards '%s' but this map is '%s'." % [
					boss.boss_dungeon_id, dungeon_info.id])

	return out


# ---------------------------------------------------------------- lookups

func tiles_layer() -> TileMapLayer:
	return get_node_or_null("Tiles") as TileMapLayer


## The Boat marker on this map, if it has one. Its tile is where the player
## lands, so nothing has to be typed into the DungeonInfo.
func boat_dock() -> EventMarker:
	for m in _markers_in("Events"):
		if m is EventMarker and m.kind == "Boat":
			return m
	return null


## Where the boat puts the player down, in tiles.
func arrival_tile() -> Vector2i:
	var dock := boat_dock()
	if dock != null:
		return Vector2i(dock.tile_col(), dock.tile_row())
	var start := get_node_or_null("PlayerStart")
	if start is PlacementMarker:
		return Vector2i(start.tile_col(), start.tile_row())
	return Vector2i(-1, -1)


## Every marker under a group, however deeply nested, matching what AssetSetter
## picks up at run time.
func _markers_in(group_name: String) -> Array:
	var group: Node = get_node_or_null(group_name)
	if group == null:
		return []
	var out: Array = []
	_gather(group, out)
	return out


func _gather(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is PlacementMarker:
			out.append(child)
		if child.get_child_count() > 0:
			_gather(child, out)


func _all_markers() -> Array:
	var out: Array = []
	for group_name in GROUPS:
		out.append_array(_markers_in(group_name))
	return out


func _painted_count() -> int:
	var layer := tiles_layer()
	return 0 if layer == null else layer.get_used_cells().size()


## Is the tile at col,row something you cannot walk through? Out of bounds and
## unpainted both count as solid, because that is how TileManager treats them.
func tile_is_solid(col: int, row: int) -> bool:
	var layer := tiles_layer()
	if layer == null:
		return false     # nothing painted yet: do not cry wolf about every marker
	var data: TileData = layer.get_cell_tile_data(Vector2i(col, row))
	if data == null:
		return true
	return bool(data.get_custom_data("collision"))


## Every marker standing on one tile, including markers under sub-groups.
func markers_on_tile(col: int, row: int) -> Array:
	var out: Array = []
	for m in _all_markers():
		if m.tile_col() == col and m.tile_row() == row:
			out.append(m)
	return out


## Is there one of these items lying on the floor somewhere on this map?
func has_object(item_name: String) -> bool:
	for m in _markers_in("Objects"):
		if m is ObjectMarker and m.item == item_name:
			return true
	return false


## Is there one of these inside a chest on this map?
func has_chest_loot(item_name: String) -> bool:
	for m in _markers_in("Objects"):
		if m is ObjectMarker and m.item == "Chest" and m.chest_loot == item_name:
			return true
	return false


## The boss marker on this map, if it has one.
func boss_marker() -> MonsterMarker:
	for m in _markers_in("Monsters"):
		if m is MonsterMarker and m.monster == "Boss":
			return m
	return null


## Does this marker block the tile it stands on? A chest or a door does; a coin
## lying on the floor does not, so a coin on a doorway is fine and a chest on
## one walls the dungeon off.
func is_solid_marker(m) -> bool:
	if m is InteractiveTileMarker:
		return true
	if m is ObjectMarker:
		return m.item == "Door" or m.item == "Chest"
	return false


## Nodes added by a tool button have to belong to the scene being edited, or
## they vanish the moment it is saved.
func _scene_owner() -> Node:
	return self if owner == null else owner
