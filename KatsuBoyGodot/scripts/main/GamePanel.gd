class_name GamePanel
extends Node2D
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
## The instantiated map scenes, one per index. Live in the scene tree so you
## can inspect them while the game runs (Debugger -> Remote tree).
var map_node: Array[Node2D] = []

## Every sound and piece of music, editable in the Inspector.
## See scripts/data/SE.gd for the slot names.
@export var sound_bank: SoundBank

@export_group("Day / night cycle")
## Frames of daylight before dusk starts. 60 frames = 1 second.
@export var day_length_frames: int = 9000
## Frames of darkness before dawn starts.
@export var night_length_frames: int = 4800
## How fast dusk falls, per frame. Bigger = quicker.
@export var dusk_fade_speed: float = 0.001
## How fast dawn breaks, per frame.
@export var dawn_fade_speed: float = 0.001
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
var world: Node2D

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
var e_generator: EntityGenerator

# ENTITY AND OBJECT
var player: Player
var obj: Array = []          # [max_map][20]
var npc: Array = []          # [max_map][10]
var monster: Array = []      # [max_map][30]
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


func _ready() -> void:
	# --- the maps come first: everything else reads tiles and markers off them
	max_map = maxi(map_scenes.size(), 1)
	world = Node2D.new()
	world.name = "World"
	world.z_index = -1
	add_child(world)

	map_node.resize(max_map)
	for i in range(map_scenes.size()):
		if map_scenes[i] == null:
			continue
		var m: Node2D = map_scenes[i].instantiate()
		world.add_child(m)
		map_node[i] = m

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
	e_generator = EntityGenerator.new(self)

	player = Player.new(self, key_h)
	obj = _new_entity_array(20)
	npc = _new_entity_array(10)
	monster = _new_entity_array(30)
	i_tile = _new_entity_array(50)
	projectile = _new_entity_array(20)

	# --- Java: Main.main() ---
	get_window().title = "Adventure of Katsu Boy 2D"
	config.load_config()
	if full_screen_on == true:
		set_full_screen()

	setup_game()


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
		ui.update_messages()

	if game_state == PAUSE_STATE:
		pass  # DO NOTHING

	# These change game state (which map you are on, what time of day it is), so
	# they tick with the game rather than with the frame rate.
	if game_state == TRANSITION_STATE:
		ui.update_transition()
	if game_state == SLEEP_STATE:
		ui.update_sleep()


## Java: drawToTempScreen(). drawToScreen() is gone - the engine presents the
## viewport for us (and stretches it when full screen).
func _draw() -> void:
	# reset the Graphics2D-ish state at the top of every frame
	alpha = 1.0
	_stroke = 1.0

	# draw items are layers in top to bottom order

	# TITLE SCREEN
	if game_state == TITLE_STATE:
		ui.draw(self)
	# MAP SCREEN
	elif game_state == MAP_STATE:
		map.draw_full_map_screen(self)
	# OTHERS
	else:
		# TILE
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

		# ENVIRONMENT
		e_manager.draw(self)

		# MINI MAP
		map.draw_mini_map(self)

		# UI
		ui.draw(self)

	# DEBUG
	if key_h.check_draw_time == true:
		set_font(ui.maru_monica, 24)
		set_color(ui.kamiblack)
		draw_str("Col: " + str(player.world_x / 48), 10 + 2, 432 + 2)
		draw_str("Row: " + str(player.world_y / 48), 10 + 2, 464 + 2)
		draw_str("WorldX: " + str(player.world_x), 10 + 2, 496 + 2)
		draw_str("WorldY: " + str(player.world_y), 10 + 2, 528 + 2)

		set_color(ui.kamiwhite)
		draw_str("Col: " + str(player.world_x / 48), 10, 432)
		draw_str("Row: " + str(player.world_y / 48), 10, 464)
		draw_str("WorldX: " + str(player.world_x), 10, 496)
		draw_str("WorldY: " + str(player.world_y), 10, 528)


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


# ---------------------------------------------------------------------------
# Graphics2D stand-ins.
#
# Java kept the pen state (font, colour, stroke, alpha composite) on the
# Graphics2D object and then called drawString/fillRect/drawImage. Godot's
# draw_* calls each take their colour explicitly, so we keep the same pen state
# here and let the helpers below apply it. That way every drawing routine in
# the game still reads like the original.
# ---------------------------------------------------------------------------

var _font: Font
var _font_size: int = 24
var _color: Color = Color.WHITE
var _stroke: float = 1.0
## Java's AlphaComposite: multiplied into every sprite we blit.
var alpha: float = 1.0


func set_font(font: Font, size: int) -> void:
	_font = font
	_font_size = size


## Java: g2.setFont(g2.getFont().deriveFont(size)) - keep the font, change size.
func derive_font(size: int) -> void:
	_font_size = size


func set_color(color: Color) -> void:
	_color = color


func set_stroke(width: float) -> void:
	_stroke = width


## Java: changeAlpha(g2, value) / setComposite(AlphaComposite...)
func change_alpha(value: float) -> void:
	alpha = value


## The tint every sprite blit is drawn with, so the alpha composite applies.
func tint() -> Color:
	return Color(1, 1, 1, alpha)


## Java: g2.drawString(text, x, y) - (x, y) is the text BASELINE in both APIs.
func draw_str(text: String, x: int, y: int) -> void:
	draw_string(_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _color)


## Java: g2.getFontMetrics().getStringBounds(text, g2).getWidth()
func get_string_width(text: String) -> int:
	return int(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x)


## Java: g2.drawImage(image, x, y, null) - draws at the sprite's own size.
func draw_img(texture: Texture2D, x: int, y: int) -> void:
	if texture == null:
		return
	draw_texture(texture, Vector2(x, y), tint())


## Java: g2.drawImage(image, x, y, width, height, null)
func draw_img_scaled(texture: Texture2D, x: int, y: int, width: int, height: int) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(x, y, width, height), false, tint())


func fill_rect(x: int, y: int, width: int, height: int) -> void:
	draw_rect(Rect2(x, y, width, height), _color, true)


func fill_round_rect(x: int, y: int, width: int, height: int, arc_width: int, _arc_height: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _color
	sb.set_corner_radius_all(int(arc_width / 2.0))
	draw_style_box(sb, Rect2(x, y, width, height))


func draw_round_rect(x: int, y: int, width: int, height: int, arc_width: int, _arc_height: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = _color
	sb.set_border_width_all(int(_stroke))
	sb.set_corner_radius_all(int(arc_width / 2.0))
	draw_style_box(sb, Rect2(x, y, width, height))
