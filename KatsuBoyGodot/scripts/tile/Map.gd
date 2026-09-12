class_name Map
extends TileManager
## Java: tile/Map.java
##
## Java had Map extend TileManager, which means it builds its own second copy of
## the tile set and the map data. Kept as is so the structure still matches -
## Godot caches the textures, so it costs almost nothing.

var world_map: Array[Texture2D] = []
var mini_map_on: bool = false


func _init(gp) -> void:
	super(gp)
	create_world_map()


## Java built these at full tile resolution - 4800x4800 pixels per map, ~92 MB
## each - for pictures only ever shown at 500x500. We render one small square
## per tile instead.
##
## 5 px per tile x 100 tiles = exactly the 500x500 the full map screen draws, so
## it is blitted 1:1 with no resampling, and the mini map takes a clean half of
## it. Any other number here means fractional scaling and uneven pixels.
const MAP_TILE_SIZE := 5
const FULL_MAP_SIZE := MAP_TILE_SIZE * 100    # 500
const MINI_MAP_SIZE := 250                    # exactly half of the full map


func create_world_map() -> void:

	world_map.resize(gp.max_map)
	var world_map_width: int = MAP_TILE_SIZE * gp.max_world_col
	var world_map_height: int = MAP_TILE_SIZE * gp.max_world_row

	# Shrink every tile once up front so the blits below are cheap.
	var small_tile: Array[Image] = []
	small_tile.resize(tile.size())
	for i in range(tile.size()):
		if tile[i] != null:
			var img: Image = tile[i].image.get_image()
			if img.is_compressed():
				img.decompress()
			img.resize(MAP_TILE_SIZE, MAP_TILE_SIZE, Image.INTERPOLATE_NEAREST)
			img.convert(Image.FORMAT_RGBA8)
			small_tile[i] = img

	for i in range(gp.max_map):

		var canvas := Image.create_empty(world_map_width, world_map_height, false, Image.FORMAT_RGBA8)

		var col := 0
		var row := 0
		while col < gp.max_world_col and row < gp.max_world_row:

			var tile_num: int = map_tile_num[i][col][row]
			var x: int = MAP_TILE_SIZE * col
			var y: int = MAP_TILE_SIZE * row
			if small_tile[tile_num] != null:
				canvas.blit_rect(small_tile[tile_num],
						Rect2i(0, 0, MAP_TILE_SIZE, MAP_TILE_SIZE), Vector2i(x, y))

			col += 1
			if col == gp.max_world_col:
				col = 0
				row += 1

		world_map[i] = ImageTexture.create_from_image(canvas)


func draw_full_map_screen(g2) -> void:

	g2.set_color(gp.ui.kamiblack)
	g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)

	# Draw Map, 1:1
	var width := FULL_MAP_SIZE
	var height := FULL_MAP_SIZE
	@warning_ignore("integer_division")
	var x: int = gp.screen_width / 2 - width / 2
	@warning_ignore("integer_division")
	var y: int = gp.screen_height / 2 - height / 2
	g2.draw_img_scaled(world_map[gp.current_map], x, y, width, height)

	# Draw Player
	var scale: float = float(gp.tile_size * gp.max_world_col) / width
	var player_x: int = int(x + gp.player.world_x / scale)
	var player_y: int = int(y + gp.player.world_y / scale)
	# 32 px = a clean 2x of the 16 px source sprite
	var player_size := 32
	g2.draw_img_scaled(gp.player.down1, player_x - 16, player_y - 16, player_size, player_size)

	# Hint
	g2.set_font(gp.ui.maru_monica, 32)
	g2.set_color(gp.ui.kamiwhite)
	g2.draw_str("Press M to close", 750, 550)


func draw_mini_map(g2) -> void:

	if mini_map_on == true:

		# Draw Map at exactly half size
		var width := MINI_MAP_SIZE
		var height := MINI_MAP_SIZE
		var x: int = gp.screen_width - width - 25
		var y := 25

		g2.change_alpha(0.7)
		g2.draw_img_scaled(world_map[gp.current_map], x, y, width, height)

		# Draw Player
		var scale: float = float(gp.tile_size * gp.max_world_col) / width
		var player_x: int = int(x + gp.player.world_x / scale)
		var player_y: int = int(y + gp.player.world_y / scale)
		# 16 px = the source sprite at 1:1
		var player_size := 16
		g2.draw_img_scaled(gp.player.down1, player_x - 8, player_y - 8, player_size, player_size)

		g2.change_alpha(1.0)
