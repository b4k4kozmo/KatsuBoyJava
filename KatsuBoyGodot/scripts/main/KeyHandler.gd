class_name KeyHandler
extends RefCounted
## Java: main/KeyHandler.java
##
## Same job and same per-game-state structure as the Swing KeyListener, but it
## works on NAMED ACTIONS instead of raw key codes. The keys behind those names
## live in Project Settings -> Input Map, so rebinding (or adding arrow keys, or
## a gamepad) is done in the editor - see scripts/data/Action.gd for the names.
##
## GamePanel._unhandled_input turns each key event into an action and calls
## action_pressed / action_released below.

var gp
var up_pressed: bool = false
var down_pressed: bool = false
var left_pressed: bool = false
var right_pressed: bool = false
var shift_pressed: bool = false
var enter_pressed: bool = false
var shot_key_pressed: bool = false
var control_pressed: bool = false
# DEBUG
var check_draw_time: bool = false


func _init(gp) -> void:
	self.gp = gp


func action_pressed(action: StringName) -> void:

	# TITLE STATE
	if gp.game_state == gp.TITLE_STATE:
		title_state(action)
	# PLAY STATE
	elif gp.game_state == gp.PLAY_STATE:
		play_state(action)
	# PAUSE STATE
	elif gp.game_state == gp.PAUSE_STATE:
		pause_state(action)
	# DIALOGUE STATE
	elif gp.game_state == gp.DIALOGUE_STATE:
		dialogue_state(action)
	# CHARACTER STATE
	elif gp.game_state == gp.CHARACTER_STATE:
		character_state(action)
	# OPTIONS STATE
	elif gp.game_state == gp.OPTION_STATE:
		option_state(action)
	# GAME OVER STATE
	elif gp.game_state == gp.GAME_OVER_STATE:
		game_over_state(action)
	# TRADE STATE
	elif gp.game_state == gp.TRADE_STATE:
		trade_state(action)
	# MAP STATE
	elif gp.game_state == gp.BOAT_STATE:
		boat_state(action)
	elif gp.game_state == gp.ENDING_STATE:
		ending_state(action)
	elif gp.game_state == gp.MAP_STATE:
		map_state(action)


func title_state(action: StringName) -> void:

	if gp.ui.title_screen_state == 0:
		if action == Action.MOVE_UP:
			gp.ui.command_num -= 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num < 0:
				gp.stop_se()
				gp.ui.command_num = 0
		if action == Action.MOVE_DOWN:
			gp.ui.command_num += 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num > 2:
				gp.stop_se()
				gp.ui.command_num = 2
		if action == Action.CONFIRM:
			if gp.ui.command_num == 0:
				gp.play_se(SE.COIN)
				gp.ui.title_screen_state = 1
				gp.play_music(SE.MUSIC_MAIN)
			if gp.ui.command_num == 1:
				gp.play_se(SE.COIN)
				gp.save_load.load_game()
				gp.game_state = gp.PLAY_STATE
				gp.play_music(SE.MUSIC_MAIN)
			if gp.ui.command_num == 2:
				gp.play_se(SE.COIN)
				gp.get_tree().quit()

	elif gp.ui.title_screen_state == 1:

		# The menu is however many classes are in GamePanel's list, plus Back.
		var last: int = gp.player_classes.size()

		if action == Action.MOVE_UP:
			gp.ui.command_num -= 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num < 0:
				gp.stop_se()
				gp.ui.command_num = last
		if action == Action.MOVE_DOWN:
			gp.ui.command_num += 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num > last:
				gp.stop_se()
				gp.ui.command_num = 0
		if action == Action.CONFIRM:

			if gp.ui.command_num >= 0 and gp.ui.command_num < last:
				gp.play_se(SE.COIN)
				gp.start_as(gp.player_classes[gp.ui.command_num])
				gp.ui.command_num = 0

			elif gp.ui.command_num == last:
				gp.play_se(SE.COIN)
				gp.ui.title_screen_state = 0
				gp.stop_music()
				gp.ui.command_num = 0


func play_state(action: StringName) -> void:
	if action == Action.MOVE_UP:
		up_pressed = true
	if action == Action.MOVE_DOWN:
		down_pressed = true
	if action == Action.MOVE_LEFT:
		left_pressed = true
	if action == Action.MOVE_RIGHT:
		right_pressed = true
	if action == Action.RUN:
		shift_pressed = true
	if action == Action.SHOOT:
		shot_key_pressed = true
	if action == Action.OPTIONS:
		gp.game_state = gp.OPTION_STATE
	if action == Action.PAUSE:
		gp.game_state = gp.PAUSE_STATE
		gp.play_se(SE.COIN)
	if action == Action.CHARACTER_SCREEN:
		gp.game_state = gp.CHARACTER_STATE
		gp.play_se(SE.COIN)
	if action == Action.CONFIRM:
		enter_pressed = true
	if action == Action.WORLD_MAP:
		gp.game_state = gp.MAP_STATE
		gp.play_se(SE.COIN)
	if action == Action.MINI_MAP:
		gp.map.mini_map_on = not gp.map.mini_map_on
	if action == Action.GUARD:
		control_pressed = true

	# DEBUG
	if action == Action.DEBUG_OVERLAY:
		check_draw_time = not check_draw_time
		gp.tile_m.draw_path = check_draw_time


func pause_state(action: StringName) -> void:
	if action == Action.PAUSE:
		gp.game_state = gp.PLAY_STATE
		gp.play_se(SE.COIN)


func dialogue_state(action: StringName) -> void:
	if action == Action.CONFIRM:
		enter_pressed = true


func character_state(action: StringName) -> void:
	if action == Action.CHARACTER_SCREEN:
		gp.game_state = gp.PLAY_STATE
		gp.play_se(SE.COIN)

	if action == Action.CONFIRM:
		gp.player.select_item()

	player_inventory(action)


func option_state(action: StringName) -> void:

	if action == Action.OPTIONS:
		gp.game_state = gp.PLAY_STATE
	if action == Action.CONFIRM:
		enter_pressed = true
		gp.play_se(SE.COIN)

	var max_command_num := 0
	match gp.ui.sub_state:
		0: max_command_num = 5
		3: max_command_num = 1

	if action == Action.MOVE_UP:
		gp.ui.command_num -= 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num < 0:
			gp.ui.command_num = 0
			gp.stop_se()
	if action == Action.MOVE_DOWN:
		gp.ui.command_num += 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num > max_command_num:
			gp.ui.command_num = max_command_num
			gp.stop_se()
	if action == Action.MOVE_LEFT:
		if gp.ui.sub_state == 0:
			if gp.ui.command_num == 1 and gp.music.volume_scale > 0:
				gp.music.volume_scale -= 1
				gp.music.check_volume()
				gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num == 2 and gp.se.volume_scale > 0:
				gp.se.volume_scale -= 1
				gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_RIGHT:
		if gp.ui.sub_state == 0:
			if gp.ui.command_num == 1 and gp.music.volume_scale < 5:
				gp.music.volume_scale += 1
				gp.music.check_volume()
				gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num == 2 and gp.se.volume_scale < 5:
				gp.se.volume_scale += 1
				gp.play_se(SE.CURSOR_MOVE)


func game_over_state(action: StringName) -> void:

	if action == Action.MOVE_UP:
		gp.ui.command_num -= 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num < 0:
			gp.ui.command_num = 0
			gp.stop_se()

	if action == Action.MOVE_DOWN:
		gp.ui.command_num += 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num > 1:
			gp.ui.command_num = 1
			gp.stop_se()

	if action == Action.CONFIRM:
		if gp.ui.command_num == 0:
			gp.game_state = gp.PLAY_STATE
			gp.reset_game(false)
			gp.play_music(SE.MUSIC_MAIN)
		elif gp.ui.command_num == 1:
			gp.game_state = gp.TITLE_STATE
			gp.ui.title_screen_state = 0
			gp.ui.command_num = 0
			gp.reset_game(true)


func trade_state(action: StringName) -> void:

	if action == Action.CONFIRM:
		enter_pressed = true

	if gp.ui.sub_state == 0:
		if action == Action.MOVE_UP:
			gp.ui.command_num -= 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num < 0:
				gp.ui.command_num = 0
				gp.stop_se()
		if action == Action.MOVE_DOWN:
			gp.ui.command_num += 1
			gp.play_se(SE.CURSOR_MOVE)
			if gp.ui.command_num > 2:
				gp.ui.command_num = 2
				gp.stop_se()

	if gp.ui.sub_state == 1:
		npc_inventory(action)
		if action == Action.OPTIONS:
			gp.ui.sub_state = 0

	if gp.ui.sub_state == 2:
		player_inventory(action)
		if action == Action.OPTIONS:
			gp.ui.sub_state = 0


## The boat timetable. One extra row past the destinations is "Stay here", so
## the cursor range is the row count, not count - 1.
func boat_state(action: StringName) -> void:

	var last: int = gp.ui.boat_rows.size()

	if action == Action.MOVE_UP:
		gp.ui.command_num -= 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num < 0:
			gp.ui.command_num = last
	if action == Action.MOVE_DOWN:
		gp.ui.command_num += 1
		gp.play_se(SE.CURSOR_MOVE)
		if gp.ui.command_num > last:
			gp.ui.command_num = 0
	if action == Action.CONFIRM:
		enter_pressed = true
	if action == Action.OPTIONS:
		# Always a way off the boat, whatever the cursor is on.
		gp.ui.command_num = 0
		gp.game_state = gp.PLAY_STATE


## The ending screen swallows input: the run is over, and the only thing left
## is the title screen.
func ending_state(action: StringName) -> void:

	if action == Action.CONFIRM or action == Action.OPTIONS:
		gp.ui.game_finished = false
		gp.ui.command_num = 0
		gp.ui.title_screen_state = 0
		gp.game_state = gp.TITLE_STATE
		gp.stop_music()


func map_state(action: StringName) -> void:
	if action == Action.WORLD_MAP:
		gp.game_state = gp.PLAY_STATE


func player_inventory(action: StringName) -> void:

	if action == Action.MOVE_UP:
		if gp.ui.player_slot_row != 0:
			gp.ui.player_slot_row -= 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_LEFT:
		if gp.ui.player_slot_col != 0:
			gp.ui.player_slot_col -= 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_DOWN:
		if gp.ui.player_slot_row != 3:
			gp.ui.player_slot_row += 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_RIGHT:
		if gp.ui.player_slot_col != 4:
			gp.ui.player_slot_col += 1
			gp.play_se(SE.CURSOR_MOVE)


func npc_inventory(action: StringName) -> void:

	if action == Action.MOVE_UP:
		if gp.ui.npc_slot_row != 0:
			gp.ui.npc_slot_row -= 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_LEFT:
		if gp.ui.npc_slot_col != 0:
			gp.ui.npc_slot_col -= 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_DOWN:
		if gp.ui.npc_slot_row != 3:
			gp.ui.npc_slot_row += 1
			gp.play_se(SE.CURSOR_MOVE)
	if action == Action.MOVE_RIGHT:
		if gp.ui.npc_slot_col != 4:
			gp.ui.npc_slot_col += 1
			gp.play_se(SE.CURSOR_MOVE)


func action_released(action: StringName) -> void:

	if action == Action.MOVE_UP:
		up_pressed = false
	if action == Action.MOVE_DOWN:
		down_pressed = false
	if action == Action.MOVE_LEFT:
		left_pressed = false
	if action == Action.MOVE_RIGHT:
		right_pressed = false
	if action == Action.SHOOT:
		shot_key_pressed = false
	if action == Action.RUN:
		shift_pressed = false
	if action == Action.CONFIRM:
		enter_pressed = false
	if action == Action.GUARD:
		control_pressed = false
