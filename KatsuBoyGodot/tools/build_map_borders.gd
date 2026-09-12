@tool
extends SceneTree
## Paints a decorative border of terrain around every map.
##
## Run: godot --headless --path . --script res://tools/build_map_borders.gd
##
## Why this exists: the camera always centres on the player and never clamps to
## the map, so standing anywhere near a map edge showed black past it. The
## player starts on tile (94, 94) of a 100x100 world, six tiles from the
## corner, so the very first thing you saw was a black band down the right.
##
## The border sits OUTSIDE the 0..99 world the game actually simulates.
## CollisionChecker.tile_collision() already treats anything out of those
## bounds as solid, so the player can never walk into this and nothing about
## collision, pathfinding or the map screen changes. It is purely what the
## camera sees when it looks past the edge.
##
## Each border cell copies the nearest real map cell: water continues as water,
## everything else becomes tree line, so the world reads as carrying on rather
## than stopping.
##
## Re-running is safe - it overwrites the same cells with the same result.

const MAPS := ["WorldMap", "MushroomHut", "TestMap"]

## World the game simulates, from GamePanel.max_world_col / max_world_row.
const MAP_W := 100
const MAP_H := 100

## How far out to paint. The screen is 20x12 tiles and the camera centres on the
## player, so standing on column 0 looks 10 columns into the void. 12 covers
## that with room to spare on both axes.
const BORDER := 12

## Columns in the tile atlas, matching build_tileset.gd.
const ATLAS_COLS := 11

## Tile ids from build_tileset.gd's TILE_NAMES order.
const TREE_ID := 16
const WATER_FIRST := 18   # water01
const WATER_LAST := 30    # water13


func atlas_coords(tile_id: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(tile_id % ATLAS_COLS, tile_id / ATLAS_COLS)


func tile_id_at(layer: TileMapLayer, cell: Vector2i) -> int:
	var coords: Vector2i = layer.get_cell_atlas_coords(cell)
	if coords == Vector2i(-1, -1):
		return 0
	return coords.y * ATLAS_COLS + coords.x


func _init() -> void:
	for map_name in MAPS:
		var path := "res://scenes/maps/%s.tscn" % map_name
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("could not load " + path)
			continue

		var root: Node = packed.instantiate()
		var layer := root.get_node_or_null("Tiles") as TileMapLayer
		if layer == null:
			push_error("%s has no TileMapLayer named 'Tiles'" % map_name)
			root.free()
			continue

		var source_id: int = layer.tile_set.get_source_id(0)

		# Snapshot the real map first. Painting and sampling in one pass would
		# let freshly painted border cells become the source for cells further
		# out, smearing one edge tile across the whole margin.
		var edge_ids := {}
		for col in range(-BORDER, MAP_W + BORDER):
			for row in range(-BORDER, MAP_H + BORDER):
				var inside := col >= 0 and col < MAP_W and row >= 0 and row < MAP_H
				if inside:
					continue
				var near := Vector2i(clampi(col, 0, MAP_W - 1), clampi(row, 0, MAP_H - 1))
				edge_ids[Vector2i(col, row)] = tile_id_at(layer, near)

		var water := 0
		var trees := 0
		for cell in edge_ids:
			var near_id: int = edge_ids[cell]
			var paint_id: int = TREE_ID
			if near_id >= WATER_FIRST and near_id <= WATER_LAST:
				paint_id = near_id   # keep the exact water variant
				water += 1
			else:
				trees += 1
			layer.set_cell(cell, source_id, atlas_coords(paint_id))

		var out := PackedScene.new()
		var err := out.pack(root)
		if err != OK:
			push_error("could not pack %s: %d" % [map_name, err])
			root.free()
			continue
		err = ResourceSaver.save(out, path)
		if err != OK:
			push_error("could not save %s: %d" % [map_name, err])
			root.free()
			continue

		var rect: Rect2i = layer.get_used_rect()
		print("%-13s +%d border cells (%d water, %d tree) -> used_rect pos=%s size=%s"
				% [map_name, edge_ids.size(), water, trees, rect.position, rect.size])
		root.free()

	print("done")
	quit()
