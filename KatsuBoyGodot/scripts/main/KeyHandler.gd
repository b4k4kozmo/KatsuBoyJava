class_name KeyHandler
extends RefCounted
## Java: main/KeyHandler.java
##
## Godot delivers keys through _unhandled_input() on GamePanel, which forwards
## them to key_pressed()/key_released() here - the same two entry points the
## Swing KeyListener had.

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


func key_pressed(code: int) -> void:

	# TITLE STATE
	if gp.game_state == gp.TITLE_STATE:
		title_state(code)
	# PLAY STATE
	elif gp.game_state == gp.PLAY_STATE:
		play_state(code)
	# PAUSE STATE
	elif gp.game_state == gp.PAUSE_STATE:
		pause_state(code)
	# DIALOGUE STATE
	elif gp.game_state == gp.DIALOGUE_STATE:
		dialogue_state(code)
	# CHARACTER STATE
	elif gp.game_state == gp.CHARACTER_STATE:
		character_state(code)
	# OPTIONS STATE
	elif gp.game_state == gp.OPTION_STATE:
		option_state(code)
	# GAME OVER STATE
	elif gp.game_state == gp.GAME_OVER_STATE:
		game_over_state(code)
	# TRADE STATE
	elif gp.game_state == gp.TRADE_STATE:
		trade_state(code)
	# MAP STATE
	elif gp.game_state == gp.MAP_STATE:
		map_state(code)


func title_state(code: int) -> void:

	if gp.ui.title_screen_state == 0:
		if code == KEY_W:
			gp.ui.command_num -= 1
			gp.play_se(11)
			if gp.ui.command_num < 0:
				gp.stop_se()
				gp.ui.command_num = 0
		if code == KEY_S:
			gp.ui.command_num += 1
			gp.play_se(11)
			if gp.ui.command_num > 2:
				gp.stop_se()
				gp.ui.command_num = 2
		if code == KEY_ENTER:
			if gp.ui.command_num == 0:
				gp.play_se(1)
				gp.ui.title_screen_state = 1
				gp.play_music(0)
			if gp.ui.command_num == 1:
				gp.play_se(1)
				gp.save_load.load_game()
				gp.game_state = gp.PLAY_STATE
				gp.play_music(0)
			if gp.ui.command_num == 2:
				gp.play_se(1)
				gp.get_tree().quit()

	elif gp.ui.title_screen_state == 1:
		if code == KEY_W:
			gp.ui.command_num -= 1
			gp.play_se(11)
			if gp.ui.command_num < 0:
				gp.stop_se()
				gp.ui.command_num = 0
		if code == KEY_S:
			gp.ui.command_num += 1
			gp.play_se(11)
			if gp.ui.command_num > 3:
				gp.stop_se()
				gp.ui.command_num = 3
		if code == KEY_ENTER:

			if gp.ui.command_num == 0:
				# Do some samurai specific stuff
				gp.play_se(1)
				gp.game_state = gp.PLAY_STATE
				gp.player.inventory.append(OBJ_Kamibokken.new(gp))

			if gp.ui.command_num == 1:
				# Do some Ninja specific stuff
				gp.play_se(1)
				gp.game_state = gp.PLAY_STATE
				gp.player.has_boots = true
				gp.ui.command_num = 0

			if gp.ui.command_num == 2:
				# Do some Zilla specific stuff
				gp.play_se(1)
				gp.stop_music()
				gp.play_music(5)
				gp.ui.kamiwhite = gp.ui.kamigreen
				gp.ui.kamipink = gp.ui.kamigreen
				gp.game_state = gp.PLAY_STATE
				gp.player.has_boots = true
				gp.ui.command_num = 0

			if gp.ui.command_num == 3:
				gp.play_se(1)
				gp.ui.title_screen_state = 0
				gp.stop_music()
				gp.ui.command_num = 0


func play_state(code: int) -> void:
	if code == KEY_W:
		up_pressed = true
	if code == KEY_S:
		down_pressed = true
	if code == KEY_A:
		left_pressed = true
	if code == KEY_D:
		right_pressed = true
	if code == KEY_SHIFT:
		shift_pressed = true
	if code == KEY_SPACE:
		shot_key_pressed = true
	if code == KEY_ESCAPE:
		gp.game_state = gp.OPTION_STATE
	if code == KEY_P:
		gp.game_state = gp.PAUSE_STATE
		gp.play_se(1)
	if code == KEY_C:
		gp.game_state = gp.CHARACTER_STATE
		gp.play_se(1)
	if code == KEY_ENTER:
		enter_pressed = true
	if code == KEY_M:
		gp.game_state = gp.MAP_STATE
		gp.play_se(1)
	if code == KEY_X:
		gp.map.mini_map_on = not gp.map.mini_map_on
	if code == KEY_CTRL:
		control_pressed = true

	# DEBUG
	if code == KEY_T:
		if check_draw_time == false:
			check_draw_time = true
			gp.tile_m.draw_path = true
		else:
			check_draw_time = false
			gp.tile_m.draw_path = false


func pause_state(code: int) -> void:
	if code == KEY_P:
		gp.game_state = gp.PLAY_STATE
		gp.play_se(1)


func dialogue_state(code: int) -> void:
	if code == KEY_ENTER:
		enter_pressed = true


func character_state(code: int) -> void:
	if code == KEY_C:
		gp.game_state = gp.PLAY_STATE
		gp.play_se(1)

	if code == KEY_ENTER:
		gp.player.select_item()

	player_inventory(code)


func option_state(code: int) -> void:

	if code == KEY_ESCAPE:
		gp.game_state = gp.PLAY_STATE
	if code == KEY_ENTER:
		enter_pressed = true
		gp.play_se(1)

	var max_command_num := 0
	match gp.ui.sub_state:
		0: max_command_num = 5
		3: max_command_num = 1

	if code == KEY_W:
		gp.ui.command_num -= 1
		gp.play_se(11)
		if gp.ui.command_num < 0:
			gp.ui.command_num = 0
			gp.stop_se()
	if code == KEY_S:
		gp.ui.command_num += 1
		gp.play_se(11)
		if gp.ui.command_num > max_command_num:
			gp.ui.command_num = max_command_num
			gp.stop_se()
	if code == KEY_A:
		if gp.ui.sub_state == 0:
			if gp.ui.command_num == 1 and gp.music.volume_scale > 0:
				gp.music.volume_scale -= 1
				gp.music.check_volume()
				gp.play_se(11)
			if gp.ui.command_num == 2 and gp.se.volume_scale > 0:
				gp.se.volume_scale -= 1
				gp.play_se(11)
	if code == KEY_D:
		if gp.ui.sub_state == 0:
			if gp.ui.command_num == 1 and gp.music.volume_scale < 5:
				gp.music.volume_scale += 1
				gp.music.check_volume()
				gp.play_se(11)
			if gp.ui.command_num == 2 and gp.se.volume_scale < 5:
				gp.se.volume_scale += 1
				gp.play_se(11)


func game_over_state(code: int) -> void:

	if code == KEY_W:
		gp.ui.command_num -= 1
		gp.play_se(11)
		if gp.ui.command_num < 0:
			gp.ui.command_num = 0
			gp.stop_se()

	if code == KEY_S:
		gp.ui.command_num += 1
		gp.play_se(11)
		if gp.ui.command_num > 1:
			gp.ui.command_num = 1
			gp.stop_se()

	if code == KEY_ENTER:
		if gp.ui.command_num == 0:
			gp.game_state = gp.PLAY_STATE
			gp.reset_game(false)
			gp.play_music(0)
		elif gp.ui.command_num == 1:
			gp.game_state = gp.TITLE_STATE
			gp.ui.title_screen_state = 0
			gp.ui.command_num = 0
			gp.reset_game(true)


func trade_state(code: int) -> void:

	if code == KEY_ENTER:
		enter_pressed = true

	if gp.ui.sub_state == 0:
		if code == KEY_W:
			gp.ui.command_num -= 1
			gp.play_se(11)
			if gp.ui.command_num < 0:
				gp.ui.command_num = 0
				gp.stop_se()
		if code == KEY_S:
			gp.ui.command_num += 1
			gp.play_se(11)
			if gp.ui.command_num > 2:
				gp.ui.command_num = 2
				gp.stop_se()

	if gp.ui.sub_state == 1:
		npc_inventory(code)
		if code == KEY_ESCAPE:
			gp.ui.sub_state = 0

	if gp.ui.sub_state == 2:
		player_inventory(code)
		if code == KEY_ESCAPE:
			gp.ui.sub_state = 0


func map_state(code: int) -> void:
	if code == KEY_M:
		gp.game_state = gp.PLAY_STATE


func player_inventory(code: int) -> void:

	if code == KEY_W:
		if gp.ui.player_slot_row != 0:
			gp.ui.player_slot_row -= 1
			gp.play_se(11)
	if code == KEY_A:
		if gp.ui.player_slot_col != 0:
			gp.ui.player_slot_col -= 1
			gp.play_se(11)
	if code == KEY_S:
		if gp.ui.player_slot_row != 3:
			gp.ui.player_slot_row += 1
			gp.play_se(11)
	if code == KEY_D:
		if gp.ui.player_slot_col != 4:
			gp.ui.player_slot_col += 1
			gp.play_se(11)


func npc_inventory(code: int) -> void:

	if code == KEY_W:
		if gp.ui.npc_slot_row != 0:
			gp.ui.npc_slot_row -= 1
			gp.play_se(11)
	if code == KEY_A:
		if gp.ui.npc_slot_col != 0:
			gp.ui.npc_slot_col -= 1
			gp.play_se(11)
	if code == KEY_S:
		if gp.ui.npc_slot_row != 3:
			gp.ui.npc_slot_row += 1
			gp.play_se(11)
	if code == KEY_D:
		if gp.ui.npc_slot_col != 4:
			gp.ui.npc_slot_col += 1
			gp.play_se(11)


func key_released(code: int) -> void:

	if code == KEY_W:
		up_pressed = false
	if code == KEY_S:
		down_pressed = false
	if code == KEY_A:
		left_pressed = false
	if code == KEY_D:
		right_pressed = false
	if code == KEY_SPACE:
		shot_key_pressed = false
	if code == KEY_SHIFT:
		shift_pressed = false
	if code == KEY_ENTER:
		enter_pressed = false
	if code == KEY_CTRL:
		control_pressed = false
