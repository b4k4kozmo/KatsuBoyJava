class_name TileManager
extends RefCounted
## Java: tile/TileManager.java
##
## The tiles themselves are now a Godot TileSet painted onto TileMapLayer nodes
## in scenes/maps/*.tscn, and those layers do the actual rendering. What this
## class still does - and what the rest of the game still reads - is unchanged:
##
##   tile[id].image      the 48x48 picture (used by the mini map)
##   tile[id].collision  whether it blocks movement (CollisionChecker, PathFinder)
##   map_tile_num[map][col][row]   the tile id at a grid position
##
## A tile's id is its position in the atlas: id = atlas_y * ATLAS_COLS + atlas_x.
## That is the same numbering the old assets/maps/*.txt files used.

## Tiles per row in assets/tiles/katsuboy_atlas.png.
const ATLAS_COLS := 11

var gp
var tile: Array = []           # Tile, indexed by tile id
var map_tile_num: Array = []   # [map][max_world_col][max_world_row]
var draw_path: bool = false


func _init(gp) -> void:
	self.gp = gp

	map_tile_num = []
	for _m in range(gp.max_map):
		var cols: Array = []
		for _c in range(gp.max_world_col):
			var rows: Array = []
			rows.resize(gp.max_world_row)
			rows.fill(0)
			cols.append(rows)
		map_tile_num.append(cols)

	get_tile_image()
	for i in range(gp.max_map):
		load_map(i)


## The TileMapLayer that holds map `map`, or null if that slot is empty.
func tiles_layer(map: int) -> TileMapLayer:
	if map < 0 or map >= gp.map_node.size() or gp.map_node[map] == null:
		return null
	return gp.map_node[map].get_node_or_null("Tiles") as TileMapLayer


## Read every tile's picture and collision flag out of the TileSet.
## Collision is the "collision" custom data layer - select a tile in the TileSet
## editor and tick it there instead of editing code.
func get_tile_image() -> void:

	var tile_set: TileSet = null
	for i in range(gp.max_map):
		var layer := tiles_layer(i)
		if layer != null and layer.tile_set != null:
			tile_set = layer.tile_set
			break

	if tile_set == null:
		push_error("No TileSet found. Does map 0 have a TileMapLayer named 'Tiles'?")
		return

	var source: TileSetAtlasSource = tile_set.get_source(tile_set.get_source_id(0)) as TileSetAtlasSource
	if source == null or source.texture == null:
		push_error("The TileSet's first source is not an atlas with a texture.")
		return

	var atlas: Image = source.texture.get_image()
	if atlas.is_compressed():
		atlas.decompress()

	@warning_ignore("integer_division")
	var atlas_rows: int = atlas.get_height() / gp.tile_size
	tile.resize(ATLAS_COLS * atlas_rows)

	for i in range(source.get_tiles_count()):
		var coords: Vector2i = source.get_tile_id(i)
		var id: int = coords.y * ATLAS_COLS + coords.x
		if id < 0 or id >= tile.size():
			continue

		var t := Tile.new()
		var region := Rect2i(coords.x * gp.tile_size, coords.y * gp.tile_size,
				gp.tile_size, gp.tile_size)
		t.image = ImageTexture.create_from_image(atlas.get_region(region))
		var data: TileData = source.get_tile_data(coords, 0)
		if data != null:
			t.collision = bool(data.get_custom_data("collision"))
		tile[id] = t

	# Any id the atlas does not define falls back to tile 0, so a stray tile
	# number can never take the game down.
	for i in range(tile.size()):
		if tile[i] == null:
			tile[i] = tile[0]


## Copy the painted TileMapLayer into map_tile_num, which is what collision and
## the pathfinder read. An unpainted cell counts as tile 0.
func load_map(map: int) -> void:

	var layer := tiles_layer(map)
	if layer == null:
		return

	for col in range(gp.max_world_col):
		for row in range(gp.max_world_row):
			var coords: Vector2i = layer.get_cell_atlas_coords(Vector2i(col, row))
			if coords == Vector2i(-1, -1):
				map_tile_num[map][col][row] = 0
			else:
				map_tile_num[map][col][row] = coords.y * ATLAS_COLS + coords.x


## The tiles draw themselves now (the TileMapLayer nodes under GamePanel/World),
## so all that is left here is the debug path overlay - press T in game.
func draw(g2) -> void:

	if draw_path == true:
		g2.set_color(Color8(194, 92, 177, 70))  # half transparent kamipink

		for i in range(gp.p_finder.path_list.size()):

			var world_x: int = gp.p_finder.path_list[i].col * gp.tile_size
			var world_y: int = gp.p_finder.path_list[i].row * gp.tile_size
			var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
			var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

			g2.fill_rect(screen_x, screen_y, gp.tile_size, gp.tile_size)
