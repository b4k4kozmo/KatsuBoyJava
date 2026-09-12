class_name TileManager
extends RefCounted
## Java: tile/TileManager.java

var gp
var tile: Array = []           # Tile[50]
var map_tile_num: Array = []   # [max_map][max_world_col][max_world_row]
var draw_path: bool = false


func _init(gp) -> void:
	self.gp = gp

	tile.resize(50)
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
	load_map("/maps/worldmap.txt", 0)
	load_map("/maps/mushroomhut.txt", 1)
	load_map("/maps/testmap.txt", 2)


func get_tile_image() -> void:
	setup(0, "grass00", false)
	setup(1, "grass01", false)
	setup(2, "road00", false)
	setup(3, "road01", false)
	setup(4, "road02", false)
	setup(5, "road03", false)
	setup(6, "road04", false)
	setup(7, "road05", false)
	setup(8, "road06", false)
	setup(9, "road07", false)
	setup(10, "road08", false)
	setup(11, "road09", false)
	setup(12, "road10", false)
	setup(13, "road11", false)
	setup(14, "road12", false)
	setup(15, "sand", false)
	setup(16, "tree", true)
	setup(17, "wall", true)
	setup(18, "water01", true)
	setup(19, "water02", true)
	setup(20, "water03", true)
	setup(21, "water04", true)
	setup(22, "water05", true)
	setup(23, "water06", true)
	setup(24, "water07", true)
	setup(25, "water08", true)
	setup(26, "water09", true)
	setup(27, "water10", true)
	setup(28, "water11", true)
	setup(29, "water12", true)
	setup(30, "water13", true)
	setup(31, "wildmushroom", false)
	setup(32, "wunderboat1", true)
	setup(33, "wunderboat10", true)
	setup(34, "wunderboat11", true)
	setup(35, "wunderboat12", false)
	setup(36, "wunderboat2", true)
	setup(37, "wunderboat3", true)
	setup(38, "wunderboat4", true)
	setup(39, "wunderboat5", true)
	setup(40, "wunderboat6", true)
	setup(41, "wunderboat7", true)
	setup(42, "wunderboat8", true)
	setup(43, "wunderboat9", true)

	# Java left tile[44..49] null; a map file referencing one of those indices
	# would have crashed. Fill the rest with a copy of tile 0 so an out of range
	# tile number just shows grass instead of taking the game down.
	for i in range(tile.size()):
		if tile[i] == null:
			tile[i] = tile[0]


var u_tool := UtilityTool.new()


func setup(index: int, image_name: String, collision: bool) -> void:
	var t := Tile.new()
	var texture: Texture2D = load("res://assets/tiles/" + image_name + ".png")
	if texture == null:
		push_warning("Missing tile: " + image_name)
		return
	t.image = u_tool.scale_image(texture, gp.tile_size, gp.tile_size)
	t.collision = collision
	tile[index] = t


func load_map(file_path: String, map: int) -> void:

	var file := FileAccess.open("res://assets" + file_path, FileAccess.READ)
	if file == null:
		push_warning("Could not open map: " + file_path)
		return

	var row := 0
	while row < gp.max_world_row and not file.eof_reached():

		var line: String = file.get_line().strip_edges()
		if line == "":
			continue

		var numbers: PackedStringArray = line.split(" ", false)

		var col := 0
		while col < gp.max_world_col and col < numbers.size():
			map_tile_num[map][col][row] = int(numbers[col])
			col += 1

		row += 1

	file.close()


func draw(g2) -> void:

	# Java walked all 100 x 100 tiles every single frame and culled each one
	# individually. Only about 21 x 13 of them are ever on screen, so work out
	# that window up front - the tiles drawn are the same, it just skips the
	# ~9,700 tiles that were being tested and thrown away.
	@warning_ignore_start("integer_division")
	var start_col: int = (gp.player.world_x - gp.player.screen_x) / gp.tile_size - 1
	var end_col: int = (gp.player.world_x + gp.player.screen_x) / gp.tile_size + 1
	var start_row: int = (gp.player.world_y - gp.player.screen_y) / gp.tile_size - 1
	var end_row: int = (gp.player.world_y + gp.player.screen_y) / gp.tile_size + 1
	@warning_ignore_restore("integer_division")

	start_col = maxi(start_col, 0)
	start_row = maxi(start_row, 0)
	end_col = mini(end_col, gp.max_world_col - 1)
	end_row = mini(end_row, gp.max_world_row - 1)

	for world_col in range(start_col, end_col + 1):
		for world_row in range(start_row, end_row + 1):

			var tile_num: int = map_tile_num[gp.current_map][world_col][world_row]

			var world_x: int = world_col * gp.tile_size
			var world_y: int = world_row * gp.tile_size
			var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
			var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

			g2.draw_img(tile[tile_num].image, screen_x, screen_y)

	if draw_path == true:
		g2.set_color(Color8(194, 92, 177, 70))  # half transparent kamipink

		for i in range(gp.p_finder.path_list.size()):

			var world_x: int = gp.p_finder.path_list[i].col * gp.tile_size
			var world_y: int = gp.p_finder.path_list[i].row * gp.tile_size
			var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
			var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

			g2.fill_rect(screen_x, screen_y, gp.tile_size, gp.tile_size)
