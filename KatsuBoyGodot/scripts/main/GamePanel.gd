class_name GamePanel
extends Graphics2D
## Java: main/GamePanel.java (+ main/Main.java)
##
## This node is two things at once, exactly like the Swing JPanel was:
##   1. the game itself (update/draw loop, all the sub-systems, the entity arrays)
##   2. the drawing surface - everything the Java code called "g2" is this node.
##
## The whole game is still drawn immediate-mode inside _draw(), so the drawing
## code below reads almost line for line like the original Graphics2D code.
## The Graphics2D-style helpers (set_color / set_font / draw_str / fill_rect ...)
## live at the bottom of this file.

# SCREEN SETTINGS
const ORIGINAL_TILE_SIZE := 16  # 16x16 tile
const SCALE := 3

var tile_size: int = ORIGINAL_TILE_SIZE * SCALE  # 48x48 tile
var max_screen_col: int = 20
var max_screen_row: int = 12
var screen_width: int = tile_size * max_screen_col   # 960 pixels
var screen_height: int = tile_size * max_screen_row  # 576 pixels

# WORLD SETTINGS
var max_world_col: int = 100
var max_world_row: int = 100
## Set from map_scenes in _ready(). Add a map scene to the list and this grows.
var max_map: int = 1
var current_map: int = 0

## The maps, in order. Map 0 is where the player starts. Drop a new map scene
## in here from the Inspector and it becomes map 3, 4, ... - no code needed.
@export var map_scenes: Array[PackedScene] = []
## Every place the boat can sail to, as DungeonInfo resources from
## assets/data/dungeons/. Order here is the order of the boat's menu.
## See ROADMAP.md for how the boat, tickets and quest fit together.
@export var dungeons: Array[DungeonInfo] = []

## Every item that is a resource rather than a script, from assets/data/items/.
##
## The list exists so a save file can find one again: a saved bag holds item
## NAMES, and a name that matches none of the hand-written items is looked for
## here. An item missing from this list works on the map and then quietly fails
## to come back after a save, which is why the marker warns about it.
@export var items: Array[ItemStats] = []
## The instantiated map scenes, one per index. Live in the scene tree so you
## can inspect them while the game runs (Debugger -> Remote tree).
var map_node: Array[Node2D] = []

## The three people you can be, as PlayerClass resources from
## assets/data/classes/. The title screen builds its class menu from this list,
## so adding one is dropping a .tres in here.
@export var player_classes: Array[PlayerClass] = []

## Every sound and piece of music, editable in the Inspector.
## See scripts/data/SE.gd for the slot names.
@export var sound_bank: SoundBank

## Testing aid: set this to a map number to boot straight into that map instead
## of map 0, so you can play a dungeon without walking to it. -1 = off.
## The player lands on that map's PlayerStart if it has one, otherwise the
## middle of the map.
@export var debug_start_map: int = -1

@export_group("Time of day")
## Game frames between each tick of the clock. 60 = one tick per real second.
@export var frames_per_time_step: int = 60
## How many in-game minutes each tick adds. At the defaults a full 24 hours
## takes about five real minutes.
@export var minutes_per_time_step: int = 5
## What a new game starts at. 0 = Sunday.
@export_range(0, 6) var start_day: int = 0
@export_range(0, 23) var start_hour: int = 8
@export_range(0, 59) var start_minute: int = 0
## The hour the calendar flips to the next day. 0 = midnight.
@export_range(0, 23) var day_rollover_hour: int = 0
## Show the clock on the HUD.
@export var show_clock: bool = true

@export_group("Days of the week")
## What each day of the week does, Sunday first. Edit the resources in
## assets/data/days/ to tune them; empty entries mean an ordinary day.
@export var day_effects: Array[DayEffect] = []

@export_group("Day / night cycle")
## Sunrise runs between these two hours: dark before, light after.
@export_range(0.0, 24.0, 0.25) var sunrise_start_hour: float = 5.0
@export_range(0.0, 24.0, 0.25) var sunrise_end_hour: float = 6.0
## Sunset runs between these two: light before, dark after.
@export_range(0.0, 24.0, 0.25) var sunset_start_hour: float = 20.0
@export_range(0.0, 24.0, 0.25) var sunset_end_hour: float = 21.0
## When "Morning" becomes "Afternoon", and "Afternoon" becomes "Evening".
@export_range(0.0, 24.0, 0.25) var midday_hour: float = 12.0
@export_range(0.0, 24.0, 0.25) var evening_hour: float = 17.0
## How dark full night gets, 0 (none) to 255 (pitch black).
@export_range(0, 255) var night_darkness: int = 240

@export_group("Palette")
## The four colours the whole UI is drawn from.
@export var color_green: Color = Color8(134, 186, 134)
@export var color_black: Color = Color8(26, 2, 43)
@export var color_pink: Color = Color8(194, 92, 177)
@export var color_white: Color = Color8(240, 242, 239)
## Holds the map scenes and scrolls them with the player. Sits behind
## everything GamePanel draws itself (z_index -1), so tiles render under the
## entities exactly like they did when we blitted them by hand.
## It is a node in main.tscn; this just finds it.
var world: Node2D
## Hit sparks. Optional - the game runs without it.
var effects: EffectsLayer

# FOR FULL SCREEN
# (Java kept a BufferedImage "tempScreen" and stretched it onto the window.
#  Godot's viewport stretch setting in project.godot does that for us.)
var full_screen_on: bool = false

# SYSTEM
var tile_m: TileManager
var key_h: KeyHandler
var music: Sound
var se: Sound
var c_checker: CollisionChecker
var a_setter: AssetSetter
var ui: UI
var e_handler: EventHandler
var config: Config
var p_finder: PathFinder
var e_manager: EnvironmentManager
var map: Map
var save_load: SaveLoad
## Tickets held, dungeons cleared, what to do next. Saved with the rest.
var quest: QuestLog
## Which dungeon the player is standing in, by DungeonInfo id. Empty on the
## world map. Set when the boat drops them off, so a boss knows which dungeon
## it belongs to without being told twice.
var current_dungeon_id: String = ""

var e_generator: EntityGenerator

# ENTITY AND OBJECT
var player: Player
var obj: Array = []          # [max_map][40]
var npc: Array = []          # [max_map][10]
var monster: Array = []      # [max_map][80]
var i_tile: Array = []       # [max_map][50]
var projectile: Array = []   # [max_map][20]
var particle_list: Array = []
var entity_list: Array = []

# GAME STATE
var game_state: int
const TITLE_STATE := 0
const PLAY_STATE := 1
const PAUSE_STATE := 2
const DIALOGUE_STATE := 3
const CHARACTER_STATE := 4
const OPTION_STATE := 5
const GAME_OVER_STATE := 6
const TRANSITION_STATE := 7
const TRADE_STATE := 8
const SLEEP_STATE := 9
const MAP_STATE := 10
## Choosing where the boat takes you. See BoatService and UI.draw_boat_screen.
const BOAT_STATE := 11
## The ending, reached by sailing home once every dungeon is cleared.
const ENDING_STATE := 12


func _ready() -> void:
	# --- the maps come first: everything else reads tiles and markers off them
	max_map = maxi(map_scenes.size(), 1)

	world = get_node_or_null("World")
	if world == null:
		# main.tscn should have one, but keep the game runnable without it.
		world = Node2D.new()
		world.name = "World"
		world.z_index = -1
		add_child(world)
	effects = get_node_or_null("EffectsLayer")

	map_node.resize(max_map)
	for i in range(map_scenes.size()):
		if map_scenes[i] == null:
			continue
		var m: Node2D = map_scenes[i].instantiate()
		world.add_child(m)
		map_node[i] = m

	_wire_maps()

	# --- Java: the GamePanel field initialisers, in the same order ---
	tile_m = TileManager.new(self)
	key_h = KeyHandler.new(self)
	if sound_bank == null:
		sound_bank = load("res://assets/data/sound_bank.tres")
	music = Sound.new(self, sound_bank)
	se = Sound.new(self, sound_bank)
	c_checker = CollisionChecker.new(self)
	a_setter = AssetSetter.new(self)
	ui = UI.new(self)
	e_handler = EventHandler.new(self)
	config = Config.new(self)
	p_finder = PathFinder.new(self)
	e_manager = EnvironmentManager.new(self)
	map = Map.new(self)
	save_load = SaveLoad.new(self)
	quest = QuestLog.new()
	e_generator = EntityGenerator.new(self)

	# Slots per map. An empty slot is null; going over the limit warns at
	# startup rather than crashing, but the extra markers are ignored - which is
	# why these are roomier than the Java fixed arrays. A generated dungeon can
	# easily hold sixty monsters.
	player = Player.new(self, key_h)
	obj = _new_entity_array(40)
	npc = _new_entity_array(10)
	monster = _new_entity_array(80)
	i_tile = _new_entity_array(50)
	projectile = _new_entity_array(20)

	# --- Java: Main.main() ---
	get_window().title = "Adventure of Katsu Boy 2D"
	config.load_config()
	if full_screen_on == true:
		set_full_screen()

	setup_game()

	if debug_start_map >= 0 and debug_start_map < max_map:
		jump_to_map(debug_start_map)


## Drop the player onto a map. Used by the debug_start_map setting and by the
## dev tools' "next map" key.
func jump_to_map(map_num: int) -> void:
	if map_num < 0 or map_num >= max_map:
		return
	current_map = map_num
	var start := a_setter.player_start_on(map_num)
	player.world_x = tile_size * start.x
	player.world_y = tile_size * start.y
	e_handler.prev_event_x = player.world_x
	e_handler.prev_event_y = player.world_y
	e_handler.can_touch_event = false


## Java used fixed size arrays: new Entity[maxMap][slots]. Godot arrays resize
## to null-filled, which gives us the same "empty slot == null" convention.
func _new_entity_array(slots: int) -> Array:
	var outer: Array = []
	for _m in range(max_map):
		var inner: Array = []
		inner.resize(slots)
		outer.append(inner)
	return outer


func setup_game() -> void:
	a_setter.set_object()
	a_setter.set_npc()
	a_setter.set_monster()
	a_setter.set_interactive_tile()
	e_manager.setup()
#	play_music(SE.MUSIC_MAIN)
	game_state = TITLE_STATE


## Begin a new game as this class. Everything the class touches - stats, gear,
## the palette - is applied here and nowhere else, so the title screen does not
## need to know what a class is made of.
func start_as(chosen: PlayerClass) -> void:

	ui.reset_palette()
	player.char_class = chosen
	player.set_default_values()
	player.restore_status()
	player.set_items()

	# Zilla sees the world in one colour. It was the only thing the old class
	# menu actually did, and it is too good a joke to lose.
	if chosen != null and chosen.id == "zilla":
		ui.kamiwhite = ui.kamigreen
		ui.kamipink = ui.kamigreen
		stop_music()
		play_music(SE.MUSIC_NIGHT)

	game_state = PLAY_STATE


func reset_game(restart: bool) -> void:
	player.set_default_positions()
	player.restore_status()
	player.reset_counter()
	a_setter.set_npc()
	a_setter.set_monster()

	if restart == true:
		player.set_default_values()
		a_setter.set_object()
		a_setter.set_interactive_tile()
		e_manager.lighting.reset_day()

		ui.reset_palette()
		player.has_boots = false


func set_full_screen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func set_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


## Java: GamePanel.run() ticked update() 60 times a second.
## _physics_process is locked to 60 Hz in project.godot, so every frame based
## counter in the game keeps its original timing.
func _physics_process(_delta: float) -> void:
	update()


## World coordinates -> on-screen pixels. The same maths every entity's draw()
## does, shared so the effect layers can use it too.
func to_screen(world_x: int, world_y: int) -> Vector2:
	return Vector2(world_x - player.world_x + player.screen_x,
			world_y - player.world_y + player.screen_y)


func _process(_delta: float) -> void:
	# Scroll the tile layers to match the hand-computed screen positions the
	# entity drawing uses, and show only the map we are standing on.
	if world != null and player != null:
		world.position = Vector2(-player.world_x + player.screen_x,
				-player.world_y + player.screen_y)
		for i in range(map_node.size()):
			if map_node[i] != null:
				map_node[i].visible = (i == current_map and game_state != MAP_STATE)

	queue_redraw()


## Turn raw input into the named actions from Project Settings -> Input Map and
## hand them to KeyHandler. Because the actions carry the key bindings, nothing
## in the game refers to a key code.
func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.is_echo():
		return  # ignore OS key repeat, menus behave much better without it

	for action in Action.ALL:
		# exact_match false, so Shift+W still counts as "move up" while also
		# counting as "run" - the same way the raw key handler behaved.
		if event.is_action_pressed(action, false, false):
			key_h.action_pressed(action)
		elif event.is_action_released(action, false):
			key_h.action_released(action)


func update() -> void:

	if game_state == PLAY_STATE:
		# PLAYER
		player.update()

		# NPC
		for i in range(npc[1].size()):
			if npc[current_map][i] != null:
				npc[current_map][i].update()

		for i in range(monster[1].size()):
			if monster[current_map][i] != null:
				if monster[current_map][i].alive == true and monster[current_map][i].dying == false:
					monster[current_map][i].update()
				if monster[current_map][i].dying == true:
					monster[current_map][i].update_dying()
				if monster[current_map][i].alive == false:
					monster[current_map][i].check_drop()
					monster[current_map][i] = null

		for i in range(projectile[1].size()):
			if projectile[current_map][i] != null:
				if projectile[current_map][i].alive == true:
					projectile[current_map][i].update()
				if projectile[current_map][i].alive == false:
					projectile[current_map][i] = null

		var i := 0
		while i < particle_list.size():
			if particle_list[i] != null:
				if particle_list[i].alive == true:
					particle_list[i].update()
				if particle_list[i].alive == false:
					particle_list.remove_at(i)
					continue
			i += 1

		for j in range(i_tile[1].size()):
			if i_tile[current_map][j] != null:
				i_tile[current_map][j].update()

		e_manager.update()
		if e_manager.clock.take_day_change():
			announce_day()
		ui.update_messages()

	if game_state == PAUSE_STATE:
		pass  # DO NOTHING

	# These change game state (which map you are on, what time of day it is), so
	# they tick with the game rather than with the frame rate.
	if game_state == TRANSITION_STATE:
		ui.update_transition()
	if game_state == SLEEP_STATE:
		ui.update_sleep()


## Java: drawToTempScreen(), minus the parts that now live on their own layer.
##
## The screen is built from layers that are real nodes in main.tscn, drawn back
## to front by z_index:
##
##   World          (-1)  the TileMapLayer terrain
##   GamePanel       (0)  interactive tiles and entities  <- this function
##   LightingOverlay (5)  the day/night shader
##   EffectsLayer    (6)  hit sparks
##   HudLayer       (10)  mini map, UI, menus, debug text
##
func _draw() -> void:

	reset_pen()

	# The title and full-map screens are pure UI: HudLayer draws those.
	if game_state == TITLE_STATE or game_state == MAP_STATE:
		return

	# The terrain draws itself (World), so all that is left of the old tile
	# pass is the A* debug overlay.
	tile_m.draw(self)

	for i in range(i_tile[1].size()):
		if i_tile[current_map][i] != null:
			i_tile[current_map][i].draw(self)

	# ADD ENTITIES TO THE LIST
	entity_list.append(player)

	for i in range(npc[1].size()):
		if npc[current_map][i] != null:
			entity_list.append(npc[current_map][i])
	for i in range(obj[1].size()):
		if obj[current_map][i] != null:
			entity_list.append(obj[current_map][i])
	for i in range(monster[1].size()):
		if monster[current_map][i] != null:
			entity_list.append(monster[current_map][i])
	for i in range(projectile[1].size()):
		if projectile[current_map][i] != null:
			entity_list.append(projectile[current_map][i])
	for i in range(particle_list.size()):
		if particle_list[i] != null:
			entity_list.append(particle_list[i])

	# SORT (painter's algorithm on world_y, same as the Java Comparator)
	entity_list.sort_custom(func(e1, e2): return e1.world_y < e2.world_y)

	# DRAW ENTITIES
	for e in entity_list:
		e.draw(self)

	# EMPTY ENTITY LIST
	entity_list.clear()


## What today does to the game. Never null, so callers can use it directly.
func today() -> DayEffect:
	if e_manager != null and e_manager.clock != null:
		var i: int = e_manager.clock.day_index
		if i >= 0 and i < day_effects.size() and day_effects[i] != null:
			return day_effects[i]
	return _neutral_day


var _neutral_day: DayEffect = DayEffect.neutral()


## Tell the player what the new day means for them.
func announce_day() -> void:
	var effect: DayEffect = today()
	if effect.note != "":
		ui.add_message(effect.note)


func play_music(i: int) -> void:
	music.set_file(i)
	music.play()
	music.loop()


func stop_music() -> void:
	music.stop()


func play_se(i: int) -> void:
	se.set_file(i)
	se.play()


func stop_se() -> void:
	se.stop()


## Fill in the numbers that used to be typed by hand, by reading them off the
## map scenes themselves.
##
## Two of them: a DungeonInfo's map number and arrival tile, which come from the
## map whose DungeonMap root points at it; and a ChangeMap door's target map,
## which comes from the scene dragged into its Target Scene slot. Both used to
## be an index into this node's Map Scenes list that a designer had to count
## out and then keep in step forever. Doing it here means a map can be dropped
## anywhere in the list and everything still points at it.
##
## Anything not covered - a DungeonInfo whose map has no DungeonMap root, a door
## with no Target Scene - keeps whatever was typed in, so old maps still work.
func _wire_maps() -> void:

	# Which scene is which map number, by the resource path of the .tscn.
	var index_of := {}
	for i in range(map_scenes.size()):
		if map_scenes[i] != null:
			index_of[map_scenes[i].resource_path] = i

	for i in range(map_node.size()):
		var node = map_node[i]
		if node == null:
			continue

		if node is DungeonMap and node.dungeon_info != null:
			var info: DungeonInfo = node.dungeon_info
			info.map_index = i
			var landing: Vector2i = node.arrival_tile()
			if landing.x >= 0:
				info.arrive_col = landing.x
				info.arrive_row = landing.y

		for m in a_setter_markers(node, "Events"):
			if m is EventMarker and not m.target_scene.is_empty():
				if index_of.has(m.target_scene):
					m.target_map = index_of[m.target_scene]
				else:
					push_warning("%s points at %s, which is not in Map Scenes."
							% [m.name, m.target_scene.get_file()])


## Markers under a group of an already-instantiated map, however deeply nested.
## AssetSetter does the same thing, but it does not exist yet at this point in
## _ready() - the maps have to be wired before anything reads them.
func a_setter_markers(map_root: Node, group_name: String) -> Array:
	var group: Node = map_root.get_node_or_null(group_name)
	var out: Array = []
	if group != null:
		_gather_markers(group, out)
	return out


func _gather_markers(node: Node, out: Array) -> void:
	for child in node.get_children():
		out.append(child)
		if child.get_child_count() > 0:
			_gather_markers(child, out)
