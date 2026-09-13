class_name UI
extends RefCounted
## Java: main/UI.java - every heads up display, menu and dialogue window.

var gp
var maru_monica: Font
## Java: font.deriveFont(Font.BOLD, ...). Godot does bold on a variable font
## through a FontVariation, so we make one up front and switch to it wherever
## the Java code asked for BOLD.
var maru_monica_bold: Font
var amari: Font

var heart_full: Texture2D
var heart_half: Texture2D
var heart_empty: Texture2D
var crystal_full: Texture2D
var crystal_blank: Texture2D
var coin: Texture2D
var coin_icon: Texture2D

var message_on: bool = false
var message: Array[String] = []
var message_counter: Array[int] = []

## The palette, copied from GamePanel's Palette group in the Inspector.
## (The Zilla class recolours these at run time, which is why they are
##  variables rather than read straight from gp.)
var kamigreen: Color
var kamiblack: Color
var kamipink: Color
var kamiwhite: Color

var game_finished: bool = false
var current_dialogue: String = ""
var command_num: int = 0
var title_screen_state: int = 0  # 0: the first screen
var player_slot_col: int = 0
var player_slot_row: int = 0
var npc_slot_col: int = 0
var npc_slot_row: int = 0
var sound_num: int = 17

## Which dock the player is standing on, by dungeon id. The boat hides the
## route back to where you already are.
var boat_dock_of: String = ""
## The rows the boat menu last drew, so the input handler and the draw code
## agree on what row 2 means.
var boat_rows: Array[Dictionary] = []

var sub_state: int = 0
var counter: int = 0
var npc: Entity
var char_index: int = 0
var combined_text: String = ""

## The Graphics2D we are currently drawing onto (GamePanel). Java stored the
## same reference in a field called g2.
var g2


func _init(gp) -> void:
	self.gp = gp

	reset_palette()

	maru_monica = load("res://assets/font/x12y16pxMaruMonica.ttf")
	amari = load("res://assets/font/Amari_Font_15-100VF.ttf")

	var bold := FontVariation.new()
	bold.base_font = maru_monica
	bold.variation_embolden = 0.6
	maru_monica_bold = bold

	# CREATE HUD OBJECTS
	var heart := OBJ_Heart.new(gp)
	heart_full = heart.image
	heart_half = heart.image2
	heart_empty = heart.image3
	var crystal := OBJ_ManaCrystal.new(gp)
	crystal_full = crystal.image
	crystal_blank = crystal.image2
	var kami_coin := OBJ_Coin.new(gp)
	coin = kami_coin.down1
	# A 2x version for the little price boxes. Drawing the 3x world sprite into
	# a 32px box resampled it and made those pixels a different size to
	# everything else on screen.
	coin_icon = kami_coin.setup("/objects/coin", 32, 32)


## Put the colours back to what the Inspector says.
func reset_palette() -> void:
	kamigreen = gp.color_green
	kamiblack = gp.color_black
	kamipink = gp.color_pink
	kamiwhite = gp.color_white


func add_message(text: String) -> void:
	message.append(text)
	message_counter.append(0)


func draw(g2) -> void:

	self.g2 = g2

	g2.set_font(maru_monica, 24)
	g2.set_color(kamipink)

	# TITLE STATE
	if gp.game_state == gp.TITLE_STATE:
		draw_title_screen()
	# PLAY STATE
	if gp.game_state == gp.PLAY_STATE:
		draw_player_life()
		draw_clock()
		draw_message()
		command_num = 0
	# PAUSE STATE
	if gp.game_state == gp.PAUSE_STATE:
		draw_player_life()
		draw_clock()
		draw_pause_screen()
	# DIALOGUE STATE
	if gp.game_state == gp.DIALOGUE_STATE:
		draw_dialogue_screen()
	# CHARACTER STATE
	if gp.game_state == gp.CHARACTER_STATE:
		draw_character_screen()
		draw_inventory(gp.player, true)
	# OPTION STATE
	if gp.game_state == gp.OPTION_STATE:
		draw_option_screen()
	# GAME OVER
	if gp.game_state == gp.GAME_OVER_STATE:
		draw_game_over_screen()
	# TRANSITION STATE
	if gp.game_state == gp.TRANSITION_STATE:
		draw_transition()
	# TRADE STATE
	if gp.game_state == gp.BOAT_STATE:
		draw_boat_screen()
	if gp.game_state == gp.ENDING_STATE:
		draw_ending_screen()
	if gp.game_state == gp.TRADE_STATE:
		draw_trade_screen()
	# SLEEP STATE
	if gp.game_state == gp.SLEEP_STATE:
		draw_sleep_screen()


func draw_player_life() -> void:

	@warning_ignore("integer_division")
	var x: int = gp.tile_size / 2
	@warning_ignore("integer_division")
	var y: int = gp.tile_size / 2
	var i := 0

	# DRAW MAX LIFE
	@warning_ignore("integer_division")
	while i < gp.player.max_life / 2:
		g2.draw_img(heart_empty, x, y)
		i += 1
		x += gp.tile_size

	# RESET
	@warning_ignore("integer_division")
	x = gp.tile_size / 2
	@warning_ignore("integer_division")
	y = gp.tile_size / 2
	i = 0

	# DRAW CURRENT LIFE
	while i < gp.player.life:
		g2.draw_img(heart_half, x, y)
		i += 1
		if i < gp.player.life:
			g2.draw_img(heart_full, x, y)
		i += 1
		x += gp.tile_size

	# DRAW MAX MANA
	@warning_ignore("integer_division")
	x = (gp.tile_size / 2) - 5
	y = int(gp.tile_size * 1.5)
	i = 0
	while i < gp.player.max_mana:
		g2.draw_img(crystal_blank, x, y)
		i += 1
		x += 35

	# DRAW MANA
	@warning_ignore("integer_division")
	x = (gp.tile_size / 2) - 5
	y = int(gp.tile_size * 1.5)
	i = 0
	while i < gp.player.mana:
		g2.draw_img(crystal_full, x, y)
		i += 1
		x += 35


## Age the on-screen messages. Ticks with the game so a message always lasts
## the same three seconds, whatever the frame rate.
func update_messages() -> void:

	var i := 0
	while i < message.size():
		message_counter[i] = message_counter[i] + 1
		if message_counter[i] > 180:
			message.remove_at(i)
			message_counter.remove_at(i)
		else:
			i += 1


## The day, the time and what part of the day it is, in a little window along
## the top. Sits between the hearts and the mini map.
func draw_clock() -> void:

	if not gp.show_clock or gp.e_manager == null or gp.e_manager.clock == null:
		return

	var clock: GameClock = gp.e_manager.clock

	var width: int = gp.tile_size * 6
	var height: int = int(gp.tile_size * 1.8)
	@warning_ignore("integer_division")
	var x: int = gp.screen_width / 2 - width / 2
	var y := 10

	draw_sub_window(x, y, width, height)

	# day and time
	g2.set_font(maru_monica, 30)
	g2.set_color(kamiwhite)
	var text: String = clock.day_name() + "   " + clock.time_string()
	g2.draw_str(text, get_x_for_centered_text(text), y + 36)

	# morning / afternoon / evening / sunrise / sunset / night
	g2.set_font(maru_monica, 26)
	g2.set_color(kamigreen)
	var period: String = clock.period_name()
	g2.draw_str(period, get_x_for_centered_text(period), y + 68)


func draw_message() -> void:

	var message_x: int = gp.tile_size
	var message_y: int = gp.tile_size * 4
	g2.set_font(maru_monica_bold, 32)

	for i in range(message.size()):
		g2.set_color(kamiblack)
		g2.draw_str(message[i], message_x + 2, message_y + 2)
		g2.set_color(kamiwhite)
		g2.draw_str(message[i], message_x, message_y)
		message_y += 50


func draw_title_screen() -> void:

	# TITLE NAME
	if title_screen_state == 0:

		g2.set_color(kamiblack)
		g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)

		g2.set_font(maru_monica_bold, 96)
		var text := "Katsu Boy Adventure"
		var x: int = get_x_for_centered_text(text)
		var y: int = gp.tile_size * 3

		# TEXT SHADOW
		g2.set_color(kamigreen)
		g2.draw_str(text, x + 3, y + 3)

		# MAIN COLOR
		g2.set_color(kamiwhite)
		g2.draw_str(text, x, y)

		# TITLE IMAGE
		@warning_ignore("integer_division")
		x = gp.screen_width / 2 - (gp.tile_size * 2) / 2
		y += gp.tile_size * 2
		g2.draw_img_scaled(gp.player.down1, x, y, gp.tile_size * 2, gp.tile_size * 2)

		# MENU
		g2.set_font(maru_monica, 40)

		text = "NEW GAME"
		x = get_x_for_centered_text(text)
		y += gp.tile_size * 4
		g2.draw_str(text, x, y)
		if command_num == 0:
			g2.draw_str(">", x - gp.tile_size, y)

		text = "LOAD GAME"
		x = get_x_for_centered_text(text)
		y += gp.tile_size
		g2.draw_str(text, x, y)
		if command_num == 1:
			g2.draw_str(">", x - gp.tile_size, y)

		text = "QUIT"
		x = get_x_for_centered_text(text)
		y += gp.tile_size
		g2.draw_str(text, x, y)
		if command_num == 2:
			g2.draw_str(">", x - gp.tile_size, y)

	elif title_screen_state == 1:

		g2.set_color(kamiblack)
		g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)

		g2.set_color(kamigreen)
		g2.set_font(maru_monica, 42)

		var text := "Select your class"
		var x: int = get_x_for_centered_text(text)
		var y: int = gp.tile_size * 3
		g2.draw_str(text, x, y)

		text = "Samurai"
		x = get_x_for_centered_text(text)
		y += gp.tile_size * 3
		g2.draw_str(text, x, y)
		if command_num == 0:
			g2.draw_str(">", x - gp.tile_size, y)

		text = "Ninja"
		x = get_x_for_centered_text(text)
		y += gp.tile_size
		g2.draw_str(text, x, y)
		if command_num == 1:
			g2.draw_str(">", x - gp.tile_size, y)

		text = "Zilla"
		x = get_x_for_centered_text(text)
		y += gp.tile_size
		g2.draw_str(text, x, y)
		if command_num == 2:
			g2.draw_str(">", x - gp.tile_size, y)

		text = "Back"
		x = get_x_for_centered_text(text)
		y += gp.tile_size * 2
		g2.draw_str(text, x, y)
		if command_num == 3:
			g2.draw_str(">", x - gp.tile_size, y)


func draw_pause_screen() -> void:

	g2.set_font(maru_monica, 80)
	g2.set_color(kamipink)
	var text := "PAUSED"
	var x: int = get_x_for_centered_text(text)
	@warning_ignore("integer_division")
	var y: int = gp.screen_height / 2

	g2.draw_str(text, x, y)

	# What you are supposed to be doing, worked out from the quest log rather
	# than tracked separately, so it cannot drift out of step with the game.
	if gp.quest == null or gp.dungeons.is_empty():
		return

	g2.set_font(maru_monica, 28)
	g2.set_color(kamiwhite)
	var carried: Array[String] = []
	for item in gp.player.inventory:
		if item is OBJ_BoatTicket and not carried.has(item.route_id):
			carried.append(item.route_id)

	var objective: String = gp.quest.objective_text(gp.dungeons, carried)
	g2.draw_str(objective, get_x_for_centered_text(objective), y + gp.tile_size)

	var counted: int = QuestLog.countable(gp.dungeons).size()
	if counted > 0:
		var tally := "%d of %d dungeons cleared" % [gp.quest.cleared_count(gp.dungeons), counted]
		g2.set_font(maru_monica, 22)
		g2.set_color(kamigreen)
		g2.draw_str(tally, get_x_for_centered_text(tally), y + int(gp.tile_size * 1.7))


func draw_dialogue_screen() -> void:

	if npc == null:
		return

	# WINDOW
	var x: int = gp.tile_size * 3
	@warning_ignore("integer_division")
	var y: int = gp.tile_size / 2
	var width: int = gp.screen_width - (gp.tile_size * 6)
	var height: int = gp.tile_size * 4

	draw_sub_window(x, y, width, height)

	g2.set_font(maru_monica, 28)
	g2.set_color(kamipink)
	x += gp.tile_size
	y += gp.tile_size

	if npc.dialogues[npc.dialogue_set][npc.dialogue_index] != null:

		var characters: String = npc.dialogues[npc.dialogue_set][npc.dialogue_index]

		if char_index < characters.length():
			gp.play_se(sound_num)
			combined_text = combined_text + characters[char_index]
			current_dialogue = combined_text
			char_index += 1

		if gp.key_h.enter_pressed == true:

			char_index = 0
			combined_text = ""

			if gp.game_state == gp.DIALOGUE_STATE:
				npc.dialogue_index += 1
				gp.key_h.enter_pressed = false

	else:  # if there is no text in the array
		npc.dialogue_index = 0

		if gp.game_state == gp.DIALOGUE_STATE:
			gp.game_state = gp.PLAY_STATE

	for line in current_dialogue.split("\n"):
		g2.draw_str(line, x, y)
		y += 40


func draw_character_screen() -> void:

	# CREATE A FRAME
	var frame_x: int = gp.tile_size * 2
	var frame_y: int = gp.tile_size
	var frame_width: int = gp.tile_size * 5
	var frame_height: int = gp.tile_size * 10
	draw_sub_window(frame_x, frame_y, frame_width, frame_height)

	# TEXT
	g2.set_color(kamiwhite)
	g2.set_font(maru_monica, 32)

	var text_x: int = frame_x + 20
	var text_y: int = frame_y + gp.tile_size
	var line_height := 35

	# NAMES
	g2.draw_str("Level", text_x, text_y); text_y += line_height
	g2.draw_str("Life", text_x, text_y); text_y += line_height
	g2.draw_str("Mana", text_x, text_y); text_y += line_height
	g2.draw_str("Strength", text_x, text_y); text_y += line_height
	g2.draw_str("Dexterity", text_x, text_y); text_y += line_height
	g2.draw_str("Attack", text_x, text_y); text_y += line_height
	g2.draw_str("Defense", text_x, text_y); text_y += line_height
	g2.draw_str("Exp", text_x, text_y); text_y += line_height
	g2.draw_str("Next Level", text_x, text_y); text_y += line_height
	g2.draw_str("Coin", text_x, text_y); text_y += line_height + 10
	g2.draw_str("Weapon", text_x, text_y); text_y += line_height + 15
	g2.draw_str("Shield", text_x, text_y); text_y += line_height

	# VALUES
	var tail_x: int = (frame_x + frame_width) - 30
	# Reset text_y
	text_y = frame_y + gp.tile_size
	var value: String

	# (Java printed life over maxMana and mana over maxLife here - swapped.)
	var values: Array[String] = [
		str(gp.player.level),
		str(gp.player.life) + "/" + str(gp.player.max_life),
		str(gp.player.mana) + "/" + str(gp.player.max_mana),
		str(gp.player.strength),
		str(gp.player.dexterity),
		str(gp.player.attack),
		str(gp.player.defense),
		str(gp.player.exp),
		str(gp.player.next_level_exp),
		str(gp.player.coin),
	]

	for v in values:
		value = v
		text_x = get_x_for_align_to_right_text(value, tail_x)
		g2.draw_str(value, text_x, text_y)
		text_y += line_height

	g2.draw_img(gp.player.current_weapon.down1, tail_x - gp.tile_size, text_y - 24)
	text_y += gp.tile_size

	g2.draw_img(gp.player.current_shield.down1, tail_x - gp.tile_size, text_y - 24)


func draw_inventory(entity, cursor: bool) -> void:

	var frame_x := 0
	var frame_y := 0
	var frame_width := 0
	var frame_height := 0
	var slot_col := 0
	var slot_row := 0

	if entity == gp.player:
		frame_x = gp.tile_size * 12
		frame_y = gp.tile_size
		frame_width = gp.tile_size * 6
		frame_height = gp.tile_size * 5
		slot_col = player_slot_col
		slot_row = player_slot_row
	else:
		frame_x = gp.tile_size * 2
		frame_y = gp.tile_size
		frame_width = gp.tile_size * 6
		frame_height = gp.tile_size * 5
		slot_col = npc_slot_col
		slot_row = npc_slot_row

	# FRAME
	draw_sub_window(frame_x, frame_y, frame_width, frame_height)

	# SLOT
	var slot_x_start: int = frame_x + 20
	var slot_y_start: int = frame_y + 20
	var slot_x: int = slot_x_start
	var slot_y: int = slot_y_start
	var slot_size: int = gp.tile_size + 3

	# DRAW THE ITEMS
	for i in range(entity.inventory.size()):

		# EQUIP CURSOR
		if (entity.inventory[i] == entity.current_weapon
				or entity.inventory[i] == entity.current_shield
				or entity.inventory[i] == entity.current_light):
			g2.set_color(Color(kamipink, 200.0 / 255.0))  # transparent kamipink
			g2.fill_round_rect(slot_x, slot_y, gp.tile_size, gp.tile_size, 10, 10)

		g2.draw_img(entity.inventory[i].down1, slot_x, slot_y)

		# DISPLAY AMOUNT
		if entity == gp.player and entity.inventory[i].amount > 1:

			g2.set_font(maru_monica, 32)
			var s: String = str(entity.inventory[i].amount)
			var amount_x: int = get_x_for_align_to_right_text(s, slot_x + 44)
			var amount_y: int = slot_y + gp.tile_size

			# SHADOW
			g2.set_color(kamiblack)
			g2.draw_str(s, amount_x, amount_y)
			# NUMBER
			g2.set_color(kamiwhite)
			g2.draw_str(s, amount_x - 3, amount_y - 3)

		slot_x += slot_size

		if i == 4 or i == 9 or i == 14:
			slot_x = slot_x_start
			slot_y += slot_size

	# CURSOR
	if cursor == true:
		var cursor_x: int = slot_x_start + (slot_size * slot_col)
		var cursor_y: int = slot_y_start + (slot_size * slot_row)
		var cursor_width: int = gp.tile_size
		var cursor_height: int = gp.tile_size
		# DRAW CURSOR
		g2.set_color(kamipink)
		g2.set_stroke(3)
		g2.draw_round_rect(cursor_x, cursor_y, cursor_width, cursor_height, 10, 10)

		# DESCRIPTION FRAME
		var d_frame_x: int = frame_x
		var d_frame_y: int = frame_y + frame_height
		var d_frame_width: int = frame_width
		var d_frame_height: int = gp.tile_size * 3

		# DRAW DESCRIPTION TEXT
		var text_x: int = d_frame_x + 20
		var text_y: int = d_frame_y + gp.tile_size
		g2.set_font(maru_monica, 28)

		var item_index: int = get_item_index_on_slot(slot_col, slot_row)

		if item_index < entity.inventory.size():

			draw_sub_window(d_frame_x, d_frame_y, d_frame_width, d_frame_height)
			g2.set_color(kamipink)

			for line in entity.inventory[item_index].description.split("\n"):
				g2.draw_str(line, text_x, text_y)
				text_y += 32


func draw_game_over_screen() -> void:

	g2.set_color(Color(kamiblack, 150.0 / 255.0))  # transparent kamiblack
	g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)

	var x: int
	var y: int
	var text: String
	g2.set_font(maru_monica_bold, 110)

	text = "Game Over"
	# Shadow
	g2.set_color(kamipink)
	x = get_x_for_centered_text(text)
	y = gp.tile_size * 4
	g2.draw_str(text, x, y)
	# Main
	g2.set_color(kamiwhite)
	g2.draw_str(text, x - 4, y - 4)

	# Retry
	g2.set_font(maru_monica, 50)
	text = "Retry"
	x = get_x_for_centered_text(text)
	y += gp.tile_size * 4
	g2.draw_str(text, x, y)
	if command_num == 0:
		g2.draw_str(">", x - 40, y)

	# Title
	text = "Quit"
	x = get_x_for_centered_text(text)
	y += 55
	g2.draw_str(text, x, y)
	if command_num == 1:
		g2.draw_str(">", x - 40, y)


func draw_option_screen() -> void:

	g2.set_color(kamiwhite)
	g2.set_font(maru_monica, 32)

	# SUB WINDOW
	var frame_x: int = gp.tile_size * 6
	var frame_y: int = gp.tile_size
	var frame_width: int = gp.tile_size * 8
	var frame_height: int = gp.tile_size * 10
	draw_sub_window(frame_x, frame_y, frame_width, frame_height)

	match sub_state:
		0: option_top(frame_x, frame_y)
		1: option_full_screen_notification(frame_x, frame_y)
		2: option_control(frame_x, frame_y)
		3: option_end_game_confirmation(frame_x, frame_y)

	gp.key_h.enter_pressed = false


func option_top(frame_x: int, frame_y: int) -> void:

	var text_x: int
	var text_y: int

	# TITLE
	var text := "Options"
	text_x = get_x_for_centered_text(text)
	text_y = frame_y + gp.tile_size
	g2.draw_str(text, text_x, text_y)

	# FULL SCREEN ON/OFF
	text_x = frame_x + gp.tile_size
	text_y += gp.tile_size * 2
	g2.draw_str("Full Screen", text_x, text_y)
	if command_num == 0:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			gp.full_screen_on = not gp.full_screen_on
			# Java needed a restart for this; Godot can switch straight away.
			if gp.full_screen_on == true:
				gp.set_full_screen()
			else:
				gp.set_windowed()
			sub_state = 1

	# MUSIC
	text_y += gp.tile_size
	g2.draw_str("Music", text_x, text_y)
	if command_num == 1:
		g2.draw_str(">", text_x - 25, text_y)
	# SE
	text_y += gp.tile_size
	g2.draw_str("Sound Effects", text_x, text_y)
	if command_num == 2:
		g2.draw_str(">", text_x - 25, text_y)
	# CONTROL
	text_y += gp.tile_size
	g2.draw_str("Control", text_x, text_y)
	if command_num == 3:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 2
			command_num = 0
	# END GAME
	text_y += gp.tile_size
	g2.draw_str("End Game", text_x, text_y)
	if command_num == 4:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 3
			command_num = 0
	# BACK
	text_y += gp.tile_size * 2
	g2.draw_str("Back", text_x, text_y)
	if command_num == 5:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			gp.game_state = gp.PLAY_STATE
			command_num = 0
			gp.config.save_config()

	# FULL SCREEN CHECK BOX
	text_x = frame_x + int(gp.tile_size * 4.5)
	@warning_ignore("integer_division")
	text_y = frame_y + gp.tile_size * 2 + (gp.tile_size / 2)
	g2.set_stroke(3)
	g2.draw_round_rect(text_x, text_y, 24, 24, 8, 8)
	if gp.full_screen_on == true:
		g2.fill_round_rect(text_x, text_y, 24, 24, 8, 8)

	# MUSIC VOLUME
	text_y += gp.tile_size
	g2.draw_round_rect(text_x, text_y, 120, 24, 8, 8)  # 120/5 = 24
	var volume_width: int = 24 * gp.music.volume_scale
	g2.fill_round_rect(text_x, text_y, volume_width, 24, 8, 8)

	# SE VOLUME
	text_y += gp.tile_size
	g2.draw_round_rect(text_x, text_y, 120, 24, 8, 8)
	volume_width = 24 * gp.se.volume_scale
	g2.fill_round_rect(text_x, text_y, volume_width, 24, 8, 8)


func option_full_screen_notification(frame_x: int, frame_y: int) -> void:

	var text_x: int = frame_x + gp.tile_size
	var text_y: int = frame_y + gp.tile_size

	current_dialogue = "Full screen has been \nswitched."

	for line in current_dialogue.split("\n"):
		g2.draw_str(line, text_x, text_y)
		text_y += 40

	# BACK
	text_y = frame_y + gp.tile_size * 9
	g2.draw_str("Back", text_x, text_y)
	if command_num == 0:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 0
			gp.config.save_config()


func option_control(frame_x: int, frame_y: int) -> void:

	var text_x: int
	var text_y: int

	# TITLE
	var text := "Control"
	text_x = get_x_for_centered_text(text)
	text_y = frame_y + gp.tile_size
	g2.draw_str(text, text_x, text_y)

	text_x = frame_x + gp.tile_size
	text_y += gp.tile_size
	g2.draw_str("Move", text_x, text_y); text_y += gp.tile_size
	g2.draw_str("Confirm/Attack", text_x, text_y); text_y += gp.tile_size
	g2.draw_str("Shoot/Cast", text_x, text_y); text_y += gp.tile_size
	g2.draw_str("Character Screen", text_x, text_y); text_y += gp.tile_size
	g2.draw_str("Pause", text_x, text_y); text_y += gp.tile_size
	g2.draw_str("Options", text_x, text_y); text_y += gp.tile_size

	# Read straight from the Input Map, so this screen always tells the truth
	# even after the keys are rebound in Project Settings.
	text_x = frame_x + gp.tile_size * 6
	text_y = frame_y + gp.tile_size * 2
	g2.draw_str(Action.movement_keys(), text_x, text_y); text_y += gp.tile_size
	g2.draw_str(Action.key_name(Action.CONFIRM), text_x, text_y); text_y += gp.tile_size
	g2.draw_str(Action.key_name(Action.SHOOT), text_x, text_y); text_y += gp.tile_size
	g2.draw_str(Action.key_name(Action.CHARACTER_SCREEN), text_x, text_y); text_y += gp.tile_size
	g2.draw_str(Action.key_name(Action.PAUSE), text_x, text_y); text_y += gp.tile_size
	g2.draw_str(Action.key_name(Action.OPTIONS), text_x, text_y); text_y += gp.tile_size

	# BACK
	text_x = frame_x + gp.tile_size
	text_y = frame_y + gp.tile_size * 9
	g2.draw_str("Back", text_x, text_y)
	if command_num == 0:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 0
			command_num = 3


func option_end_game_confirmation(frame_x: int, frame_y: int) -> void:

	var text_x: int = frame_x + gp.tile_size
	var text_y: int = frame_y + gp.tile_size * 3

	current_dialogue = "Are you sure you'd like to \nreturn to the title screen?"

	for line in current_dialogue.split("\n"):
		g2.draw_str(line, text_x, text_y)
		text_y += 40

	# YES
	var text := "Yes"
	text_x = get_x_for_centered_text(text)
	text_y += gp.tile_size * 3
	g2.draw_str(text, text_x, text_y)
	if command_num == 0:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 0
			gp.game_state = gp.TITLE_STATE
			title_screen_state = 0
			gp.stop_music()
			gp.reset_game(true)

	# NO
	text = "No"
	text_x = get_x_for_centered_text(text)
	text_y += gp.tile_size
	g2.draw_str(text, text_x, text_y)
	if command_num == 1:
		g2.draw_str(">", text_x - 25, text_y)
		if gp.key_h.enter_pressed == true:
			sub_state = 0
			command_num = 4


## Java advanced this inside the draw call, because its draw loop WAS the 60 FPS
## game loop. Here drawing happens at the monitor's rate, so anything that
## changes game state has to tick with the game instead - otherwise the fade
## runs at a different speed on every machine, and stalls completely if the
## window stops rendering.
func update_transition() -> void:

	counter += 2

	if counter >= 50:
		counter = 0
		gp.game_state = gp.PLAY_STATE
		gp.current_map = gp.e_handler.temp_map
		gp.player.world_x = gp.tile_size * gp.e_handler.temp_col
		gp.player.world_y = gp.tile_size * gp.e_handler.temp_row
		gp.e_handler.prev_event_x = gp.player.world_x
		gp.e_handler.prev_event_y = gp.player.world_y


func draw_transition() -> void:
	g2.set_color(Color(kamiblack, mini(counter * 5, 255) / 255.0))
	g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)


## The boat timetable. Draws every route the player could ever take, with the
## reason any of them are unavailable, so the timetable teaches itself rather
## than needing a wiki.
func draw_boat_screen() -> void:

	var day: int = gp.e_manager.clock.day_index if gp.e_manager and gp.e_manager.clock else 0

	# What is in the bag only changes the wording of a blocked row: a ticket
	# you are carrying has to be stamped by the collector before it is passage.
	var carried: Array[String] = []
	for item in gp.player.inventory:
		if item is OBJ_BoatTicket and not carried.has(item.route_id):
			carried.append(item.route_id)

	boat_rows = BoatService.destinations(gp.dungeons, gp.quest, day, carried)
	# Never offer to sail to the dock you are standing on.
	if not boat_dock_of.is_empty():
		var kept: Array[Dictionary] = []
		for row in boat_rows:
			if row["info"].id != boat_dock_of:
				kept.append(row)
		boat_rows = kept

	var x: int = gp.tile_size * 2
	var y: int = gp.tile_size
	var width: int = gp.tile_size * 16
	var height: int = gp.tile_size * 10
	draw_sub_window(x, y, width, height)

	g2.set_font(maru_monica, 32)
	g2.set_color(kamiwhite)

	var text_x: int = x + gp.tile_size
	var text_y: int = y + gp.tile_size + 8

	g2.set_color(kamipink)
	g2.draw_str("THE WUNDERBOAT", text_x, text_y)
	g2.set_color(kamiwhite)
	var clock_text: String = gp.e_manager.clock.day_name() if gp.e_manager and gp.e_manager.clock else "Today"
	g2.draw_str(clock_text, x + width - gp.tile_size * 4, text_y)
	text_y += int(gp.tile_size * 0.9)

	if boat_rows.is_empty():
		g2.draw_str("No routes from here yet.", text_x, text_y + gp.tile_size)
		g2.draw_str("[ESC] Back", text_x, y + height - 24)
		gp.key_h.enter_pressed = false
		return

	command_num = clampi(command_num, 0, boat_rows.size())

	for i in range(boat_rows.size()):
		var row: Dictionary = boat_rows[i]
		var info: DungeonInfo = row["info"]

		# Available routes read clearly; blocked ones are dimmed but still
		# legible, because the reason is the useful part.
		if row["sailing"]:
			g2.set_color(kamiwhite if i != command_num else kamipink)
		else:
			g2.set_color(kamigreen)

		var label: String = info.display_name
		if row["cleared"]:
			label += "  (cleared)"
		g2.draw_str(label, text_x, text_y)

		var note: String = row["reason"]
		if note.is_empty():
			note = "%s  -  sails %s" % [info.scale_text(), info.timetable_text()]
		g2.set_font(maru_monica, 22)
		g2.draw_str(note, text_x + gp.tile_size * 6, text_y)
		g2.set_font(maru_monica, 32)

		if i == command_num:
			g2.set_color(kamipink)
			g2.draw_str(">", text_x - 26, text_y)
			if gp.key_h.enter_pressed and row["sailing"]:
				gp.key_h.enter_pressed = false
				if gp.event_h.sail_to(info):
					command_num = 0
				return

		text_y += int(gp.tile_size * 0.8)

	# "Stay here" is always the last row, so ESC is never the only way out.
	g2.set_color(kamiwhite if command_num != boat_rows.size() else kamipink)
	text_y += 10
	g2.draw_str("Stay here", text_x, text_y)
	if command_num == boat_rows.size():
		g2.draw_str(">", text_x - 26, text_y)
		if gp.key_h.enter_pressed:
			gp.key_h.enter_pressed = false
			command_num = 0
			gp.game_state = gp.PLAY_STATE

	g2.set_font(maru_monica, 22)
	g2.set_color(kamiwhite)
	g2.draw_str("[ESC] Back", text_x, y + height - 24)

	gp.key_h.enter_pressed = false


## Shown after sailing home with every dungeon cleared.
func draw_ending_screen() -> void:

	g2.set_color(Color(0, 0, 0, 0.85))
	g2.fill_rect(0, 0, gp.screen_width, gp.screen_height)

	g2.set_font(amari, 72)
	g2.set_color(kamipink)
	var title := "THE ADVENTURE ENDS"
	g2.draw_str(title, get_x_for_centered_text(title), gp.tile_size * 3)

	g2.set_font(maru_monica, 34)
	g2.set_color(kamiwhite)
	var lines := [
		"Katsu Boy sailed home.",
		"",
		"Level %d" % gp.player.level,
		"%d coins" % gp.player.coin,
		"%d dungeons cleared" % gp.quest.cleared_count(gp.dungeons),
	]
	var line_y: int = gp.tile_size * 5
	for line in lines:
		if not line.is_empty():
			g2.draw_str(line, get_x_for_centered_text(line), line_y)
		line_y += 44

	g2.set_font(maru_monica, 28)
	g2.set_color(kamigreen)
	var prompt := "Thanks for playing"
	g2.draw_str(prompt, get_x_for_centered_text(prompt), gp.screen_height - gp.tile_size)


func draw_trade_screen() -> void:

	match sub_state:
		0: trade_select()
		1: trade_buy()
		2: trade_sell()
	gp.key_h.enter_pressed = false


func trade_select() -> void:

	npc.dialogue_set = 0
	draw_dialogue_screen()

	# DRAW WINDOW
	var x: int = gp.tile_size * 15
	var y: int = gp.tile_size * 4
	var width: int = gp.tile_size * 3
	var height: int = int(gp.tile_size * 3.5)
	draw_sub_window(x, y, width, height)

	# DRAW TEXT
	x += gp.tile_size
	y += gp.tile_size

	g2.draw_str("Buy", x, y)
	if command_num == 0:
		g2.draw_str(">", x - 25, y)
		if gp.key_h.enter_pressed == true:
			sub_state = 1
	y += gp.tile_size
	g2.draw_str("Sell", x, y)
	if command_num == 1:
		g2.draw_str(">", x - 25, y)
		if gp.key_h.enter_pressed == true:
			sub_state = 2
	y += gp.tile_size
	g2.draw_str("Leave", x, y)
	if command_num == 2:
		g2.draw_str(">", x - 25, y)
		if gp.key_h.enter_pressed == true:
			command_num = 0
			npc.start_dialogue(npc, 1)

	gp.key_h.enter_pressed = false


func trade_buy() -> void:

	# player inventory, no cursor
	draw_inventory(gp.player, false)
	# npc inventory, with cursor
	draw_inventory(npc, true)

	g2.set_font(maru_monica, 32)
	g2.set_color(kamipink)

	# DRAW HINT WINDOW
	var x: int = gp.tile_size * 2
	var y: int = gp.tile_size * 9
	var width: int = gp.tile_size * 6
	var height: int = gp.tile_size * 2
	draw_sub_window(x, y, width, height)
	g2.draw_str("[ESC] Back", x + 24, y + 60)

	# DRAW PLAYER COIN WINDOW
	x = gp.tile_size * 12
	y = gp.tile_size * 9
	width = gp.tile_size * 6
	height = gp.tile_size * 2
	draw_sub_window(x, y, width, height)
	g2.draw_str("Kami Coin: " + str(gp.player.coin), x + 24, y + 60)

	# DRAW PRICE WINDOW
	var item_index: int = get_item_index_on_slot(npc_slot_col, npc_slot_row)
	if item_index < npc.inventory.size():

		x = int(gp.tile_size * 5.5)
		y = int(gp.tile_size * 5.5)
		width = int(gp.tile_size * 2.5)
		height = gp.tile_size
		draw_sub_window(x, y, width, height)
		g2.draw_img(coin_icon, x + 10, y + 8)

		# Friday is a sale day - see assets/data/days/
		var price: int = DayEffect.apply(npc.inventory[item_index].price,
				gp.today().shop_price_multiplier)
		var text: String = str(price)
		x = get_x_for_align_to_right_text(text, gp.tile_size * 8 - 30)
		g2.draw_str(text, x, y + 34)

		# BUY AN ITEM
		if gp.key_h.enter_pressed == true:
			if gp.player.is_cursed == true:
				npc.start_dialogue(npc, 8)
			else:
				if price > gp.player.coin:
					sub_state = 0
					npc.start_dialogue(npc, 2)
					gp.play_se(SE.RECEIVE_DAMAGE)
				else:
					if gp.player.can_obtain_item(npc.inventory[item_index]) == true:
						sub_state = 0
						gp.player.coin -= price
						npc.start_dialogue(npc, 3)
						gp.play_se(SE.COIN)
					else:
						command_num = 0
						sub_state = 0
						npc.start_dialogue(npc, 4)
						gp.play_se(SE.RECEIVE_DAMAGE)


func trade_sell() -> void:

	# player inventory, with cursor
	draw_inventory(gp.player, true)

	g2.set_font(maru_monica, 32)
	g2.set_color(kamipink)

	var x: int
	var y: int
	var width: int
	var height: int

	# DRAW HINT WINDOW
	x = gp.tile_size * 2
	y = gp.tile_size * 9
	width = gp.tile_size * 6
	height = gp.tile_size * 2
	draw_sub_window(x, y, width, height)
	g2.draw_str("[ESC] Back", x + 24, y + 60)

	# DRAW PLAYER COIN WINDOW
	x = gp.tile_size * 12
	y = gp.tile_size * 9
	width = gp.tile_size * 6
	height = gp.tile_size * 2
	draw_sub_window(x, y, width, height)
	g2.draw_str("Kami Coin: " + str(gp.player.coin), x + 24, y + 60)

	# DRAW PRICE WINDOW
	var item_index: int = get_item_index_on_slot(player_slot_col, player_slot_row)
	if item_index < gp.player.inventory.size():

		x = int(gp.tile_size * 15.5)
		y = int(gp.tile_size * 5.5)
		width = int(gp.tile_size * 2.5)
		height = gp.tile_size
		draw_sub_window(x, y, width, height)
		g2.draw_img(coin_icon, x + 10, y + 8)

		@warning_ignore("integer_division")
		var price: int = gp.player.inventory[item_index].price / 2
		var text: String = str(price)
		x = get_x_for_align_to_right_text(text, gp.tile_size * 18 - 30)
		g2.draw_str(text, x, y + 34)

		# SELL AN ITEM
		if gp.key_h.enter_pressed == true:

			if (gp.player.inventory[item_index] == gp.player.current_weapon
					or gp.player.inventory[item_index] == gp.player.current_shield):
				command_num = 0
				sub_state = 0
				npc.start_dialogue(npc, 5)
				gp.play_se(SE.RECEIVE_DAMAGE)
			else:
				sub_state = 0
				if gp.player.inventory[item_index].amount > 1:
					gp.player.inventory[item_index].amount -= 1
				else:
					gp.player.inventory.remove_at(item_index)

				if (gp.e_manager.lighting.day_state == gp.e_manager.lighting.NIGHT
						and gp.player.is_cursed == false):
					gp.player.coin += (price * 10)
					npc.start_dialogue(npc, 6)
					gp.play_se(SE.COIN)
				else:
					gp.player.coin += price
					npc.start_dialogue(npc, 7)
					gp.play_se(SE.COIN)


## Ticks with the game, for the same reason as update_transition().
func update_sleep() -> void:

	counter += 1
	# The clock keeps running while you sleep, but the screen fade is scripted,
	# so drive filter_alpha directly here rather than from the hour.

	if counter < 120:
		gp.e_manager.lighting.filter_alpha += 0.01
		if gp.e_manager.lighting.filter_alpha > 1.0:
			gp.e_manager.lighting.filter_alpha = 1.0

	if counter >= 120:
		gp.e_manager.lighting.filter_alpha -= 0.1
		if gp.e_manager.lighting.filter_alpha <= 0.0:
			gp.e_manager.lighting.filter_alpha = 0.0
			counter = 0
			# Wake up at sunrise, one day later.
			gp.e_manager.clock.set_time(int(gp.sunrise_end_hour), 0, true)
			gp.e_manager.lighting.refresh()
			gp.game_state = gp.PLAY_STATE
			gp.player.get_image()


func draw_sleep_screen() -> void:
	pass  # the screen darkening is the lighting filter, driven by update_sleep()


func get_item_index_on_slot(slot_col: int, slot_row: int) -> int:
	return slot_col + (slot_row * 5)


func draw_sub_window(x: int, y: int, width: int, height: int) -> void:

	g2.set_color(Color(kamiblack, 210.0 / 255.0))
	g2.fill_round_rect(x, y, width, height, 35, 35)

	g2.set_color(kamigreen)
	g2.set_stroke(5)
	g2.draw_round_rect(x + 5, y + 5, width - 10, height - 10, 25, 25)

	g2.set_color(kamipink)


func get_x_for_centered_text(text: String) -> int:
	var length: int = g2.get_string_width(text)
	@warning_ignore("integer_division")
	return gp.screen_width / 2 - length / 2


## Java divided the text width by 2 here, so "right aligned" numbers actually
## overhung their box. Aligning to the real width is what was meant.
func get_x_for_align_to_right_text(text: String, tail_x: int) -> int:
	var length: int = g2.get_string_width(text)
	return tail_x - length
