extends Node
## Regression test. Drives a real GamePanel through every screen and every
## major gameplay path, and checks the results.
##
## Run it:
##   godot --headless --path . res://tests/SmokeTest.tscn
##
## Exits with code 1 if anything fails, so it works in CI. Run this after any
## change to the game code - it catches the crashes and silent breakages that
## are otherwise only found by playing for ten minutes.

var gp
var frame := 0
var passed := 0
var failed: Array[String] = []


func _ready() -> void:
	gp = get_parent()
	# Monsters wander using randi(), which Godot seeds differently every run.
	# Pin it so a failure is always reproducible.
	seed(20240612)


func check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed += 1
		print("  ok    %s" % label)
	else:
		failed.append(label)
		print("  FAIL  %s %s" % [label, detail])


func monsters_alive(map := 0) -> int:
	var n := 0
	for m in gp.monster[map]:
		if m != null:
			n += 1
	return n


func objects_on(map := 0) -> int:
	var n := 0
	for o in gp.obj[map]:
		if o != null:
			n += 1
	return n


func press(action: StringName) -> void:
	gp.key_h.action_pressed(action)


func release(action: StringName) -> void:
	gp.key_h.action_released(action)


## Driven from _physics_process, not _process, so one "frame" here is exactly
## one game update - the same 60 Hz tick GamePanel.update() runs on.
func _physics_process(_d: float) -> void:
	frame += 1

	# keep swinging during the two combat phases (the axe swing is a 50 frame
	# cycle, so a few hundred frames are needed to land three hits)
	if (frame >= 72 and frame < 280) or (frame >= 560 and frame < 760):
		if frame % 6 == 0: press(Action.CONFIRM)
		if frame % 6 == 3: release(Action.CONFIRM)

	match frame:
		2:
			print("\n-- boot --")
			check("3 maps instantiated", gp.map_node.size() == 3 and gp.map_node[0] != null)
			check("tile set loaded", gp.tile_m.tile.size() >= 44 and gp.tile_m.tile[0] != null)
			check("tree tile collides", gp.tile_m.tile[16].collision == true)
			check("grass tile does not collide", gp.tile_m.tile[0].collision == false)
			check("map 0 tiles read", gp.tile_m.map_tile_num[0][94][94] >= 0)
			check("objects placed from markers", objects_on(0) == 15, str(objects_on(0)))
			check("monsters placed from markers", monsters_alive(0) == 23, str(monsters_alive(0)))
			check("npc on map 0", gp.npc[0][0] != null)
			check("merchant on map 1", gp.npc[1][1] is NPC_Merchant)
			check("interactive tile placed", gp.i_tile[0][0] != null)
			check("events collected", gp.e_handler.events.size() == 8, str(gp.e_handler.events.size()))
			var missing_actions: Array[String] = []
			for a in Action.ALL:
				if not InputMap.has_action(a):
					missing_actions.append(a)
			check("all input actions exist in Project Settings",
				missing_actions.is_empty(), str(missing_actions))
			check("player start read from its marker",
				gp.player.world_x == gp.tile_size * 94 and gp.player.world_y == gp.tile_size * 94,
				"%d,%d" % [gp.player.world_x, gp.player.world_y])

		4:
			print("\n-- title screen --")
			check("starts on title", gp.game_state == gp.TITLE_STATE)
			press(Action.CONFIRM); release(Action.CONFIRM)
		8:
			check("new game -> class select", gp.ui.title_screen_state == 1)
			press(Action.CONFIRM); release(Action.CONFIRM)
		12:
			check("class picked -> play state", gp.game_state == gp.PLAY_STATE)
			check("samurai got the bokken", gp.player.search_item_in_inventory("Kami no Bokken") != 999)

		16:
			print("\n-- pickups --")
			gp.player.world_x = gp.tile_size * 52
			gp.player.world_y = gp.tile_size * 97
			gp.player.direction = "down"
			press(Action.MOVE_DOWN)
		26:
			# the Carbuncle crashed the Java build on pickup
			check("carbuncle picked up", objects_on(0) == 14, str(objects_on(0)))
			release(Action.MOVE_DOWN)
			gp.player.world_x = gp.tile_size * 50
			gp.player.world_y = gp.tile_size * 96
			press(Action.MOVE_DOWN)
		36:
			check("coin picked up (coin +1)", gp.player.coin == 1000, str(gp.player.coin))
			release(Action.MOVE_DOWN)

		40:
			print("\n-- chest and door --")
			gp.player.world_x = gp.tile_size * 91
			gp.player.world_y = gp.tile_size * 91
			gp.player.direction = "down"
			press(Action.MOVE_DOWN)
		50:
			press(Action.CONFIRM)
		52:
			release(Action.CONFIRM); release(Action.MOVE_DOWN)
		56:
			check("chest opened", gp.obj[0][11].opened == true)
			check("key in inventory", gp.player.search_item_in_inventory("Key") != 999)
			gp.game_state = gp.PLAY_STATE
		60:
			gp.player.world_x = gp.tile_size * 85
			gp.player.world_y = gp.tile_size * 96
			gp.player.direction = "down"
			var ki: int = gp.player.search_item_in_inventory("Key")
			gp.player.inventory[ki].use(gp.player)
		64:
			var door_gone := true
			for o in gp.obj[0]:
				if o != null and o.name == "Door":
					door_gone = false
			check("door unlocked by key", door_gone)
			gp.game_state = gp.PLAY_STATE

		70:
			print("\n-- interactive tile --")
			gp.player.inventory.append(OBJ_Kamiaxe.new(gp))
			gp.player.current_weapon = gp.player.inventory[gp.player.inventory.size() - 1]
			gp.player.get_attack()
			gp.player.get_attack_image()
			gp.player.world_x = gp.tile_size * 86
			gp.player.world_y = gp.tile_size * 96
			gp.player.direction = "down"
			check("dry tree present", gp.i_tile[0][0] is IT_DryTree)
		71:
			press(Action.MOVE_DOWN)
		285:
			release(Action.MOVE_DOWN); release(Action.CONFIRM)
			check("dry tree became a trunk", gp.i_tile[0][0] is IT_Trunk)

		290:
			print("\n-- ui screens --")
			gp.game_state = gp.CHARACTER_STATE
		294:
			check("character screen drew", gp.ui.g2 != null)
			gp.game_state = gp.MAP_STATE
		298:
			check("map screen ok", gp.map.world_map.size() == gp.max_map and gp.map.world_map[0] != null)
			gp.game_state = gp.PAUSE_STATE
		302:
			gp.game_state = gp.OPTION_STATE
			gp.ui.sub_state = 0
		306:
			gp.ui.sub_state = 2
		310:
			gp.ui.sub_state = 3
		314:
			gp.ui.sub_state = 0
			gp.game_state = gp.PLAY_STATE
			gp.map.mini_map_on = true

		320:
			print("\n-- dialogue --")
			gp.player.world_x = gp.tile_size * 96
			gp.player.world_y = gp.tile_size * 96
			gp.player.direction = "up"
			gp.npc[0][0].speak()
		326:
			check("dialogue opened", gp.game_state == gp.DIALOGUE_STATE)
			check("dialogue has text", gp.ui.current_dialogue.length() > 0)
			gp.game_state = gp.PLAY_STATE

		328:
			# Clear the wandering monsters first: one of the Slimes spawns on
			# the same tile as the doorway and can stand in it, which has
			# nothing to do with what this phase is testing.
			for i in range(gp.monster[0].size()):
				gp.monster[0][i] = null
		330:
			print("\n-- map transitions (event markers) --")
			gp.player.world_x = gp.tile_size * 8
			gp.player.world_y = gp.tile_size * 45
			gp.player.direction = "down"
			press(Action.MOVE_DOWN)
		360:
			release(Action.MOVE_DOWN)
			check("walking onto a ChangeMap marker started a transition",
				gp.game_state == gp.TRANSITION_STATE or gp.current_map == 1)
		400:
			check("arrived on map 1", gp.current_map == 1, str(gp.current_map))
			check("player moved to the marker's target tile",
				gp.player.world_x == gp.tile_size * 26 and gp.player.world_y == gp.tile_size * 32)
		404:
			gp.e_handler.change_map(2, 82, 67)
		450:
			check("arrived on map 2", gp.current_map == 2, str(gp.current_map))
			gp.e_handler.change_map(0, 10, 9)
		500:
			check("back on map 0", gp.current_map == 0, str(gp.current_map))

		556:
			print("\n-- combat --")
			gp.player.max_life = 500
			gp.player.life = 500
			gp.player.strength = 50
			gp.player.get_attack()
			gp.player.world_x = gp.tile_size * 60
			gp.player.world_y = gp.tile_size * 60
			gp.player.direction = "down"
			# parked just inside the axe's reach, and frozen so it cannot wander
			# a fresh slime, parked just inside the axe's reach and frozen
			gp.monster[0][1] = MON_Slime.new(gp)
			gp.monster[0][1].world_x = gp.tile_size * 60
			gp.monster[0][1].world_y = gp.tile_size * 60 + 24
			gp.monster[0][1].speed = 0
			gp.monster[0][1].on_path = false
		558:
			press(Action.MOVE_DOWN)
		762:
			release(Action.MOVE_DOWN); release(Action.CONFIRM)
			check("monster killed", gp.monster[0][1] == null)
			check("exp gained", gp.player.exp > 0, str(gp.player.exp))
		766:
			gp.player.mana = 99
			gp.player.max_mana = 99
			gp.player.direction = "right"
			press(Action.SHOOT)
		770:
			release(Action.SHOOT)
			check("shuriken cost mana", gp.player.mana == 98, str(gp.player.mana))
		774:
			for m in gp.monster[0]:
				if m != null:
					m.on_path = true
		810:
			check("pathfinder produced a path", gp.p_finder.path_list.size() >= 0)
			for m in gp.monster[0]:
				if m != null:
					m.on_path = false

		820:
			print("\n-- world edges (crashed the Java build) --")
			gp.player.world_x = 0
			gp.player.world_y = 0
			press(Action.MOVE_UP); press(Action.MOVE_LEFT)
		840:
			release(Action.MOVE_UP); release(Action.MOVE_LEFT)
			gp.player.world_x = gp.tile_size * (gp.max_world_col - 1)
			gp.player.world_y = gp.tile_size * (gp.max_world_row - 1)
			press(Action.MOVE_DOWN); press(Action.MOVE_RIGHT)
		860:
			release(Action.MOVE_DOWN); release(Action.MOVE_RIGHT)
			check("survived the world edges", gp.game_state == gp.PLAY_STATE)

		870:
			print("\n-- trading --")
			gp.current_map = 1
			gp.player.coin = 500
			gp.npc[1][1].speak()
		874:
			check("trade opened", gp.game_state == gp.TRADE_STATE)
			gp.ui.sub_state = 1
			gp.ui.npc_slot_col = 0
			gp.ui.npc_slot_row = 0
		878:
			gp.key_h.enter_pressed = true
		882:
			check("bought an item (coins spent)", gp.player.coin < 500, str(gp.player.coin))
			gp.game_state = gp.TRADE_STATE
			gp.ui.sub_state = 2
			gp.ui.player_slot_col = 4
			gp.ui.player_slot_row = 0
		886:
			gp.key_h.enter_pressed = true
		890:
			check("sell screen ran", gp.game_state != gp.TRADE_STATE or gp.ui.sub_state == 0)
			gp.game_state = gp.PLAY_STATE
			gp.current_map = 0

		900:
			print("\n-- save and load --")
			gp.player.coin = 4242
			gp.player.level = 9
			gp.save_load.save()
			gp.player.coin = 0
			gp.player.level = 1
		906:
			gp.save_load.load_game()
			check("coin restored", gp.player.coin == 4242, str(gp.player.coin))
			check("level restored", gp.player.level == 9, str(gp.player.level))

		912:
			print("\n-- game over and restart --")
			gp.player.life = 0
		916:
			check("game over triggered", gp.game_state == gp.GAME_OVER_STATE)
			gp.ui.command_num = 1
			press(Action.CONFIRM); release(Action.CONFIRM)
		922:
			check("restart returned to title", gp.game_state == gp.TITLE_STATE)
			check("monsters respawned from markers", monsters_alive(0) == 23, str(monsters_alive(0)))
			# respawning happens mid-game, when the map scenes are scrolled away
			# from the origin - marker coords must not drift with the scroll
			check("respawned monster is on its marker tile",
				gp.monster[0][0].world_x == gp.tile_size * 82
				and gp.monster[0][0].world_y == gp.tile_size * 95,
				"%d,%d" % [gp.monster[0][0].world_x, gp.monster[0][0].world_y])
			check("objects reset from markers", objects_on(0) == 15, str(objects_on(0)))

		930:
			print("\n-- boots and running --")
			gp.game_state = gp.PLAY_STATE
			gp.player.has_boots = false
			gp.player.speed = gp.player.default_speed
			# open ground, well away from the Boots pickup
			gp.player.world_x = gp.tile_size * 60
			gp.player.world_y = gp.tile_size * 60
			gp.player.direction = "down"
			check("starts without the boots", gp.player.has_boots == false)
			press(Action.MOVE_DOWN)
			press(Action.RUN)
		938:
			check("cannot run before the boots",
				gp.player.speed == Player.STATS.walk_speed, str(gp.player.speed))
			release(Action.RUN)
			release(Action.MOVE_DOWN)
		942:
			# now walk into the Boots pickup that sits on the map
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 92
			gp.player.direction = "left"
			press(Action.MOVE_LEFT)
		975:
			# walked into the Boots pickup placed on the map
			check("picked up the boots", gp.player.has_boots == true)
		978:
			press(Action.RUN)
		982:
			check("Run key sprints once you have the boots",
				gp.player.speed == Player.STATS.run_speed, str(gp.player.speed))
			release(Action.RUN)
		986:
			check("walking speed with boots",
				gp.player.speed == Player.STATS.boots_walk_speed, str(gp.player.speed))
			release(Action.MOVE_LEFT)

		1000:
			print("\n-- clock --")
			var clock: GameClock = gp.e_manager.clock
			var light = gp.e_manager.lighting

			clock.reset()
			check("starts on the configured day", clock.day_name() == "Sunday", clock.day_name())
			check("starts at the configured time", clock.time_string() == "8:00 AM", clock.time_string())
			check("starts in the morning", clock.period_name() == "Morning", clock.period_name())

			# 12-hour formatting round the awkward hours
			clock.set_time(0, 0)
			check("midnight reads 12:00 AM", clock.time_string() == "12:00 AM", clock.time_string())
			clock.set_time(12, 0)
			check("noon reads 12:00 PM", clock.time_string() == "12:00 PM", clock.time_string())
			clock.set_time(13, 5)
			check("afternoon reads 1:05 PM", clock.time_string() == "1:05 PM", clock.time_string())

			# the named parts of the day
			var periods := {5.5: "Sunrise", 10.0: "Morning", 14.0: "Afternoon",
					18.0: "Evening", 20.5: "Sunset", 23.0: "Night", 2.0: "Night"}
			var period_ok := true
			var period_detail := ""
			for h in periods:
				clock.set_time(int(h), int((h - floor(h)) * 60))
				if clock.period_name() != periods[h]:
					period_ok = false
					period_detail += " %s->%s(want %s)" % [clock.time_string(), clock.period_name(), periods[h]]
			check("every part of the day is named right", period_ok, period_detail)

			# darkness follows the same schedule the shader fades with
			clock.set_time(12, 0)
			check("noon is fully light", is_equal_approx(clock.darkness_amount(), 0.0))
			clock.set_time(23, 0)
			check("late evening is fully dark", is_equal_approx(clock.darkness_amount(), 1.0))
			clock.set_time(3, 0)
			check("small hours are fully dark", is_equal_approx(clock.darkness_amount(), 1.0))
			clock.set_time(20, 30)
			check("half way through sunset is half dark",
				absf(clock.darkness_amount() - 0.5) < 0.01, str(clock.darkness_amount()))
			clock.set_time(5, 30)
			check("half way through sunrise is half dark",
				absf(clock.darkness_amount() - 0.5) < 0.01, str(clock.darkness_amount()))

			# the rest of the game asks "is it night?" - that has to agree
			clock.set_time(12, 0); light.refresh()
			check("noon counts as day", light.day_state == light.DAY)
			clock.set_time(23, 0); light.refresh()
			check("night counts as night", light.day_state == light.NIGHT)
			clock.set_time(20, 30); light.refresh()
			check("sunset counts as dusk", light.day_state == light.DUSK)
			clock.set_time(5, 30); light.refresh()
			check("sunrise counts as dawn", light.day_state == light.DAWN)
		1004:
			var clock2: GameClock = gp.e_manager.clock
			clock2.reset()
			# a full day forward rolls the calendar exactly once
			clock2.advance(24 * 60)
			check("a day later is Monday", clock2.day_name() == "Monday", clock2.day_name())
			check("and the same time of day", clock2.time_string() == "8:00 AM", clock2.time_string())
			clock2.advance(24 * 60 * 6)
			check("a week later is back to Sunday", clock2.day_name() == "Sunday", clock2.day_name())

			# sleeping in a tent wakes you at sunrise the next morning
			clock2.set_time(22, 0)
			var before: String = clock2.day_name()
			clock2.set_time(int(gp.sunrise_end_hour), 0, true)
			check("a tent wakes you at sunrise", clock2.time_string() == "6:00 AM", clock2.time_string())
			check("a tent moves you to the next day", clock2.day_name() != before,
				"%s -> %s" % [before, clock2.day_name()])

			# ticking: one step per frames_per_time_step, minutes_per_time_step each
			clock2.reset()
			gp.e_manager.clock.step_counter = gp.frames_per_time_step - 1
		1005:
			var clock3: GameClock = gp.e_manager.clock
			check("the clock ticks forward in steps",
				clock3.minute() == gp.start_minute + gp.minutes_per_time_step,
				clock3.time_string())
			clock3.reset()
			gp.e_manager.lighting.refresh()

		1010:
			print("\n================================")
			print("%d passed, %d failed" % [passed, failed.size()])
			for f in failed:
				print("  FAILED: %s" % f)
			print("================================")
			get_tree().quit(0 if failed.is_empty() else 1)
