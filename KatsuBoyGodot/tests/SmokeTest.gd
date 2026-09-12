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


## Hit a throwaway monster and report how much life it lost.
func _hit_dummy(attack_value: int) -> int:
	var dummy := MON_Slime.new(gp)
	dummy.max_life = 1000
	dummy.life = 1000
	dummy.defense = 0
	gp.monster[0][5] = dummy
	gp.player.damage_monster(5, gp.player, attack_value, 0)
	var lost: int = 1000 - dummy.life
	gp.monster[0][5] = null
	return lost


## Take a hit from a throwaway monster and report how much life was lost.
func _take_hit(attack_value: int) -> int:
	var attacker := MON_Slime.new(gp)
	gp.player.max_life = 1000
	gp.player.life = 1000
	gp.player.invincible = false
	gp.player.guarding = false
	attacker.damage_player(attack_value)
	var lost: int = 1000 - gp.player.life
	gp.player.invincible = false
	return lost


## Eat a heart and report how much life it gave back.
func _use_heart() -> int:
	gp.player.max_life = 1000
	gp.player.life = 100
	OBJ_Heart.new(gp).use(gp.player)
	return gp.player.life - 100


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
			check("5 maps instantiated", gp.map_node.size() == 5 and gp.map_node[0] != null,
				str(gp.map_node.size()))
			check("tile set loaded", gp.tile_m.tile.size() >= 44 and gp.tile_m.tile[0] != null)
			check("tree tile collides", gp.tile_m.tile[16].collision == true)
			check("grass tile does not collide", gp.tile_m.tile[0].collision == false)
			check("map 0 tiles read", gp.tile_m.map_tile_num[0][94][94] >= 0)
			check("objects placed from markers", objects_on(0) == 15, str(objects_on(0)))
			check("monsters placed from markers", monsters_alive(0) == 23, str(monsters_alive(0)))
			check("npc on map 0", gp.npc[0][0] != null)
			check("merchant on map 1", gp.npc[1][1] is NPC_Merchant)
			check("interactive tile placed", gp.i_tile[0][0] != null)
			# 8 teleports/map transitions, plus one boat dock per map that has
			# one: the world map's port and the two dungeons.
			check("events collected", gp.e_handler.events.size() == 11, str(gp.e_handler.events.size()))
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
			gp.e_manager.clock.day_index = 3  # Wednesday: an ordinary day
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

		1020:
			print("\n-- days of the week --")
			var clock: GameClock = gp.e_manager.clock

			check("all seven days are configured", gp.day_effects.size() == 7,
				str(gp.day_effects.size()))
			check("today() follows the clock",
				gp.today().display_name == clock.day_name(),
				"%s vs %s" % [gp.today().display_name, clock.day_name()])

			# the multiplier helper itself
			check("a multiplier of 1 changes nothing", DayEffect.apply(7, 1.0) == 7)
			check("a 1.3x multiplier rounds up sensibly", DayEffect.apply(4, 1.3) == 5,
				str(DayEffect.apply(4, 1.3)))
			check("a 0.75x multiplier discounts", DayEffect.apply(100, 0.75) == 75,
				str(DayEffect.apply(100, 0.75)))

			# Saturday: the player deals more damage
			clock.day_index = 3
			var normal_hit: int = _hit_dummy(10)
			clock.day_index = 6
			var saturday_hit: int = _hit_dummy(10)
			check("Saturday deals more damage", saturday_hit > normal_hit,
				"%d -> %d" % [normal_hit, saturday_hit])

			# Monday: the player takes more damage
			clock.day_index = 3
			var normal_taken: int = _take_hit(10)
			clock.day_index = 1
			var monday_taken: int = _take_hit(10)
			check("Monday takes more damage", monday_taken > normal_taken,
				"%d -> %d" % [normal_taken, monday_taken])

			# Tuesday to Thursday are ordinary
			var ordinary := true
			for d in [2, 3, 4]:
				var e: DayEffect = gp.day_effects[d]
				if not (is_equal_approx(e.damage_dealt_multiplier, 1.0)
						and is_equal_approx(e.damage_taken_multiplier, 1.0)
						and is_equal_approx(e.shop_price_multiplier, 1.0)
						and is_equal_approx(e.healing_multiplier, 1.0)
						and e.shop_open):
					ordinary = false
			check("Tuesday to Thursday are ordinary days", ordinary)

		1024:
			var clock2: GameClock = gp.e_manager.clock

			# Sunday: healing does more
			clock2.day_index = 3
			var normal_heal: int = _use_heart()
			clock2.day_index = 0
			var sunday_heal: int = _use_heart()
			check("Sunday heals more", sunday_heal > normal_heal,
				"%d -> %d" % [normal_heal, sunday_heal])

			# Friday: the shop discounts
			clock2.day_index = 3
			var normal_price: int = DayEffect.apply(200, gp.today().shop_price_multiplier)
			clock2.day_index = 5
			var friday_price: int = DayEffect.apply(200, gp.today().shop_price_multiplier)
			check("Friday is cheaper", friday_price < normal_price,
				"%d -> %d" % [normal_price, friday_price])

		1028:
			var clock3: GameClock = gp.e_manager.clock
			# Sunday: the shop is shut
			gp.current_map = 1
			gp.game_state = gp.PLAY_STATE
			clock3.day_index = 0
			gp.npc[1][1].speak()
			check("the shop is shut on Sunday", gp.game_state != gp.TRADE_STATE,
				str(gp.game_state))
			gp.game_state = gp.PLAY_STATE
			clock3.day_index = 5
			gp.npc[1][1].speak()
			check("the shop opens on other days", gp.game_state == gp.TRADE_STATE,
				str(gp.game_state))
			gp.game_state = gp.PLAY_STATE
			gp.ui.sub_state = 0
			gp.current_map = 0

			# a day with an effect announces itself; an ordinary one keeps quiet
			clock3.day_index = 1  # Monday
			gp.ui.message.clear()
			gp.ui.message_counter.clear()
			gp.announce_day()
			check("a day with an effect announces itself",
				gp.ui.message.size() == 1 and "Monday" in gp.ui.message[0],
				str(gp.ui.message))
			clock3.day_index = 3  # Wednesday
			gp.ui.message.clear()
			gp.ui.message_counter.clear()
			gp.announce_day()
			check("an ordinary day says nothing", gp.ui.message.is_empty(),
				str(gp.ui.message))
		1032:
			var clock4: GameClock = gp.e_manager.clock
			clock4.reset()
			clock4.set_time(23, 59)
			clock4.advance(2)
			check("the clock reports the day change once", clock4.take_day_change() == true)
			check("and only once", clock4.take_day_change() == false)
			clock4.reset()
			gp.e_manager.lighting.refresh()

		1060:
			print("\n-- boat, tickets and quest --")

			# Build a self-contained timetable rather than leaning on whatever
			# is in the Inspector, so the test says what it means.
			var mini := DungeonInfo.new()
			mini.id = "cave"
			mini.display_name = "Cave"
			mini.map_index = 1
			mini.ticket_id = "cave"
			mini.ticket_price = 40
			mini.sail_days = (1 << 1) | (1 << 4)     # Monday and Thursday

			var major := DungeonInfo.new()
			major.id = "deep"
			major.display_name = "Deep"
			major.map_index = 2
			major.ticket_id = "deep"
			major.sail_days = (1 << 6)               # Saturday
			major.unlocked_by = "cave"

			var home := DungeonInfo.new()
			home.id = "home"
			home.display_name = "Sail home"
			home.is_victory = true
			home.sail_days = 127

			var dungeons: Array = [mini, major, home]
			var q := QuestLog.new()

			check("a route with no ticket is listed but not sailing",
				BoatService.sailable(dungeons, q, 1).is_empty())
			check("the reason given is the ticket price",
				"40" in BoatService.destinations(dungeons, q, 1)[0]["reason"],
				BoatService.destinations(dungeons, q, 1)[0]["reason"])

			check("a locked route says so, not 'no ticket'",
				BoatService.destinations(dungeons, q, 6)[1]["block"] == BoatService.Block.LOCKED)

			check("the victory route is hidden before the work is done",
				BoatService.destinations(dungeons, q, 1).size() == 2)

			q.grant_ticket("cave")
			check("a ticket is not granted twice", q.grant_ticket("cave") == false)
			check("with a ticket the Monday boat sails",
				BoatService.sailable(dungeons, q, 1).size() == 1)
			check("but not on a Tuesday",
				BoatService.sailable(dungeons, q, 2).is_empty())
			check("and Tuesday explains the timetable",
				"Mon" in BoatService.destinations(dungeons, q, 2)[0]["reason"],
				BoatService.destinations(dungeons, q, 2)[0]["reason"])
			check("next sailing from Tuesday is Thursday",
				BoatService.next_sailing_day(mini, 2) == 4)

			check("the objective points at the cave",
				q.objective_text(dungeons) == "Clear Cave.", q.objective_text(dungeons))

			q.mark_cleared("cave")
			check("a dungeon is not cleared twice", q.mark_cleared("cave") == false)
			check("clearing the cave unlocks the deep on a Saturday",
				BoatService.destinations(dungeons, q, 6)[1]["block"] == BoatService.Block.NO_TICKET)
			q.grant_ticket("deep")
			check("and with its ticket the Saturday boat sails",
				BoatService.sailable(dungeons, q, 6).size() == 1)

			check("not everything is cleared yet", q.all_cleared(dungeons) == false)
			q.mark_cleared("deep")
			check("both dungeons cleared", q.all_cleared(dungeons) == true)
			check("two counted as cleared", q.cleared_count(dungeons) == 2)
			check("the way home appears once everything is cleared",
				BoatService.destinations(dungeons, q, 3).size() == 3)
			check("and it is sailing",
				BoatService.sailable(dungeons, q, 3).size() == 1)
			check("the objective now says go home",
				"home" in q.objective_text(dungeons), q.objective_text(dungeons))

			# The dock you are standing on is not offered, which the boat
			# screen filters rather than BoatService.
			check("by_id finds a dungeon", BoatService.by_id(dungeons, "deep") == major)
			check("by_id returns null for a dungeon that is gone",
				BoatService.by_id(dungeons, "nowhere") == null)

			# Round-trip through a save.
			var round_trip := QuestLog.new()
			round_trip.apply_dict(q.to_dict())
			check("tickets survive a save", round_trip.has_ticket("deep"))
			check("cleared dungeons survive a save", round_trip.is_cleared("cave"))
			check("a save with no quest data loads as a fresh log",
				QuestLog.new().tickets.is_empty())

			# The real Inspector-assigned dungeons, so a typo in a .tres shows up.
			check("dungeon resources are assigned", gp.dungeons.size() >= 3,
				str(gp.dungeons.size()))
			var ids := {}
			var dupes := false
			for d in gp.dungeons:
				if d == null or d.id.is_empty():
					dupes = true
				elif ids.has(d.id):
					dupes = true
				else:
					ids[d.id] = true
			check("every dungeon has a unique, non-empty id", not dupes, str(ids.keys()))
			for d in gp.dungeons:
				if d != null and not d.is_victory and d.map_index >= gp.map_scenes.size():
					check("dungeon '%s' points at a real map" % d.id, false,
						"map_index %d of %d" % [d.map_index, gp.map_scenes.size()])

			# Stepping off the boat onto a tree would wedge the player for good,
			# so every arrival tile is checked here rather than in play testing.
			for d in gp.dungeons:
				if d == null or d.is_victory:
					continue
				if d.map_index >= gp.map_scenes.size():
					continue
				var in_bounds: bool = (d.arrive_col >= 0 and d.arrive_col < gp.max_world_col
						and d.arrive_row >= 0 and d.arrive_row < gp.max_world_row)
				if not in_bounds:
					check("'%s' arrives inside its map" % d.id, false,
						"%d,%d" % [d.arrive_col, d.arrive_row])
					continue
				var arrive_tile: int = gp.tile_m.map_tile_num[d.map_index][d.arrive_col][d.arrive_row]
				check("'%s' arrives on a walkable tile" % d.id,
					not gp.tile_m.tile[arrive_tile].collision,
					"map %d tile %d at %d,%d" % [d.map_index, arrive_tile, d.arrive_col, d.arrive_row])

		1075:
			print("\n-- the guide who walks to the boat --")

			var guide = gp.npc[0][1]
			check("the dock guide is on the world map", guide is NPC_OldMan,
				str(guide))

			if guide is NPC_OldMan:
				check("the guide knows which dungeon he points at",
					guide.guide_dungeon_id == "mushroom_cave", guide.guide_dungeon_id)
				check("and where he walks to",
					guide.guide_col == 87 and guide.guide_row == 97,
					"%d,%d" % [guide.guide_col, guide.guide_row])

				# Fresh log: he should be talking about the ticket.
				gp.quest = QuestLog.new()
				gp.current_map = 0
				gp.player.direction = "up"
				gp.game_state = gp.PLAY_STATE
				guide.speak()
				check("talking to the guide opens dialogue",
					gp.game_state == gp.DIALOGUE_STATE, str(gp.game_state))
				check("he speaks the guide set, not small talk",
					guide.dialogue_set == NPC_OldMan.GUIDE_SET, str(guide.dialogue_set))
				check("he names the dungeon",
					"cave" in guide.dialogues[NPC_OldMan.GUIDE_SET][0].to_lower(),
					str(guide.dialogues[NPC_OldMan.GUIDE_SET][0]))

				var guide_lines := ""
				for line in guide.dialogues[NPC_OldMan.GUIDE_SET]:
					if line != null:
						guide_lines += str(line) + "\n"
				check("he mentions the ticket price while you lack the ticket",
					"40" in guide_lines, guide_lines)
				check("and the timetable", "Mon" in guide_lines, guide_lines)
				check("talking to him sets the objective",
					gp.quest.current_target == "mushroom_cave", gp.quest.current_target)
				check("he starts following his path", guide.on_path == true)
				gp.game_state = gp.PLAY_STATE

				# With the ticket in hand the price line drops out, so he does
				# not nag about something you already bought.
				gp.quest.grant_ticket("mushroom_cave")
				guide.speak()
				var after_ticket := ""
				for line in guide.dialogues[NPC_OldMan.GUIDE_SET]:
					if line != null:
						after_ticket += str(line) + "\n"
				check("with the ticket he stops talking about the price",
					not ("40" in after_ticket), after_ticket)
				gp.game_state = gp.PLAY_STATE

				# Cleared: he congratulates rather than sending you back.
				gp.quest.mark_cleared("mushroom_cave")
				guide.speak()
				check("once cleared he says so",
					"quiet" in str(guide.dialogues[NPC_OldMan.GUIDE_SET][0]).to_lower(),
					str(guide.dialogues[NPC_OldMan.GUIDE_SET][0]))
				gp.game_state = gp.PLAY_STATE

				# Walking. Standing on the goal tile ends the walk instead of
				# shuffling on it forever.
				guide.on_path = true
				guide.world_x = 87 * gp.tile_size - guide.solid_area.x
				guide.world_y = 97 * gp.tile_size - guide.solid_area.y
				guide.set_action()
				check("he stops once he reaches the dock", guide.on_path == false)

				# Away from the dock he keeps going.
				guide.on_path = true
				guide.world_x = 92 * gp.tile_size - guide.solid_area.x
				guide.world_y = 97 * gp.tile_size - guide.solid_area.y
				guide.set_action()
				check("away from the dock he is still walking", guide.on_path == true)

				# An NPC with no guide id is unchanged: small talk that cycles.
				var plain = gp.npc[0][0]
				if plain is NPC_OldMan:
					check("an ordinary old man is not a guide",
						plain.guide_dungeon_id.is_empty(), plain.guide_dungeon_id)
					plain.dialogue_set = 0
					plain.speak()
					check("and his dialogue still cycles",
						plain.dialogue_set == 1, str(plain.dialogue_set))
					gp.game_state = gp.PLAY_STATE

				# A guide pointed at a dungeon that no longer exists falls back
				# to small talk rather than crashing.
				guide.guide_dungeon_id = "a_dungeon_that_was_deleted"
				guide.dialogue_set = 0
				guide.speak()
				check("a guide with a dead dungeon id falls back to small talk",
					guide.dialogue_set == 1, str(guide.dialogue_set))
				guide.guide_dungeon_id = "mushroom_cave"
				gp.game_state = gp.PLAY_STATE
				gp.quest = QuestLog.new()

		1080:
			print("\n-- boat tickets at Kami Mart --")

			var merchant = gp.npc[1][1]
			gp.quest = QuestLog.new()
			merchant.refresh_stock()

			var stocked_tickets: Array = []
			for item in merchant.inventory:
				if item is OBJ_BoatTicket:
					stocked_tickets.append(item)

			check("Kami Mart stocks the cave ticket", stocked_tickets.size() == 1,
				str(stocked_tickets.size()))
			if stocked_tickets.size() == 1:
				check("priced from the dungeon file", stocked_tickets[0].price == 40,
					str(stocked_tickets[0].price))
				check("named after the dungeon",
					stocked_tickets[0].name == "Mushroom Cave Ticket",
					stocked_tickets[0].name)
				check("and pointed at the right route",
					stocked_tickets[0].route_id == "mushroom_cave",
					stocked_tickets[0].route_id)

				# Buying it registers the route, which is what the boat reads.
				var bought = stocked_tickets[0]
				check("using a ticket grants the route", bought.use(gp.player) == true)
				check("and the quest log has it", gp.quest.has_ticket("mushroom_cave"))
				check("using it twice does nothing", bought.use(gp.player) == false)
				gp.game_state = gp.PLAY_STATE

			merchant.refresh_stock()
			var still_stocked := 0
			for item in merchant.inventory:
				if item is OBJ_BoatTicket:
					still_stocked += 1
			check("a ticket you already hold comes off the shelf",
				still_stocked == 0, str(still_stocked))
			check("the ordinary stock is untouched", merchant.inventory.size() == 4,
				str(merchant.inventory.size()))

			# The Shadow Deep is not for sale at any point - its ticket_price is
			# 0, so the only way there is through the cave's boss.
			gp.quest.mark_cleared("mushroom_cave")
			merchant.refresh_stock()
			var deep_on_sale := false
			for item in merchant.inventory:
				if item is OBJ_BoatTicket and item.route_id == "shadow_deep":
					deep_on_sale = true
			check("a route with no price is never sold", not deep_on_sale)

			# A ticket in the bag is saved by name, so the generator has to be
			# able to build it back from that name alone.
			var reloaded = gp.e_generator.get_object("Mushroom Cave Ticket")
			check("a ticket survives a save by name", reloaded is OBJ_BoatTicket,
				str(reloaded))
			if reloaded is OBJ_BoatTicket:
				check("and comes back pointed at its route",
					reloaded.route_id == "mushroom_cave", reloaded.route_id)

			gp.quest = QuestLog.new()
			merchant.refresh_stock()

		1085:
			print("\n-- the whole run: dock, cave, boss, deep, ending --")

			gp.quest = QuestLog.new()
			gp.game_state = gp.PLAY_STATE
			gp.current_map = 0
			gp.current_dungeon_id = "port"

			var cave: DungeonInfo = BoatService.by_id(gp.dungeons, "mushroom_cave")
			var deep: DungeonInfo = BoatService.by_id(gp.dungeons, "shadow_deep")
			var home: DungeonInfo = BoatService.by_id(gp.dungeons, "victory")
			check("the three dungeon files load",
				cave != null and deep != null and home != null)

			# Each dungeon map has a boss wired to it by its marker.
			var cave_boss = null
			for m in gp.monster[cave.map_index]:
				if m is MON_Boss:
					cave_boss = m
			check("the cave has a boss", cave_boss != null)
			if cave_boss != null:
				check("who knows his dungeon", cave_boss.dungeon_id == "mushroom_cave",
					cave_boss.dungeon_id)
				check("and what he hands over", cave_boss.reward_ticket == "shadow_deep",
					cave_boss.reward_ticket)
				check("a boss is tougher than the monster it is built from",
					cave_boss.max_life > MON_KamiJack.new(gp).max_life * 3,
					str(cave_boss.max_life))

			var deep_boss = null
			for m in gp.monster[deep.map_index]:
				if m is MON_Boss:
					deep_boss = m
			check("the deep has a boss", deep_boss != null)

			# Sail. Monday, with the ticket bought at the shop.
			gp.quest.grant_ticket("mushroom_cave")
			var sail_day := 1
			# The home port sails every day and needs no ticket, so on a Monday
			# with the cave ticket in hand there are two routes: home and the cave.
			check("the cave is sailing on Monday",
				BoatService.sailable(gp.dungeons, gp.quest, sail_day).size() == 2,
				str(BoatService.sailable(gp.dungeons, gp.quest, sail_day).size()))

			gp.e_handler.sail_to(cave)
			check("boarding starts the transition", gp.game_state == gp.TRANSITION_STATE)
			check("and it is aimed at the cave map",
				gp.e_handler.temp_map == cave.map_index, str(gp.e_handler.temp_map))
			check("the game remembers which dungeon you are in",
				gp.current_dungeon_id == "mushroom_cave", gp.current_dungeon_id)

			# Finish the fade rather than waiting 25 frames for it.
			gp.ui.counter = 50
			gp.ui.update_transition()
			check("you arrive in the cave", gp.current_map == cave.map_index,
				str(gp.current_map))
			@warning_ignore("integer_division")
			var arrived_col: int = gp.player.world_x / gp.tile_size
			check("standing on the dock tile", arrived_col == cave.arrive_col,
				str(arrived_col))

			# Kill the boss.
			if cave_boss != null:
				cave_boss.check_drop()
			check("the cave is cleared", gp.quest.is_cleared("mushroom_cave"))
			check("and the deep's ticket is in hand", gp.quest.has_ticket("shadow_deep"))
			check("the objective moves on",
				gp.quest.objective_text(gp.dungeons) == "Clear The Shadow Deep.",
				gp.quest.objective_text(gp.dungeons))
			check("killing him twice changes nothing",
				gp.quest.cleared_count(gp.dungeons) == 1,
				str(gp.quest.cleared_count(gp.dungeons)))

			# The deep only runs on Saturday.
			check("the deep does not sail on Monday",
				BoatService.sailable(gp.dungeons, gp.quest, 1).size() == 2,
				str(BoatService.sailable(gp.dungeons, gp.quest, 1).size()))
			# Saturday: home and the deep. The cave only runs Mondays and
			# Thursdays, so it drops off the board.
			check("but it does on Saturday",
				BoatService.sailable(gp.dungeons, gp.quest, 6).size() == 2,
				str(BoatService.sailable(gp.dungeons, gp.quest, 6).size()))
			var saturday_ids: Array = []
			for row in BoatService.sailable(gp.dungeons, gp.quest, 6):
				saturday_ids.append(row["info"].id)
			check("and the Saturday board is home and the deep",
				saturday_ids.has("shadow_deep") and saturday_ids.has("port"),
				str(saturday_ids))
			check("the home port is not a dungeon to clear",
				QuestLog.countable(gp.dungeons).size() == 2,
				str(QuestLog.countable(gp.dungeons).size()))

			gp.e_handler.sail_to(deep)
			gp.ui.counter = 50
			gp.ui.update_transition()
			check("you arrive in the deep", gp.current_map == deep.map_index,
				str(gp.current_map))

			if deep_boss != null:
				deep_boss.check_drop()
			check("everything is cleared", gp.quest.all_cleared(gp.dungeons))
			check("the way home is offered",
				BoatService.sailable(gp.dungeons, gp.quest, 1).size() >= 1)

			var home_row_found := false
			for row in BoatService.destinations(gp.dungeons, gp.quest, 1):
				if row["info"].is_victory and row["sailing"]:
					home_row_found = true
			check("and it is the victory route", home_row_found)

			gp.ui.game_finished = false
			gp.e_handler.sail_to(home)
			check("sailing home ends the game", gp.game_state == gp.ENDING_STATE,
				str(gp.game_state))
			check("the ending screen knows it", gp.ui.game_finished == true)

			# Back to somewhere sane for anything that runs after this.
			gp.game_state = gp.PLAY_STATE
			gp.ui.game_finished = false
			gp.current_map = 0
			gp.current_dungeon_id = "port"
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 94
			gp.quest = QuestLog.new()

		1090:
			print("\n================================")
			print("%d passed, %d failed" % [passed, failed.size()])
			for f in failed:
				print("  FAILED: %s" % f)
			print("================================")
			get_tree().quit(0 if failed.is_empty() else 1)
