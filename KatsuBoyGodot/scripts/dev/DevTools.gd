class_name DevTools
extends Node2D
## Developer cheats and a live readout, so you can test content without
## replaying the game to get to it.
##
## The node lives under GamePanel in main.tscn. Press F1 in game for the panel.
##
## EDITOR ONLY. _ready() switches the whole thing off unless the game is
## running from the Godot editor, so no exported build - web or desktop - ships
## working cheats, whatever the Inspector tick says. That matters because the
## web build reports to the high-score board on kamimart.com, and F10 handing
## out 1000 coins would make that board meaningless.
##
## Nothing else in the game depends on this node, so it stays in the project
## for development rather than being deleted before a release.

## Master switch. When off, none of the keys below do anything.
@export var enabled: bool = true
## Show the readout panel on start without pressing F1.
@export var panel_visible_on_start: bool = false

var gp
var panel_visible: bool = false
var god_mode: bool = false
var message: String = ""
var message_timer: int = 0

const HELP := [
	"F1  this panel",
	"F2  god mode",
	"F3  +3 hours",
	"F4  give one of every item",
	"F6  full heal + refill mana",
	"F7  kill every monster on this map",
	"F8  respawn monsters",
	"F9  next map",
	"F10 +1000 coins, +500 exp",
	"click  teleport to that tile",
]


func _ready() -> void:
	gp = get_parent()

	# has_feature("editor") is true when running from the editor and false in
	# every export, which is exactly the line we want: cheats while developing,
	# none in anything a player can download or open in a browser.
	if not OS.has_feature("editor"):
		enabled = false
		set_process_input(false)
		hide()
		return

	panel_visible = panel_visible_on_start
	z_index = 100


func notify(text: String) -> void:
	message = text
	message_timer = 120


func _input(event: InputEvent) -> void:

	if not enabled or gp == null or gp.player == null:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if gp.game_state == gp.PLAY_STATE:
			var mouse: Vector2 = get_viewport().get_mouse_position()
			gp.player.world_x = int(mouse.x) - gp.player.screen_x + gp.player.world_x
			gp.player.world_y = int(mouse.y) - gp.player.screen_y + gp.player.world_y
			notify("teleported to %d,%d" % [gp.player.world_x / gp.tile_size, gp.player.world_y / gp.tile_size])
			get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return

	var handled := true

	match event.keycode:
		KEY_F1:
			panel_visible = not panel_visible
		KEY_F2:
			god_mode = not god_mode
			if god_mode:
				gp.player.max_life = 500
				gp.player.life = 500
				gp.player.strength = 50
				gp.player.get_attack()
			notify("god mode %s" % ("ON" if god_mode else "OFF"))
		KEY_F3:
			gp.e_manager.clock.advance(3 * 60)
			gp.e_manager.lighting.refresh()
			notify("time: " + day_name())
		KEY_F4:
			for item_name in ["Key", "Green Potion", "Tent", "Candle", "Boots",
					"Kami Axe", "Kami no Bokken", "Kami Shield", "Puffa Shield"]:
				var item: Entity = gp.e_generator.get_object(item_name)
				if item != null and gp.player.inventory.size() < gp.player.MAX_INVENTORY_SIZE:
					gp.player.inventory.append(item)
			notify("items added")
		KEY_F6:
			gp.player.life = gp.player.max_life
			gp.player.mana = gp.player.max_mana
			gp.player.is_cursed = false
			notify("healed")
		KEY_F7:
			var killed := 0
			for i in range(gp.monster[gp.current_map].size()):
				if gp.monster[gp.current_map][i] != null:
					gp.monster[gp.current_map][i] = null
					killed += 1
			notify("cleared %d monsters" % killed)
		KEY_F8:
			gp.a_setter.set_monster()
			notify("monsters respawned")
		KEY_F9:
			var next: int = (gp.current_map + 1) % gp.max_map
			gp.jump_to_map(next)
			notify("map %d" % next)
		KEY_F10:
			gp.player.coin += 1000
			gp.player.exp += 500
			gp.player.check_level_up()
			notify("+1000 coins, +500 exp")
		_:
			handled = false

	if handled:
		get_viewport().set_input_as_handled()


func day_name() -> String:
	var clock = gp.e_manager.clock
	if clock == null:
		return "?"
	return "%s %s (%s)" % [clock.day_name(), clock.time_string(), clock.period_name()]


func state_name() -> String:
	match gp.game_state:
		gp.TITLE_STATE: return "title"
		gp.PLAY_STATE: return "play"
		gp.PAUSE_STATE: return "pause"
		gp.DIALOGUE_STATE: return "dialogue"
		gp.CHARACTER_STATE: return "character"
		gp.OPTION_STATE: return "option"
		gp.GAME_OVER_STATE: return "game over"
		gp.TRANSITION_STATE: return "transition"
		gp.TRADE_STATE: return "trade"
		gp.SLEEP_STATE: return "sleep"
		gp.MAP_STATE: return "map"
	return "?"


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	if god_mode and gp != null and gp.player != null:
		gp.player.life = gp.player.max_life
	if message_timer > 0:
		message_timer -= 1
	queue_redraw()


func _draw() -> void:

	if not enabled or gp == null or gp.player == null or gp.ui == null:
		return

	var font: Font = gp.ui.maru_monica
	if font == null:
		font = ThemeDB.fallback_font

	if message_timer > 0 and message != "":
		draw_string(font, Vector2(12, gp.screen_height - 16), "DEV: " + message,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.9, 0.3))

	if not panel_visible:
		return

	var lines: Array[String] = [
		"-- DEV (F1 to hide) --",
		"fps        %d" % Engine.get_frames_per_second(),
		"state      %s" % state_name(),
		"map        %d / %d" % [gp.current_map, gp.max_map - 1],
		"tile       %d, %d" % [gp.player.world_x / gp.tile_size, gp.player.world_y / gp.tile_size],
		"world      %d, %d" % [gp.player.world_x, gp.player.world_y],
		"life       %d / %d" % [gp.player.life, gp.player.max_life],
		"mana       %d / %d" % [gp.player.mana, gp.player.max_mana],
		"level %d   exp %d / %d" % [gp.player.level, gp.player.exp, gp.player.next_level_exp],
		"attack %d  defense %d" % [gp.player.attack, gp.player.defense],
		"coin       %d" % gp.player.coin,
		"weapon     %s" % gp.player.current_weapon.name,
		"time       %s" % day_name(),
		"monsters   %d" % count_monsters(),
		"particles  %d" % gp.particle_list.size(),
		"god mode   %s" % ("ON" if god_mode else "off"),
		"",
	]
	lines.append_array(HELP)

	var width := 330
	var height: int = 18 * lines.size() + 16
	draw_rect(Rect2(8, 8, width, height), Color(0.02, 0.01, 0.06, 0.85))
	draw_rect(Rect2(8, 8, width, height), Color(0.52, 0.73, 0.52), false, 2.0)

	var y := 28
	for line in lines:
		draw_string(font, Vector2(20, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				Color(0.94, 0.95, 0.94))
		y += 18


func count_monsters() -> int:
	var n := 0
	if gp.current_map < gp.monster.size():
		for m in gp.monster[gp.current_map]:
			if m != null:
				n += 1
	return n
