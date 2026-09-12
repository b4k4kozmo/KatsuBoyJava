extends SceneTree
## Builds dungeon map scenes from the descriptions in DUNGEONS below.
##
## Run it:
##   godot --headless --path . --script tools/build_dungeon_map.gd
##
## Hand-painting a 100x100 TileMapLayer is miserable, so this lays out rooms and
## corridors, carves them into the shared tileset, and drops in the markers a
## dungeon needs: the dock you arrive at, the monsters, the chests and the boss
## whose death clears the place. The result is an ordinary .tscn - open it in
## Godot afterwards and move anything you like, it is yours from then on.
##
## RE-RUNNING OVERWRITES the scene, so once you start editing a dungeon by hand,
## take it out of DUNGEONS (or change its "file") or you will lose your work.
##
## Adding a dungeon:
##   1. Add an entry to DUNGEONS.
##   2. Run this script.
##   3. Add the new scene to "Map Scenes" on GamePanel in main.tscn.
##   4. Make a DungeonInfo .tres pointing at that map index.
##   5. Add the .tres to GamePanel's "Dungeons".
## ROADMAP.md walks through it in more detail.

## Atlas ids, which are atlas_y * 11 + atlas_x. 15 is the speckled interior
## floor and 17 the brick wall, the same pair the Mushroom Hut uses.
const FLOOR := 15
const WALL := 17
const ROCK := 16   ## solid filler outside the dungeon, never seen

const TILESET_PATH := "res://assets/tiles/katsuboy_tileset.tres"
const SOURCE_MAP := "res://scenes/maps/WorldMap.tscn"

const MARKER_SCRIPTS := {
	"event": "res://scripts/authoring/EventMarker.gd",
	"monster": "res://scripts/authoring/MonsterMarker.gd",
	"object": "res://scripts/authoring/ObjectMarker.gd",
	"npc": "res://scripts/authoring/NpcMarker.gd",
}

const TILE := 48

## One entry per dungeon.
##   file          where the scene goes
##   dungeon_id    the DungeonInfo id, so the dock knows where it is
##   reward_ticket what the boss hands over (a DungeonInfo ticket_id)
##   cols/rows     how many rooms across and down
##   room_min/max  room size in tiles
##   cell          spacing between room origins, must exceed room_max
##   origin        top-left of the whole thing in world grid coordinates
##   monsters      what wanders the rooms, and how many per room
##   chests        how many chests, and what is in them
const DUNGEONS := [
	{
		"file": "res://scenes/maps/MushroomCave.tscn",
		"name": "MushroomCave",
		"dungeon_id": "mushroom_cave",
		"reward_ticket": "shadow_deep",
		"seed": 8801,
		"cols": 3, "rows": 2,
		"room_min": 6, "room_max": 10,
		"cell": 13,
		"origin": Vector2i(34, 40),
		"monsters": ["Slime", "Snome"],
		"monsters_per_room": 2,
		"chests": 2,
		"chest_loot": ["Green Potion", "Kami Shield"],
	},
	{
		"file": "res://scenes/maps/ShadowDeep.tscn",
		"name": "ShadowDeep",
		"dungeon_id": "shadow_deep",
		"reward_ticket": "",
		"seed": 4407,
		"cols": 5, "rows": 5,
		"room_min": 8, "room_max": 14,
		"cell": 17,
		"origin": Vector2i(6, 6),
		"monsters": ["Snome", "Kamijack", "Shadow"],
		"monsters_per_room": 3,
		"chests": 4,
		"chest_loot": ["Green Potion", "Kami Axe", "Green Potion", "Tent"],
	},
]


func _init() -> void:
	var tile_set := _tile_set()
	if tile_set == null:
		push_error("Could not get the TileSet out of %s." % SOURCE_MAP)
		quit(1)
		return

	for spec in DUNGEONS:
		_build(spec, tile_set)

	quit(0)


## The TileSet lives inside the map scenes as a sub-resource. Pull it out once
## and save it so every generated dungeon shares the same one rather than
## carrying its own copy.
func _tile_set() -> TileSet:
	if ResourceLoader.exists(TILESET_PATH):
		return load(TILESET_PATH) as TileSet

	var packed := load(SOURCE_MAP) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	var layer := inst.get_node_or_null("Tiles") as TileMapLayer
	var ts: TileSet = null
	if layer != null and layer.tile_set != null:
		ts = layer.tile_set.duplicate(true)
		ts.take_over_path(TILESET_PATH)
		var err := ResourceSaver.save(ts, TILESET_PATH)
		if err != OK:
			push_error("Could not save the shared TileSet: %d" % err)
			ts = null
		else:
			print("wrote %s" % TILESET_PATH)
	inst.free()
	return ts


func _atlas(id: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(id % 11, id / 11)


func _build(spec: Dictionary, tile_set: TileSet) -> void:

	var rng := RandomNumberGenerator.new()
	rng.seed = spec["seed"]

	var origin: Vector2i = spec["origin"]
	var cell: int = spec["cell"]
	var cols: int = spec["cols"]
	var rows: int = spec["rows"]

	# Rooms first, one per grid cell, jittered inside it so the place does not
	# read as a spreadsheet.
	var rooms: Array[Rect2i] = []
	for r in range(rows):
		for c in range(cols):
			var w: int = rng.randi_range(spec["room_min"], spec["room_max"])
			var h: int = rng.randi_range(spec["room_min"], spec["room_max"])
			var slack_x: int = maxi(cell - w - 1, 0)
			var slack_y: int = maxi(cell - h - 1, 0)
			var x: int = origin.x + c * cell + rng.randi_range(0, slack_x)
			var y: int = origin.y + r * cell + rng.randi_range(0, slack_y)
			rooms.append(Rect2i(x, y, w, h))

	var root := Node2D.new()
	root.name = spec["name"]

	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = tile_set

	# Solid everywhere, then carve. Out-of-bounds already counts as solid, so
	# the filler only has to cover what the camera can see.
	var pad := 3
	var span_x: int = cols * cell + pad * 2
	var span_y: int = rows * cell + pad * 2
	for y in range(origin.y - pad, origin.y + span_y):
		for x in range(origin.x - pad, origin.x + span_x):
			layer.set_cell(Vector2i(x, y), 0, _atlas(ROCK))

	for room in rooms:
		_carve_room(layer, room)

	# Corridors: chain the rooms in order, then add a couple of shortcuts so it
	# is not a single line.
	for i in range(rooms.size() - 1):
		_carve_corridor(layer, rooms[i], rooms[i + 1], rng)
	if rooms.size() > 3:
		_carve_corridor(layer, rooms[0], rooms[rooms.size() - 1], rng)
	if rooms.size() > 5:
		_carve_corridor(layer, rooms[1], rooms[rooms.size() - 2], rng)

	# One tile of wall around every carved floor, so the edges read as a room
	# rather than as the rock the rooms were cut out of.
	_wall_the_edges(layer)

	root.add_child(layer)
	layer.owner = root

	var groups := {}
	for group_name in ["Objects", "NPCs", "Monsters", "InteractiveTiles", "Events"]:
		var g := Node2D.new()
		g.name = group_name
		root.add_child(g)
		g.owner = root
		groups[group_name] = g

	# The dock is in the first room: you step off the boat, you can step back on.
	var arrive: Vector2i = rooms[0].position + Vector2i(rooms[0].size.x / 2, rooms[0].size.y / 2)
	var dock := _marker("event", {
		"kind": "Boat",
		"dock_of": spec["dungeon_id"],
	}, arrive)
	dock.name = "BoatDock"
	groups["Events"].add_child(dock)
	dock.owner = root

	# The boss is in the last room, as far from the dock as the layout gets.
	var boss_room: Rect2i = rooms[rooms.size() - 1]
	var boss := _marker("monster", {
		"monster": "Boss",
		"boss_dungeon_id": spec["dungeon_id"],
		"reward_ticket": spec["reward_ticket"],
	}, boss_room.position + Vector2i(boss_room.size.x / 2, boss_room.size.y / 2))
	boss.name = "Boss"
	groups["Monsters"].add_child(boss)
	boss.owner = root

	# Wandering monsters, in every room but the one you arrive in.
	var n := 0
	for i in range(1, rooms.size()):
		for _k in range(spec["monsters_per_room"]):
			var kind: String = spec["monsters"][rng.randi() % spec["monsters"].size()]
			var at := _in_room(rooms[i], rng)
			var m := _marker("monster", {"monster": kind}, at)
			m.name = "%s%d" % [kind, n]
			groups["Monsters"].add_child(m)
			m.owner = root
			n += 1

	# Chests, spread through the middle rooms.
	for i in range(spec["chests"]):
		var room: Rect2i = rooms[1 + (i * 2) % maxi(rooms.size() - 1, 1)]
		var loot: String = spec["chest_loot"][i % spec["chest_loot"].size()]
		var chest := _marker("object", {"item": "Chest", "chest_loot": loot}, _in_room(room, rng))
		chest.name = "Chest%d" % i
		groups["Objects"].add_child(chest)
		chest.owner = root

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Could not pack %s: %d" % [spec["name"], err])
		root.free()
		return
	err = ResourceSaver.save(packed, spec["file"])
	if err != OK:
		push_error("Could not save %s: %d" % [spec["file"], err])
	else:
		print("wrote %s  (%d rooms, arrive at %d,%d, boss at %d,%d)" % [
			spec["file"], rooms.size(), arrive.x, arrive.y,
			boss_room.position.x + boss_room.size.x / 2,
			boss_room.position.y + boss_room.size.y / 2])
	root.free()


func _carve_room(layer: TileMapLayer, room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			layer.set_cell(Vector2i(x, y), 0, _atlas(FLOOR))


## An L-shaped corridor two tiles wide, so a player with a 28 px solid box never
## gets wedged in a diagonal.
func _carve_corridor(layer: TileMapLayer, a: Rect2i, b: Rect2i, rng: RandomNumberGenerator) -> void:
	var from := a.position + Vector2i(a.size.x / 2, a.size.y / 2)
	var to := b.position + Vector2i(b.size.x / 2, b.size.y / 2)

	if rng.randi() % 2 == 0:
		_carve_h(layer, from.x, to.x, from.y)
		_carve_v(layer, from.y, to.y, to.x)
	else:
		_carve_v(layer, from.y, to.y, from.x)
		_carve_h(layer, from.x, to.x, to.y)


func _carve_h(layer: TileMapLayer, x0: int, x1: int, y: int) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		layer.set_cell(Vector2i(x, y), 0, _atlas(FLOOR))
		layer.set_cell(Vector2i(x, y + 1), 0, _atlas(FLOOR))


func _carve_v(layer: TileMapLayer, y0: int, y1: int, x: int) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		layer.set_cell(Vector2i(x, y), 0, _atlas(FLOOR))
		layer.set_cell(Vector2i(x + 1, y), 0, _atlas(FLOOR))


## Turn the rock that touches a floor tile into wall, purely so it looks built
## rather than dug. Both are solid, so this changes nothing about movement.
func _wall_the_edges(layer: TileMapLayer) -> void:
	var floors := {}
	for cell in layer.get_used_cells():
		if layer.get_cell_atlas_coords(cell) == _atlas(FLOOR):
			floors[cell] = true

	var to_wall := {}
	for cell in floors.keys():
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = cell + Vector2i(dx, dy)
				if floors.has(n):
					continue
				if layer.get_cell_source_id(n) == -1:
					continue
				to_wall[n] = true

	for cell in to_wall.keys():
		layer.set_cell(cell, 0, _atlas(WALL))


func _in_room(room: Rect2i, rng: RandomNumberGenerator) -> Vector2i:
	# Kept off the wall line so nothing spawns half inside the stonework.
	return Vector2i(
		rng.randi_range(room.position.x + 1, maxi(room.end.x - 2, room.position.x + 1)),
		rng.randi_range(room.position.y + 1, maxi(room.end.y - 2, room.position.y + 1)))


func _marker(kind: String, props: Dictionary, at: Vector2i) -> Node2D:
	var node := Node2D.new()
	node.set_script(load(MARKER_SCRIPTS[kind]))
	node.position = Vector2(at.x * TILE, at.y * TILE)
	for key in props.keys():
		node.set(key, props[key])
	return node
