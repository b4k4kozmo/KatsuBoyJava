@tool
extends SceneTree
## Build step 2 of 2: turns the original res/maps/*.txt files and the hardcoded
## AssetSetter / EventHandler placements into editable Godot scenes.
##
## Run:  godot --headless --path . --script res://tools/build_maps.gd
##
## You should not need to run this again - from here on you edit the map scenes
## in scenes/maps/ directly. It is kept so the conversion is reproducible and so
## you can see exactly where the original data came from.

const COLS := 11          # tiles per row in the atlas
const TILE := 48
const TILE_COUNT := 44

## Which tile IDs block movement. Index matches tools/build_tileset.gd.
## After this runs, collision is edited in the TileSet editor instead
## (select a tile -> Custom Data -> collision).
const COLLISION := [
	false, false,                                              # grass
	false, false, false, false, false, false, false,           # road00-06
	false, false, false, false, false, false,                  # road07-12
	false,                                                     # sand
	true, true,                                                # tree, wall
	true, true, true, true, true, true, true,                  # water01-07
	true, true, true, true, true, true,                        # water08-13
	false,                                                     # wildmushroom
	true, true, true, false, true, true, true, true, true,     # wunderboat
	true, true, true,
]

const MAPS := [
	{"txt": "worldmap", "scene": "WorldMap"},
	{"txt": "mushroomhut", "scene": "MushroomHut"},
	{"txt": "testmap", "scene": "TestMap"},
]

const OBJECTS := {
	0: [
		["Kami Coin", 50, 97], ["Carbuncle", 52, 98], ["Key", 96, 96],
		["Kami Coin", 96, 97], ["Kami Coin", 97, 90], ["Kami no Bokken", 98, 98],
		["Kami Shield", 97, 98], ["Green Potion", 89, 97], ["Heart", 95, 91],
		["Kami Axe", 94, 91], ["Door", 85, 97], ["Chest", 91, 92],
		["Candle", 92, 92], ["Tent", 92, 93],
		# Not in the Java game: the Boots existed as an item but were never
		# placed anywhere, and picking them up did nothing. Now they unlock
		# running, so there is one on open grass near the start.
		["Boots", 93, 92],
	],
}

const NPCS := {
	0: [["OldMan", 96, 95]],
	1: [["NanaMan", 11, 23], ["Merchant", 26, 18]],
}

const MONSTERS := {
	0: [
		["Snome", 82, 95], ["Slime", 58, 79], ["Slime", 8, 55], ["Slime", 8, 51],
		["Slime", 8, 46], ["Slime", 8, 35], ["Slime", 84, 93], ["Snome", 80, 90],
		["Snome", 80, 88], ["Snome", 80, 87], ["Snome", 79, 87], ["Snome", 78, 87],
		["Snome", 77, 87], ["Snome", 77, 86], ["Snome", 76, 86], ["Snome", 77, 85],
		["Snome", 76, 87], ["Kamijack", 88, 77], ["Kamijack", 92, 73],
		["Kamijack", 27, 79], ["Kamijack", 79, 52], ["Kamijack", 66, 45],
		["Shadow", 7, 59],
	],
}

const INTERACTIVE := {
	0: [["DryTree", 86, 97]],
}

## kind, col, row, direction, target_map, target_col, target_row, speak_npc_node
const EVENTS := {
	0: [
		["DamagePit", 95, 95, "any", 0, 0, 0, ""],
		["HealingPool", 5, 71, "down", 0, 0, 0, ""],
		["Teleport", 97, 97, "any", 0, 5, 70, ""],
		["ChangeMap", 8, 46, "any", 1, 26, 32, ""],
		["ChangeMap", 10, 9, "up", 2, 82, 67, ""],
	],
	1: [
		["ChangeMap", 26, 32, "any", 0, 8, 46, ""],
		["Speak", 26, 20, "up", 0, 0, 0, "../../NPCs/Merchant"],
	],
	2: [
		["ChangeMap", 82, 67, "any", 0, 10, 9, ""],
	],
}


func _init() -> void:
	var tile_set := build_tile_set()
	for i in range(MAPS.size()):
		build_map(i, tile_set)
	print("done")
	quit()


func build_tile_set() -> TileSet:

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "collision")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)

	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/katsuboy_atlas.png")
	src.texture_region_size = Vector2i(TILE, TILE)

	# The source has to belong to the TileSet before we touch TileData, or the
	# custom data layers are not visible to it yet.
	ts.add_source(src, 0)

	for i in range(TILE_COUNT):
		@warning_ignore("integer_division")
		var coords := Vector2i(i % COLS, i / COLS)
		src.create_tile(coords)
		var data: TileData = src.get_tile_data(coords, 0)
		data.set_custom_data("collision", COLLISION[i])

	var err := ResourceSaver.save(ts, "res://assets/tiles/katsuboy_tileset.tres")
	print("tileset saved, %d tiles, err=%d" % [TILE_COUNT, err])
	return ts


func build_map(index: int, tile_set: TileSet) -> void:

	var info: Dictionary = MAPS[index]

	var root := Node2D.new()
	root.name = info["scene"]

	# --- tiles -------------------------------------------------------------
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = tile_set
	root.add_child(layer)
	layer.owner = root

	var file := FileAccess.open("res://assets/maps/%s.txt" % info["txt"], FileAccess.READ)
	var row := 0
	while file != null and not file.eof_reached() and row < 100:
		var line: String = file.get_line().strip_edges()
		if line == "":
			continue
		var numbers: PackedStringArray = line.split(" ", false)
		for col in range(mini(numbers.size(), 100)):
			var id: int = int(numbers[col])
			@warning_ignore("integer_division")
			layer.set_cell(Vector2i(col, row), 0, Vector2i(id % COLS, id / COLS))
		row += 1
	if file != null:
		file.close()

	# --- placement markers -------------------------------------------------
	add_group(root, "Objects", OBJECTS.get(index, []), func(entry):
		var m := ObjectMarker.new()
		m.item = entry[0]
		if entry[0] == "Chest":
			m.chest_loot = "Key"
		return m)

	add_group(root, "NPCs", NPCS.get(index, []), func(entry):
		var m := NpcMarker.new()
		m.npc = entry[0]
		return m)

	add_group(root, "Monsters", MONSTERS.get(index, []), func(entry):
		var m := MonsterMarker.new()
		m.monster = entry[0]
		return m)

	add_group(root, "InteractiveTiles", INTERACTIVE.get(index, []), func(entry):
		var m := InteractiveTileMarker.new()
		m.kind = entry[0]
		return m)

	var events := Node2D.new()
	events.name = "Events"
	root.add_child(events)
	events.owner = root
	for entry in EVENTS.get(index, []):
		var m := EventMarker.new()
		m.kind = entry[0]
		m.required_direction = entry[3]
		m.target_map = entry[4]
		m.target_col = entry[5]
		m.target_row = entry[6]
		if entry[7] != "":
			m.speak_npc = NodePath(entry[7])
		m.position = Vector2(entry[1] * TILE, entry[2] * TILE)
		m.name = entry[0]
		events.add_child(m, true)
		m.owner = root

	# where a new game begins
	if index == 0:
		var start := PlayerStartMarker.new()
		start.name = "PlayerStart"
		start.position = Vector2(94 * TILE, 94 * TILE)
		root.add_child(start)
		start.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	var path := "res://scenes/maps/%s.tscn" % info["scene"]
	var err := ResourceSaver.save(packed, path)
	print("%s: %d rows of tiles, err=%d" % [path, row, err])


func add_group(root: Node2D, group_name: String, entries: Array, make: Callable) -> void:

	var group := Node2D.new()
	group.name = group_name
	root.add_child(group)
	group.owner = root

	for entry in entries:
		var m: PlacementMarker = make.call(entry)
		m.position = Vector2(entry[1] * TILE, entry[2] * TILE)
		# Plain readable names - Godot appends 2, 3, ... for repeats.
		m.name = str(entry[0]).replace(" ", "")
		group.add_child(m, true)
		m.owner = root
