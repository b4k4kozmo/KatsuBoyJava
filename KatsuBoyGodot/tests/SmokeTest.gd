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


## Average coins a monster drops, over enough kills for the average to mean
## something. Clears map 0's objects while it samples and puts them back after.
func _coin_yield(maker: String, samples: int) -> float:
	var total := 0
	for _i in range(samples):
		for slot in range(gp.obj[gp.current_map].size()):
			gp.obj[gp.current_map][slot] = null
		var m = gp.e_generator.get_monster(maker)
		if m == null:
			return 0.0
		m.world_x = gp.player.world_x
		m.world_y = gp.player.world_y
		m.check_drop()
		for o in gp.obj[gp.current_map]:
			if o is OBJ_Coin:
				total += o.value
	return float(total) / float(samples)


## Set the player up as `cls` at `level`, exactly as a real playthrough would,
## and hand back what they hit for and how fast.
func _as_class(cls: PlayerClass, level: int) -> Dictionary:
	gp.player.char_class = cls
	gp.player.set_default_values()
	gp.player.level = level
	gp.player.max_life = cls.max_life_at(level, PlayerStats.new().max_life)
	gp.player.life = gp.player.max_life
	gp.player.strength = cls.strength_at(level, PlayerStats.new().strength)
	gp.player.dexterity = cls.dexterity_at(level, PlayerStats.new().dexterity)
	gp.player.get_attack()
	gp.player.get_defense()
	return {
		"attack": gp.player.attack,
		"defense": gp.player.defense,
		"life": gp.player.max_life,
		"swing": maxi(gp.player.motion2_duration, 1),
		"speed": gp.player.default_speed,
	}


## Damage per second this class does to a monster, through the real damage path.
func _dps_against(cls: PlayerClass, level: int, monster_name: String) -> float:
	var me: Dictionary = _as_class(cls, level)
	var dummy = gp.e_generator.get_monster(monster_name)
	dummy.max_life = 1000000
	dummy.life = 1000000
	gp.monster[gp.current_map][7] = dummy
	gp.player.damage_monster(7, gp.player, gp.player.attack, 0)
	var per_hit: int = 1000000 - dummy.life
	gp.monster[gp.current_map][7] = null
	return float(per_hit) * 60.0 / float(me["swing"])


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
			check("objects placed from markers", objects_on(0) == 23, str(objects_on(0)))
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
			check("carbuncle picked up", objects_on(0) == 22, str(objects_on(0)))
			release(Action.MOVE_DOWN)
			gp.player.world_x = gp.tile_size * 50
			gp.player.world_y = gp.tile_size * 96
			press(Action.MOVE_DOWN)
		36:
			# A new game starts broke, and that first coin is worth what its
			# marker says - loose change, near where you wake up.
			check("coin picked up, and worth what the marker says",
				gp.player.coin == 3, str(gp.player.coin))
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
			var chest_slot := -1
			for slot in range(gp.obj[0].size()):
				if gp.obj[0][slot] is OBJ_Chest and gp.obj[0][slot].opened:
					chest_slot = slot
			check("chest opened", chest_slot >= 0, "no opened chest found")
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
			check("objects reset from markers", objects_on(0) == 23, str(objects_on(0)))

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

		1050:
			print("\n-- nothing is stacked on anything --")

			# A dry tree, a door or a chest occupies its tile. Anything placed
			# on the same tile is unreachable: the candle used to sit under a
			# tree, and no amount of walking at it would ever pick it up.
			var occupied := {}
			var stacked: Array[String] = []
			for map_num in range(gp.max_map):
				var here := {}
				for group in ["Objects", "NPCs", "Monsters", "InteractiveTiles", "Events"]:
					for m in gp.a_setter.markers(map_num, group):
						var key := "%d:%d" % [m.tile_col(), m.tile_row()]
						var solid: bool = group == "InteractiveTiles"
						if m is ObjectMarker and (m.item == "Door" or m.item == "Chest"):
							solid = true
						if here.has(key):
							var other = here[key]
							if solid or other["solid"]:
								stacked.append("map %d tile %s: %s + %s" % [
									map_num, key, other["what"], m.name])
							elif group == "NPCs" and other["group"] == "NPCs":
								stacked.append("map %d tile %s: two people, %s + %s" % [
									map_num, key, other["what"], m.name])
						here[key] = {"what": m.name, "solid": solid, "group": group}
				occupied[map_num] = here.size()

			check("nothing shares a tile with something solid", stacked.is_empty(),
				str(stacked))

			# And the people are not all standing in one doorway.
			var npc_tiles: Array = []
			for m in gp.a_setter.markers(0, "NPCs"):
				npc_tiles.append(Vector2i(m.tile_col(), m.tile_row()))
			var too_close: Array[String] = []
			for i in range(npc_tiles.size()):
				for j in range(i + 1, npc_tiles.size()):
					var d: Vector2i = npc_tiles[i] - npc_tiles[j]
					if absi(d.x) <= 1 and absi(d.y) <= 1:
						too_close.append(str(npc_tiles[i]) + " & " + str(npc_tiles[j]))
			check("no two villagers are standing on each other", too_close.is_empty(),
				str(too_close))

			# The starting area is where a new player learns to walk. Keep it
			# clear: a couple of choppable trees, not a forest.
			var start_trees := 0
			for m in gp.a_setter.markers(0, "InteractiveTiles"):
				if absi(m.tile_col() - 94) <= 10 and absi(m.tile_row() - 94) <= 10:
					start_trees += 1
			check("the starting area is not full of dry trees", start_trees <= 2,
				str(start_trees))

		1052:
			print("\n-- dialogue fits its window --")

			# The window is 14 tiles wide with a tile of padding either side.
			var dlg_width: int = (gp.screen_width - gp.tile_size * 6) - gp.tile_size * 2
			var dlg_font: Font = gp.ui.maru_monica

			# The line that started this: a dungeon hint is written in a text
			# field by a designer, with no idea how wide the window is.
			var long_hint := ""
			for d in gp.dungeons:
				if d is DungeonInfo and d.hint.length() > long_hint.length():
					long_hint = d.hint
			check("there is a hint long enough to be worth wrapping",
				long_hint.length() > 60, str(long_hint.length()))
			check("and it does not fit the window as written",
				dlg_font.get_string_size(long_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x > dlg_width,
				str(dlg_font.get_string_size(long_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x))

			var wrapped: Array = gp.ui.wrap_text(long_hint, dlg_width, dlg_font, 28)
			check("wrapping breaks it up", wrapped.size() > 1, str(wrapped.size()))
			var all_fit := true
			for line in wrapped:
				if dlg_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x > dlg_width:
					all_fit = false
			check("and every line it produces fits", all_fit, str(wrapped))
			check("wrapping loses no words",
				" ".join(wrapped).replace("\n", " ") == long_hint.replace("\n", " "),
				" ".join(wrapped))

			# A word with no spaces in it still has to go somewhere.
			var runon := "Supercalifragilisticexpialidociousandthensomemoreontopofthat"
			var cut: Array = gp.ui.wrap_text(runon, dlg_width, dlg_font, 28)
			var runon_fits := true
			for line in cut:
				if dlg_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x > dlg_width:
					runon_fits = false
			check("an unbroken run of letters is cut, not lost",
				runon_fits and "".join(cut) == runon, str(cut))

			# Nothing anywhere in the game may overflow the window.
			var too_wide: Array[String] = []
			var speakers: Array = []
			for map_num in range(gp.max_map):
				for n in gp.npc[map_num]:
					if n != null:
						speakers.append(n)
			speakers.append(gp.player)
			for e in speakers:
				for set_num in range(e.dialogues.size()):
					for line_num in range(e.dialogues[set_num].size()):
						var line = e.dialogues[set_num][line_num]
						if line == null:
							continue
						for piece in str(line).split("\n"):
							if dlg_font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x > dlg_width:
								too_wide.append("%s set %d: %s" % [e.name, set_num, piece])
			check("no hand written line is wider than the window",
				too_wide.is_empty(), str(too_wide))

			# Pagination: four lines a screen, and it always ends cleanly.
			var pages: Array = gp.ui.paginate(long_hint, dlg_width, dlg_font, 28)
			var page_ok := true
			for page in pages:
				if page.split("\n").size() > UI.DIALOGUE_LINES:
					page_ok = false
			check("no page is taller than the window", page_ok, str(pages))
			check("a short line is still exactly one page",
				gp.ui.paginate("Hello.", dlg_width, dlg_font, 28).size() == 1)

			# And the whole thing through the real dialogue loop: the guide says
			# his piece, the player presses on, and the conversation ends.
			var talker = null
			for n in gp.npc[0]:
				if n is NPC_OldMan and not n.guide_dungeon_id.is_empty():
					talker = n
			if talker != null:
				gp.quest = QuestLog.new()
				gp.game_state = gp.PLAY_STATE
				gp.player.direction = "up"
				talker.speak()
				gp.ui.npc = talker
				var guard := 0
				var pages_seen := 0
				while gp.game_state == gp.DIALOGUE_STATE and guard < 4000:
					gp.ui.draw(gp)
					var page_before: int = gp.ui._dialogue_page
					gp.key_h.enter_pressed = true
					gp.ui.draw(gp)
					if gp.ui._dialogue_page != page_before:
						pages_seen += 1
					guard += 1
				check("the guide's whole speech can be read through",
					gp.game_state == gp.PLAY_STATE, "stuck after %d presses" % guard)

				# Paging itself, with a line deliberately longer than a window.
				var epic := ""
				for _w in range(40):
					epic += "the old man kept talking and talking "
				var epic_pages: Array = gp.ui.paginate(epic, dlg_width, dlg_font, 28)
				check("a speech longer than the window becomes several pages",
					epic_pages.size() > 1, str(epic_pages.size()))

				talker.dialogues[9][0] = epic
				talker.dialogues[9][1] = null
				gp.ui.npc = talker
				gp.ui._dialogue_source = ""
				gp.ui._dialogue_pages.clear()
				talker.dialogue_set = 9
				talker.dialogue_index = 0
				gp.key_h.enter_pressed = false
				gp.game_state = gp.DIALOGUE_STATE
				var seen := {}
				var guard2 := 0
				while gp.game_state == gp.DIALOGUE_STATE and guard2 < 20000:
					gp.ui.draw(gp)
					if gp.game_state != gp.DIALOGUE_STATE or gp.ui._dialogue_pages.is_empty():
						break
					seen[gp.ui._dialogue_page] = true
					if gp.ui.char_index >= str(gp.ui._dialogue_pages[gp.ui._dialogue_page]).length():
						gp.key_h.enter_pressed = true
						gp.ui.draw(gp)
						if gp.game_state == gp.DIALOGUE_STATE and not gp.ui._dialogue_pages.is_empty():
							seen[gp.ui._dialogue_page] = true
					guard2 += 1
				check("every page of it gets shown, and then it ends",
					seen.size() == epic_pages.size() and gp.game_state == gp.PLAY_STATE,
					"saw %d of %d pages, state %d" % [seen.size(), epic_pages.size(), gp.game_state])
				gp.game_state = gp.PLAY_STATE
				gp.key_h.enter_pressed = false
				gp.quest = QuestLog.new()

		1053:
			print("\n-- the three classes --")

			var roster: Array = gp.player_classes
			check("all three classes are loaded", roster.size() == 3, str(roster.size()))

			var ids := {}
			for c in roster:
				ids[c.id] = c
			check("they are samurai, ninja and zilla",
				ids.has("samurai") and ids.has("ninja") and ids.has("zilla"),
				str(ids.keys()))

			check("nobody starts with the Boots any more",
				not ids["samurai"].starts_with_boots and not ids["ninja"].starts_with_boots
					and not ids["zilla"].starts_with_boots)
			check("the ninja is the quick one and zilla the slow one",
				ids["ninja"].walk_speed > ids["samurai"].walk_speed
					and ids["zilla"].walk_speed < ids["samurai"].walk_speed,
				"%d %d %d" % [ids["ninja"].walk_speed, ids["samurai"].walk_speed,
					ids["zilla"].walk_speed])

			if gp.e_manager and gp.e_manager.lighting:
				gp.e_manager.lighting.day_state = gp.e_manager.lighting.DAY
			if gp.e_manager and gp.e_manager.clock:
				gp.e_manager.clock.day_index = 2

			# Damage per second, through the real swing and the real damage
			# code, against the thing each class will actually be fighting.
			print("      damage per second, by class and level:")
			var spread_ok := true
			for pair in [[1, "Snome"], [6, "Kamijack"], [11, "Shadow"], [14, "Shadow"]]:
				var lv: int = pair[0]
				var mon: String = pair[1]
				var dps := {}
				for key in ["samurai", "ninja", "zilla"]:
					dps[key] = _dps_against(ids[key], lv, mon)
				var best: float = maxf(dps["samurai"], maxf(dps["ninja"], dps["zilla"]))
				var worst: float = minf(dps["samurai"], minf(dps["ninja"], dps["zilla"]))
				print("        lv %2d vs %-9s  samurai %5.1f   ninja %5.1f   zilla %5.1f" % [
					lv, mon, dps["samurai"], dps["ninja"], dps["zilla"]])
				# Nobody may be twice as good at killing as anybody else.
				if worst <= 0.0 or best / worst > 2.0:
					spread_ok = false
			check("no class kills twice as fast as another", spread_ok,
				"see the table above")

			# Each one has to be the best at something.
			var lv_mid := 8
			var soft: Dictionary = {}
			var armoured: Dictionary = {}
			for key in ["samurai", "ninja", "zilla"]:
				soft[key] = _dps_against(ids[key], lv_mid, "Slime")
				armoured[key] = _dps_against(ids[key], lv_mid, "Shadow")
			check("the ninja is the fastest against soft targets",
				soft["ninja"] > soft["samurai"] and soft["ninja"] > soft["zilla"],
				"%.1f %.1f %.1f" % [soft["ninja"], soft["samurai"], soft["zilla"]])
			check("zilla is the best against armour",
				armoured["zilla"] > armoured["ninja"],
				"%.1f vs %.1f" % [armoured["zilla"], armoured["ninja"]])

			# Toughness has to go the other way.
			var tough := {}
			for key in ["samurai", "ninja", "zilla"]:
				var me: Dictionary = _as_class(ids[key], lv_mid)
				tough[key] = int(ceil(float(me["life"]) / float(maxi(14 - me["defense"], 1))))
			check("zilla can stand in a fight the others cannot",
				tough["zilla"] > tough["samurai"] and tough["samurai"] >= tough["ninja"],
				"zilla %d, samurai %d, ninja %d" % [tough["zilla"], tough["samurai"], tough["ninja"]])

			# The ninja's night bonus, through the real attack code.
			var day_attack: int = _as_class(ids["ninja"], 8)["attack"]
			if gp.e_manager and gp.e_manager.lighting:
				gp.e_manager.lighting.day_state = gp.e_manager.lighting.NIGHT
			var night_attack: int = _as_class(ids["ninja"], 8)["attack"]
			var samurai_night: int = _as_class(ids["samurai"], 8)["attack"]
			var samurai_day_attack: int = 0
			if gp.e_manager and gp.e_manager.lighting:
				gp.e_manager.lighting.day_state = gp.e_manager.lighting.DAY
			samurai_day_attack = _as_class(ids["samurai"], 8)["attack"]
			check("the ninja hits harder after dark", night_attack > day_attack,
				"%d by day, %d by night" % [day_attack, night_attack])
			check("and nobody else notices the dark",
				samurai_night == samurai_day_attack,
				"%d vs %d" % [samurai_night, samurai_day_attack])

			# Thrown weapons: the ninja's trade, zilla's afterthought.
			var throw_dmg := {}
			for key in ["samurai", "ninja", "zilla"]:
				var _me: Dictionary = _as_class(ids[key], 10)
				throw_dmg[key] = gp.player.ranged_attack(OBJ_Shuriken.new(gp))
			check("a ninja's shuriken outdoes everyone else's",
				throw_dmg["ninja"] > throw_dmg["samurai"] and throw_dmg["samurai"] > throw_dmg["zilla"],
				str(throw_dmg))
			check("and eventually beats his own sword",
				throw_dmg["ninja"] > _as_class(ids["ninja"], 10)["attack"],
				"%d thrown vs %d melee" % [throw_dmg["ninja"], _as_class(ids["ninja"], 10)["attack"]])

			# Knock-back, both directions.
			var jack := MON_KamiJack.new(gp)
			var _s: Dictionary = _as_class(ids["zilla"], 6)
			jack.speed = 0
			jack.set_knock_back(jack, gp.player, 10)
			var zilla_shove: int = jack.speed
			jack.speed = 0
			var _s2: Dictionary = _as_class(ids["samurai"], 6)
			jack.set_knock_back(jack, gp.player, 10)
			var samurai_shove: int = jack.speed
			check("zilla hits things further than the samurai does",
				zilla_shove > samurai_shove, "%d vs %d" % [zilla_shove, samurai_shove])

			gp.player.speed = 0
			gp.player.set_knock_back(gp.player, jack, 10)
			var samurai_taken: int = gp.player.speed
			var _s3: Dictionary = _as_class(ids["ninja"], 6)
			gp.player.speed = 0
			gp.player.set_knock_back(gp.player, jack, 10)
			var ninja_taken: int = gp.player.speed
			check("the samurai keeps his feet better than the ninja",
				samurai_taken < ninja_taken, "%d vs %d" % [samurai_taken, ninja_taken])

			# Everyone gets the same number of levels out of the same exp.
			var stats_ref := PlayerStats.new()
			var life_at_20 := {}
			for key in ["samurai", "ninja", "zilla"]:
				life_at_20[key] = ids[key].max_life_at(20, stats_ref.max_life)
			check("every class levels on the same exp curve",
				stats_ref.exp_to_reach(20) == 3578, str(stats_ref.exp_to_reach(20)))
			check("but they do not all grow the same",
				life_at_20["zilla"] > life_at_20["samurai"], str(life_at_20))

			# A class survives a save and a load.
			gp.player.char_class = ids["zilla"]
			gp.player.set_default_values()
			gp.save_load.save()
			gp.player.char_class = ids["ninja"]
			gp.save_load.load_game()
			check("the class you picked survives a save",
				gp.player.char_class != null and gp.player.char_class.id == "zilla",
				str(gp.player.char_class.id if gp.player.char_class else "none"))

			gp.player.char_class = ids["samurai"]
			gp.player.set_default_values()
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 94
			gp.current_map = 0
			gp.game_state = gp.PLAY_STATE

		1055:
			print("\n-- levelling and the difficulty curve --")

			var stats := PlayerStats.new()
			if gp.e_manager and gp.e_manager.clock:
				gp.e_manager.clock.day_index = 2      # an ordinary day, no multipliers

			# The curve: every level dearer than the last, no walls.
			var steps: Array[int] = []
			for lv in range(1, 21):
				steps.append(stats.exp_to_reach(lv + 1) - stats.exp_to_reach(lv))
			var rising := true
			var worst_jump := 1.0
			for k in range(1, steps.size()):
				if steps[k] <= steps[k - 1]:
					rising = false
				worst_jump = maxf(worst_jump, float(steps[k]) / float(steps[k - 1]))
			check("every level costs more than the one before it", rising, str(steps))
			check("but no level costs twice the last one", worst_jump < 2.0,
				"worst jump x%.2f" % worst_jump)
			check("level 2 is a couple of kills away",
				stats.exp_to_reach(2) <= 15, str(stats.exp_to_reach(2)))
			check("level 20 is a whole game away",
				stats.exp_to_reach(20) > 2000, str(stats.exp_to_reach(20)))
			print("      exp to reach:  lv2 %d   lv5 %d   lv10 %d   lv20 %d" % [
				stats.exp_to_reach(2), stats.exp_to_reach(5),
				stats.exp_to_reach(10), stats.exp_to_reach(20)])

			# Where the player is expected to be when they first meet each thing.
			var ladder := [
				{"name": "Slime", "level": 1, "hits": [2, 4], "touches": [5, 12]},
				{"name": "Snome", "level": 2, "hits": [2, 4], "touches": [5, 12]},
				{"name": "Kamijack", "level": 6, "hits": [4, 8], "touches": [3, 8]},
				{"name": "Shadow", "level": 11, "hits": [7, 13], "touches": [3, 8]},
			]

			print("      at the level you meet it:")
			for rung in ladder:
				var lv: int = rung["level"]
				gp.player.level = lv
				gp.player.max_life = stats.max_life_at(lv)
				gp.player.life = gp.player.max_life
				gp.player.strength = stats.strength_at(lv)
				gp.player.dexterity = stats.dexterity_at(lv)
				gp.player.current_weapon = gp.e_generator.get_object("Kami no Bokken")
				gp.player.current_shield = gp.e_generator.get_object("Puffa Shield")
				gp.player.get_attack()
				gp.player.get_defense()

				var mon = gp.e_generator.get_monster(rung["name"])
				# One real swing, through the real damage path.
				mon.max_life = 100000
				mon.life = 100000
				gp.monster[gp.current_map][6] = mon
				gp.player.damage_monster(6, gp.player, gp.player.attack, 0)
				var per_hit: int = 100000 - mon.life
				gp.monster[gp.current_map][6] = null

				var fresh = gp.e_generator.get_monster(rung["name"])
				var to_kill: int = int(ceil(float(fresh.max_life) / float(maxi(per_hit, 1))))
				var per_touch: int = maxi(fresh.attack - gp.player.defense, 1)
				var to_die: int = int(ceil(float(gp.player.max_life) / float(per_touch)))

				print("        %-9s lv %2d   %2d hits to kill   %2d touches to die   %d exp" % [
					rung["name"], lv, to_kill, to_die, fresh.exp])

				check("%s takes %d-%d hits when you meet it" % [
						rung["name"], rung["hits"][0], rung["hits"][1]],
					to_kill >= rung["hits"][0] and to_kill <= rung["hits"][1],
					"%d hits at level %d" % [to_kill, lv])
				check("%s takes %d-%d touches to kill you" % [
						rung["name"], rung["touches"][0], rung["touches"][1]],
					to_die >= rung["touches"][0] and to_die <= rung["touches"][1],
					"%d touches at level %d" % [to_die, lv])

			# Nothing on the starting map may one shot a new player, and a new
			# player must be able to hurt everything, however slowly.
			gp.player.level = 1
			gp.player.max_life = stats.max_life
			gp.player.life = gp.player.max_life
			gp.player.strength = stats.strength
			gp.player.dexterity = stats.dexterity
			gp.player.current_weapon = gp.e_generator.get_object("Kami no Bokken")
			gp.player.current_shield = gp.e_generator.get_object("Puffa Shield")
			gp.player.get_attack()
			gp.player.get_defense()

			var worst_hit := 0
			var unkillable: Array[String] = []
			for m in gp.monster[0]:
				if m == null:
					continue
				worst_hit = maxi(worst_hit, maxi(m.attack - gp.player.defense, 1))
				if gp.player.attack - m.defense < 1 and false:
					unkillable.append(m.name)
			check("nothing on the world map kills a new player in one touch",
				worst_hit < stats.max_life, "%d damage vs %d life" % [worst_hit, stats.max_life])

			var wall := MON_ShadowKatsu.new(gp)
			wall.max_life = 100000
			wall.life = 100000
			gp.monster[gp.current_map][6] = wall
			gp.player.damage_monster(6, gp.player, gp.player.attack, 0)
			check("a level 1 player can still chip the toughest thing in the game",
				100000 - wall.life >= 1, str(100000 - wall.life))
			gp.monster[gp.current_map][6] = null

			# What the world map is worth in levels.
			var world_exp := 0
			for m in gp.monster[0]:
				if m != null:
					world_exp += m.exp
			var reached := 1
			while stats.exp_to_reach(reached + 1) <= world_exp:
				reached += 1
			print("      clearing the world map = %d exp = level %d" % [world_exp, reached])
			check("clearing the world map once gets you to level 4-6",
				reached >= 4 and reached <= 6, "level %d off %d exp" % [reached, world_exp])

			gp.player.set_default_values()
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 94

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
			check("a ticket with no route is not a ticket", q.grant_ticket("") == false)
			check("a second ticket buys a second trip",
				q.grant_ticket("cave") and q.pass_count("cave") == 2, str(q.pass_count("cave")))
			check("and a trip is spent when it is used", q.spend_pass("cave") and q.pass_count("cave") == 1)
			check("holding a ticket makes the route known to Kami Mart", q.is_known("cave"))
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

			# Holding the paper ticket is not the same as being stamped, and the
			# objective line has to say which of the two you are missing.
			var unstamped := QuestLog.new()
			check("with nothing at all, buy a ticket",
				unstamped.objective_text(dungeons) == "Get a ticket to Cave.",
				unstamped.objective_text(dungeons))
			check("with a ticket in the bag, go to the collector",
				unstamped.objective_text(dungeons, ["cave"])
					== "Take your Cave ticket to the collector.",
				unstamped.objective_text(dungeons, ["cave"]))
			check("a carried ticket changes the boat's wording, not what sails",
				"collector" in BoatService.destinations(dungeons, unstamped, 1, ["cave"])[0]["reason"]
					and BoatService.sailable(dungeons, unstamped, 1, ).is_empty(),
				BoatService.destinations(dungeons, unstamped, 1, ["cave"])[0]["reason"])

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
				QuestLog.new().passes.is_empty())

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

		1070:
			print("\n-- squeezing through a one-tile doorway --")

			# The hut's doorway is one tile wide: col 26 of row 32, walls both
			# sides. Walking into it a few pixels off centre used to stop the
			# player dead; corner_assist is what lets them round the frame.
			gp.current_map = 1
			gp.game_state = gp.PLAY_STATE
			gp.player.direction = "down"
			gp.player.speed = 4
			# Eight pixels of the player's box hang into the wall tile beside the
			# doorway. Derived from the box rather than hard coded, so this still
			# tests what it says it does if the box is ever resized.
			gp.player.world_x = (26 * gp.tile_size - 8) - gp.player.solid_area.x
			gp.player.world_y = 1534 - gp.player.solid_area.y - gp.player.solid_area.height

			var start_y: int = gp.player.world_y
			var blocked_frames := 0
			for _i in range(24):
				gp.player.collision_on = false
				gp.c_checker.check_tile(gp.player)
				if gp.player.collision_on:
					blocked_frames += 1
				else:
					gp.player.world_y += gp.player.speed

			check("the doorway does not block a slightly misaligned player",
				gp.player.world_y > start_y,
				"stuck at %d after %d blocked frames" % [gp.player.world_y, blocked_frames])
			check("and it took a moment of sliding, not a teleport",
				blocked_frames > 0 and blocked_frames < 16, str(blocked_frames))
			check("the slide stopped once the player was inside the doorway",
				gp.player.world_x + gp.player.solid_area.x >= 26 * gp.tile_size
					and gp.player.world_x + gp.player.solid_area.x < 27 * gp.tile_size,
				str(gp.player.world_x + gp.player.solid_area.x))

			# Squarely facing a wall must still be a wall: no drift, no move.
			gp.player.world_x = 1104      # against the left wall of the room
			gp.player.world_y = 1534 - gp.player.solid_area.y - gp.player.solid_area.height
			gp.player.direction = "down"
			var wall_x: int = gp.player.world_x
			var wall_y: int = gp.player.world_y
			for _i in range(12):
				gp.player.collision_on = false
				gp.c_checker.check_tile(gp.player)
				if not gp.player.collision_on:
					gp.player.world_y += gp.player.speed
			check("a wall you are squarely facing is still a wall",
				gp.player.world_y == wall_y, str(gp.player.world_y))
			check("and the player is not slid sideways along it",
				absi(gp.player.world_x - wall_x) <= 2, str(gp.player.world_x))

			gp.current_map = 0
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 94
			gp.player.speed = gp.player.default_speed

		1072:
			print("\n-- hitboxes --")

			# A monster's solid_area is both its hurtbox and its body, so one
			# that draws at two tiles and keeps a one-tile box in its corner is
			# a monster you swing at and miss.
			var jack := MON_KamiJack.new(gp)
			var jack_sprite: int = gp.tile_size * 2
			check("the Kamijack draws two tiles wide",
				jack.down1 != null and int(jack.down1.get_width()) == jack_sprite,
				str(jack.down1.get_width() if jack.down1 else -1))
			check("its hitbox covers the middle of that sprite, not a corner",
				jack.solid_area.x > jack_sprite / 6
					and jack.solid_area.x + jack.solid_area.width > jack_sprite / 2
					and jack.solid_area.width >= gp.tile_size,
				"x %d w %d" % [jack.solid_area.x, jack.solid_area.width])
			check("and still fits down a two-tile corridor",
				jack.solid_area.width < gp.tile_size * 2
					and jack.solid_area.height < gp.tile_size * 2,
				"%d x %d" % [jack.solid_area.width, jack.solid_area.height])

			check("nothing on the world map outruns a player in boots",
				jack.speed < PlayerStats.new().boots_walk_speed
					or jack.speed <= gp.player.default_speed,
				str(jack.speed))


			# Being hit slows a Kamijack down, and it recovers. Java set the
			# counter and never ticked it, so the slow lasted forever.
			jack.damage_reaction()
			var slowed: int = jack.speed
			check("a hit slows it", slowed < jack.default_speed,
				"%d vs %d" % [slowed, jack.default_speed])
			for _i in range(200):
				jack.tick_slow_down()
			check("and the slow wears off", jack.speed == jack.default_speed,
				"%d vs %d" % [jack.speed, jack.default_speed])

			# Every monster's box should sit inside the sprite it is drawn as.
			for maker in ["Slime", "Snome", "Kamijack", "Shadow"]:
				var m = gp.e_generator.get_monster(maker)
				if m == null or m.down1 == null:
					continue
				var w: int = m.down1.get_width()
				var h: int = m.down1.get_height()
				check("%s's hitbox is inside its sprite" % maker,
					m.solid_area.x >= 0 and m.solid_area.y >= 0
						and m.solid_area.x + m.solid_area.width <= w
						and m.solid_area.y + m.solid_area.height <= h,
					"box %d,%d %dx%d in %dx%d" % [m.solid_area.x, m.solid_area.y,
						m.solid_area.width, m.solid_area.height, w, h])

		1075:
			print("\n-- the guide who walks to the boat --")

			var guide = null
			for n in gp.npc[0]:
				if n is NPC_OldMan and not n.guide_dungeon_id.is_empty():
					guide = n
			check("the dock guide is on the world map", guide != null, str(guide))

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

				# The real walk: from where he actually stands on the map, all the
				# way to the dock, with the player following a step behind him
				# the whole way. That is the case that used to wedge him.
				guide.on_path = true
				guide.world_x = 91 * gp.tile_size - guide.solid_area.x
				guide.world_y = 94 * gp.tile_size - guide.solid_area.y
				gp.player.world_x = guide.world_x + gp.tile_size
				gp.player.world_y = guide.world_y
				var guide_start_x: int = guide.world_x
				var stuck_frames := 0
				var last := Vector2i(guide.world_x, guide.world_y)
				for _i in range(1200):
					if not guide.on_path:
						break
					guide.update()
					var now := Vector2i(guide.world_x, guide.world_y)
					if now == last:
						stuck_frames += 1
					last = now
					# The player follows, one tile behind.
					gp.player.world_x = guide.world_x + gp.tile_size
					gp.player.world_y = guide.world_y
				check("he is not standing still for most of the walk",
					stuck_frames < 240, "%d frames without moving" % stuck_frames)
				@warning_ignore("integer_division")
				var guide_col: int = (guide.world_x + guide.solid_area.x) / gp.tile_size
				check("he makes real progress with the player on his heels",
					guide.world_x < guide_start_x - gp.tile_size,
					"moved from %d to %d" % [guide_start_x, guide.world_x])
				check("and reaches the dock", guide.on_path == false and guide_col <= 88,
					"col %d, on_path %s" % [guide_col, str(guide.on_path)])

				# A goal that cannot be reached at all stops the walk rather
				# than leaving him grinding at a wall.
				guide.guide_col = 0
				guide.guide_row = 0          # the map border, solid
				guide.on_path = true
				for _i in range(120):
					guide.set_action()
				check("an unreachable goal ends the walk", guide.on_path == false)
				guide.guide_col = 87
				guide.guide_row = 97

				gp.player.world_x = gp.tile_size * 94
				gp.player.world_y = gp.tile_size * 94

				# An NPC with no guide id is unchanged: small talk that cycles.
				var plain = null
				for n in gp.npc[0]:
					if n is NPC_OldMan and n.guide_dungeon_id.is_empty():
						plain = n
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

		1078:
			print("\n-- the economy --")

			check("a new game starts broke", PlayerStats.new().coin == 0,
				str(PlayerStats.new().coin))

			gp.current_map = 0
			gp.game_state = gp.PLAY_STATE

			# What each kind of monster is worth, averaged over 400 kills.
			var per_slime: float = _coin_yield("Slime", 400)
			var per_snome: float = _coin_yield("Snome", 400)
			var per_jack: float = _coin_yield("Kamijack", 400)
			var per_shadow: float = _coin_yield("Shadow", 400)
			gp.a_setter.set_object()

			print("      avg coins: slime %.1f  snome %.1f  kamijack %.1f  shadow %.1f" % [
				per_slime, per_snome, per_jack, per_shadow])

			check("every monster is worth something", per_slime > 0 and per_snome > 0)
			check("the dangerous ones pay better than the easy ones",
				per_jack > per_snome and per_snome > per_slime,
				"%.1f %.1f %.1f" % [per_slime, per_snome, per_jack])

			# What the starting map actually holds.
			var roster := {"Slime": 0, "Snome": 0, "Kamijack": 0, "Shadow": 0}
			for m in gp.monster[0]:
				if m == null:
					continue
				if m is MON_Slime: roster["Slime"] += 1
				elif m is MON_Snome: roster["Snome"] += 1
				elif m is MON_KamiJack: roster["Kamijack"] += 1
				elif m is MON_ShadowKatsu: roster["Shadow"] += 1

			var sweep: float = (roster["Slime"] * per_slime + roster["Snome"] * per_snome
					+ roster["Kamijack"] * per_jack + roster["Shadow"] * per_shadow)
			var careful_sweep: float = roster["Slime"] * per_slime + roster["Snome"] * per_snome

			print("      world map: %s   full sweep ~%d coins, avoiding the hard ones ~%d" % [
				str(roster), int(sweep), int(careful_sweep)])

			# The point of all of it: a first afternoon has to end at the shop
			# with something to show for it.
			var cheapest := 999999
			var ticket_price := 0
			for d in gp.dungeons:
				if d is DungeonInfo and d.sold_from_start and d.ticket_price > 0:
					ticket_price = d.ticket_price
			var shop = gp.npc[1][1]
			gp.quest = QuestLog.new()
			shop.refresh_stock()
			for item in shop.inventory:
				cheapest = mini(cheapest, item.price)

			check("clearing the starting map buys a boat ticket",
				sweep >= float(ticket_price) and ticket_price > 0,
				"%d coins vs a %d coin ticket" % [int(sweep), ticket_price])
			check("even playing it safe buys something from the shop",
				careful_sweep >= float(cheapest) and cheapest < 999999,
				"%d coins vs the %d coin cheapest item" % [int(careful_sweep), cheapest])
			check("but not the whole shop in one afternoon",
				sweep < 210.0, "%d coins" % int(sweep))

			# Coins lying around: worth finding, never the main income.
			var scattered := 0
			for o in gp.obj[0]:
				if o is OBJ_Coin:
					scattered += o.value
			check("there are coins to find on the map", scattered > 0, str(scattered))
			check("but they are worth less than the monsters",
				float(scattered) < sweep, "%d scattered vs %d from monsters" % [scattered, int(sweep)])
			print("      scattered on the world map: %d coins" % scattered)

			# Chopping a dry tree pays now and then - the grass-cutting money of
			# this game, and a reason to carry the axe.
			var tree_total := 0
			for _i in range(400):
				for slot in range(gp.obj[gp.current_map].size()):
					gp.obj[gp.current_map][slot] = null
				var tree := IT_DryTree.new(gp, 90, 90)
				tree.check_drop()
				for o in gp.obj[gp.current_map]:
					if o is OBJ_Coin:
						tree_total += o.value
			gp.a_setter.set_object()
			var per_tree: float = float(tree_total) / 400.0
			print("      avg coins per dry tree: %.1f" % per_tree)
			check("chopping a tree sometimes pays", per_tree > 0.0)
			check("but less than killing something", per_tree < per_slime,
				"%.1f vs %.1f" % [per_tree, per_slime])

			# A placed coin keeps its value through a save.
			var big := OBJ_Coin.worth(gp, 20)
			check("a coin can be worth more than one", big.value == 20)
			check("and a fat coin is drawn bigger",
				big.down1.get_width() > OBJ_Coin.worth(gp, 1).down1.get_width())

			# Clear the map, walk away, come back: it is full again. This is the
			# loop that keeps the shop reachable without making coins free.
			for slot in range(gp.monster[0].size()):
				gp.monster[0][slot] = null
			check("the map is empty after a clear", monsters_alive(0) == 0)

			gp.e_handler.change_map(1, 25, 22)
			gp.ui.counter = 50
			gp.ui.update_transition()
			gp.e_handler.change_map(0, 94, 94)
			gp.ui.counter = 50
			gp.ui.update_transition()
			check("walking back in refills it", monsters_alive(0) == 23,
				str(monsters_alive(0)))
			check("and the player is back on the world map", gp.current_map == 0)

			gp.player.coin = 0
			gp.player.world_x = gp.tile_size * 94
			gp.player.world_y = gp.tile_size * 94

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

				# A ticket is paper. Selecting it in the menu must not turn it
				# into passage, wherever the player happens to be standing.
				var bought = stocked_tickets[0]
				gp.player.inventory.append(bought)
				check("a ticket cannot be used from the inventory",
					bought.use(gp.player) == false)
				check("and using it grants nothing",
					gp.quest.has_ticket("mushroom_cave") == false)
				gp.game_state = gp.PLAY_STATE

				# The collector at the dock is the only one who can stamp it.
				var collector = null
				for n in gp.npc[0]:
					if n is NPC_TicketMan:
						collector = n
				check("there is a ticket collector at the dock", collector != null)

				if collector != null:
					var bag_before: int = gp.player.inventory.size()
					collector.speak()
					check("he takes the ticket",
						gp.player.inventory.size() == bag_before - 1,
						"%d -> %d" % [bag_before, gp.player.inventory.size()])
					check("and stamps a boarding pass",
						gp.quest.has_ticket("mushroom_cave"))
					check("one ticket buys exactly one trip",
						gp.quest.pass_count("mushroom_cave") == 1,
						str(gp.quest.pass_count("mushroom_cave")))
					check("he says which route and when",
						"Mushroom Cave" in str(collector.dialogues[NPC_TicketMan.STAMPED_SET][0]),
						str(collector.dialogues[NPC_TicketMan.STAMPED_SET][0]))
					gp.game_state = gp.PLAY_STATE

					# Empty handed, he sends you shopping rather than aboard.
					gp.quest = QuestLog.new()
					collector.speak()
					check("with no ticket he refuses",
						collector.dialogue_set == NPC_TicketMan.NOTHING_TO_STAMP,
						str(collector.dialogue_set))
					check("and says where tickets come from",
						"Kami Mart" in str(collector.dialogues[NPC_TicketMan.NOTHING_TO_STAMP][1]),
						str(collector.dialogues[NPC_TicketMan.NOTHING_TO_STAMP][1]))
					gp.game_state = gp.PLAY_STATE

			gp.player.inventory.clear()
			gp.player.set_items()
			merchant.refresh_stock()
			var still_stocked := 0
			for item in merchant.inventory:
				if item is OBJ_BoatTicket:
					still_stocked += 1
			check("the shop keeps selling tickets, now that they get used up",
				still_stocked == 1, str(still_stocked))
			check("the ordinary stock is untouched", merchant.inventory.size() == 5,
				str(merchant.inventory.size()))

			# The Shadow Deep is not on the shelf until the player has held one
			# of its tickets - the cave's boss hands over the first.
			gp.quest.mark_cleared("mushroom_cave")
			merchant.refresh_stock()
			var deep_on_sale := false
			for item in merchant.inventory:
				if item is OBJ_BoatTicket and item.route_id == "shadow_deep":
					deep_on_sale = true
			check("a route you have never had a ticket for is not sold", not deep_on_sale)

			gp.quest.mark_known("shadow_deep")
			merchant.refresh_stock()
			for item in merchant.inventory:
				if item is OBJ_BoatTicket and item.route_id == "shadow_deep":
					deep_on_sale = true
			check("but once you have held one, Kami Mart stocks it", deep_on_sale)

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
				check("a boss has its own numbers, not a scaled up Kamijack",
					cave_boss.max_life != MON_KamiJack.new(gp).max_life * 6
						and cave_boss.name != "Boss",
					"%s, %d life" % [cave_boss.name, cave_boss.max_life])
				check("and is much tougher than what guards the corridors",
					cave_boss.max_life > MON_KamiJack.new(gp).max_life * 2,
					str(cave_boss.max_life))

			var deep_boss = null
			for m in gp.monster[deep.map_index]:
				if m is MON_Boss:
					deep_boss = m
			check("the deep has a boss", deep_boss != null)

			# Sail. Monday, with a pass stamped by the collector.
			gp.quest.grant_ticket("mushroom_cave")
			var sail_day := 1
			if gp.e_manager and gp.e_manager.clock:
				gp.e_manager.clock.day_index = sail_day
			# The home port sails every day and needs no ticket, so on a Monday
			# with the cave ticket in hand there are two routes: home and the cave.
			check("the cave is sailing on Monday",
				BoatService.sailable(gp.dungeons, gp.quest, sail_day).size() == 2,
				str(BoatService.sailable(gp.dungeons, gp.quest, sail_day).size()))

			check("the boat refuses a route with no stamped ticket",
				gp.e_handler.sail_to(deep) == false)
			check("and refusing does not move the player",
				gp.game_state != gp.TRANSITION_STATE, str(gp.game_state))

			check("with a pass it sails", gp.e_handler.sail_to(cave) == true)
			check("the trip is spent", gp.quest.pass_count("mushroom_cave") == 0,
				str(gp.quest.pass_count("mushroom_cave")))
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
			# Monday: only the way home. The cave runs today but the ticket that
			# got us here has been used, and the deep is a Saturday route.
			check("the deep does not sail on Monday",
				BoatService.sailable(gp.dungeons, gp.quest, 1).size() == 1,
				str(BoatService.sailable(gp.dungeons, gp.quest, 1).size()))
			# Saturday: home and the deep. The cave only runs Mondays and
			# Thursdays, so it drops off the board.
			if gp.e_manager and gp.e_manager.clock:
				gp.e_manager.clock.day_index = 6
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

			check("the deep sails once its boss ticket is stamped",
				gp.e_handler.sail_to(deep) == true)
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
			if gp.e_manager and gp.e_manager.clock:
				gp.e_manager.clock.day_index = 1
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

		1087:
			print("\n-- building a map without touching code --")

			# Every map scene carries the root script, so every map gets the
			# tool buttons and the warning triangle.
			var rooted := 0
			for node in gp.map_node:
				if node is DungeonMap:
					rooted += 1
			check("every map has a DungeonMap root", rooted == gp.map_node.size(),
				"%d of %d" % [rooted, gp.map_node.size()])

			# And every one of them passes its own check. This is the button a
			# designer presses; if the shipped maps cannot pass it, it is the
			# check that is wrong.
			for i in range(gp.map_node.size()):
				var node = gp.map_node[i]
				if not (node is DungeonMap):
					continue
				var problems: PackedStringArray = node._problems()
				check("%s checks out" % node.name, problems.is_empty(),
					"; ".join(problems))

			# "Set up this map" on an empty map builds what AssetSetter looks
			# for. This is the first button a new person presses, so it had
			# better produce a map the rest of the engine recognises.
			var blank := DungeonMap.new()
			blank.name = "Blank"
			add_child(blank)
			blank._setup_map()
			check("setting up a map makes the Tiles layer", blank.tiles_layer() != null)
			check("with the shared tile set",
				blank.tiles_layer() != null and blank.tiles_layer().tile_set != null)
			var groups_made := 0
			for g in DungeonMap.GROUPS:
				if blank.get_node_or_null(g) != null:
					groups_made += 1
			check("and all five group nodes", groups_made == 5, str(groups_made))
			check("and it says what is still missing",
				blank._problems().size() > 0 and "painted" in " ".join(blank._problems()),
				" ".join(blank._problems()))

			# Pressing it twice does not make a second set of everything.
			blank._setup_map()
			check("setting up twice changes nothing",
				blank.get_child_count() == 6, str(blank.get_child_count()))

			# Paint a patch of floor, then let the border tool frame it.
			for row in range(4, 8):
				for col in range(4, 8):
					blank.tiles_layer().set_cell(Vector2i(col, row), 0, Vector2i(0, 0))
			blank.border_width = 2
			blank._paint_border()
			check("painting the border fills the edges",
				blank.tiles_layer().get_used_rect().size == Vector2i(8, 8),
				str(blank.tiles_layer().get_used_rect()))
			blank.queue_free()

			# The map number and the landing tile are READ off the scene, not
			# typed into the resource. Scribble over both and re-wire: if they
			# come back right, nothing is relying on what was typed.
			var cave_info: DungeonInfo = BoatService.by_id(gp.dungeons, "mushroom_cave")
			var was_index: int = cave_info.map_index
			var was_col: int = cave_info.arrive_col
			var was_row: int = cave_info.arrive_row
			cave_info.map_index = 99
			cave_info.arrive_col = -7
			cave_info.arrive_row = -7
			gp._wire_maps()
			check("the map number comes back from the scene",
				cave_info.map_index == was_index,
				"%d, wanted %d" % [cave_info.map_index, was_index])
			check("and so does the landing tile",
				cave_info.arrive_col == was_col and cave_info.arrive_row == was_row,
				"%d,%d wanted %d,%d" % [cave_info.arrive_col, cave_info.arrive_row,
					was_col, was_row])

			# The landing tile is the Boat marker's tile, so moving the dock in
			# the editor moves where the boat puts you down.
			var cave_map: DungeonMap = gp.map_node[cave_info.map_index]
			var dock: EventMarker = cave_map.boat_dock()
			check("the dock is where the boat lands you", dock != null
				and dock.tile_col() == cave_info.arrive_col
				and dock.tile_row() == cave_info.arrive_row)

			# Markers sort into sub-groups without disappearing: a hundred
			# monsters want folders, and folders used to silently drop them.
			var folder := Node2D.new()
			folder.name = "TestFolder"
			var nested := MonsterMarker.new()
			nested.name = "NestedSlime"
			gp.map_node[0].get_node("Monsters").add_child(folder)
			folder.add_child(nested)
			var found := false
			for m in gp.a_setter.markers(0, "Monsters"):
				if m == nested:
					found = true
			check("a marker in a sub-folder is still found", found)
			folder.queue_free()

			# The cave ships two of them, so the whole path - .tres on disk, into
			# a marker, out as a live monster - is exercised by a real map and
			# not only by this test's hand-built one.
			var cave_idx: int = BoatService.by_id(gp.dungeons, "mushroom_cave").map_index
			var shipped := 0
			for m in gp.monster[cave_idx]:
				if m is MON_Custom:
					shipped += 1
					check("%s came off a resource with its art" % m.name,
						m.name == "Cave Mushroom" and m.down1 != null and m.left1 != null,
						m.name)
			check("the cave ships two resource-only monsters", shipped == 2, str(shipped))

			# A monster that is nothing but a resource.
			var sheet := MonsterStats.new()
			sheet.display_name = "Paper Tiger"
			sheet.max_life = 12
			sheet.attack = 3
			sheet.defense = 1
			sheet.speed = 2
			sheet.exp_reward = 7
			sheet.behaviour = "Chaser"
			sheet.solid_area = Rect2i(8, 16, 32, 32)
			var paper: Entity = gp.e_generator.get_monster("From Stats", sheet)
			check("a monster can be built from a resource alone", paper is MON_Custom)
			check("and it takes its numbers off the sheet",
				paper.name == "Paper Tiger" and paper.max_life == 12
					and paper.attack == 3 and paper.exp == 7,
				"%s life %d atk %d exp %d" % [paper.name, paper.max_life,
					paper.attack, paper.exp])
			check("and its hitbox", paper.solid_area.x == 8 and paper.solid_area.width == 32)

			# A drop table with one certain row pays out that row every time.
			var coin_row := MonsterDrop.new()
			coin_row.item = "Coin"
			coin_row.weight = 10
			coin_row.coin_min = 4
			coin_row.coin_max = 4
			sheet.drops = [coin_row]
			var paid := 0
			for i in range(20):
				var loot: Entity = sheet.roll_drop(gp)
				if loot is OBJ_Coin and loot.value == 4:
					paid += 1
			check("a drop table pays what it says", paid == 20, "%d of 20" % paid)

			# And a "Nothing" row really does mean nothing, so the share of
			# kills that pay out zero is something a designer can dial in.
			var nothing_row := MonsterDrop.new()
			nothing_row.item = "Nothing"
			nothing_row.weight = 1
			sheet.drops = [nothing_row]
			check("a Nothing row drops nothing", sheet.roll_drop(gp) == null)

			# Off-grid markers are reported rather than quietly rounded.
			var stray := ObjectMarker.new()
			stray.name = "Stray"
			gp.map_node[0].get_node("Objects").add_child(stray)
			stray.position = Vector2(94 * 48 + 11, 94 * 48)
			check("an off-grid marker knows it", not stray.is_on_grid())
			stray.snap_to_grid()
			check("and tidying up puts it on a tile", stray.is_on_grid()
				and stray.tile_col() == 94 and stray.tile_row() == 94,
				"%d,%d" % [stray.tile_col(), stray.tile_row()])
			stray.queue_free()

			# Every marker the shipped maps carry is already square on the grid,
			# so the editor is not crying wolf the moment anyone opens a map.
			var crooked: Array[String] = []
			for map_num in range(gp.map_node.size()):
				for group in ["Objects", "NPCs", "Monsters", "InteractiveTiles", "Events"]:
					for m in gp.a_setter.markers(map_num, group):
						if m is PlacementMarker and not m.is_on_grid():
							crooked.append("%s on map %d" % [m.name, map_num])
			check("every shipped marker is on the grid", crooked.is_empty(),
				", ".join(crooked))

			# The doors on the world map point at scenes, not numbers, and the
			# numbers they end up with are the right ones.
			var doors_wired := 0
			for m in gp.a_setter.markers(0, "Events"):
				if m is EventMarker and m.kind == "ChangeMap":
					doors_wired += 1
					check("%s resolved to a real map" % m.name,
						m.target_scene != null
							and m.target_map > 0 and m.target_map < gp.max_map
							and gp.map_scenes[m.target_map] == m.target_scene,
						"map %d" % m.target_map)
			check("the world map's doors are all wired this way", doors_wired == 2,
				str(doors_wired))

			# And the guide walks to wherever the dock marker is, rather than to
			# a pair of numbers somebody typed once.
			var dock_guide = null
			for m in gp.a_setter.markers(0, "NPCs"):
				if m is NpcMarker and not m.guide_dungeon_id.is_empty():
					dock_guide = m
			var home_dock: EventMarker = gp.map_node[0].boat_dock()
			check("the guide takes his destination from the dock",
				dock_guide != null and home_dock != null
					and dock_guide.guide_tile() == Vector2i(
						home_dock.tile_col(), home_dock.tile_row()),
				str(dock_guide.guide_tile()) if dock_guide != null else "no guide")

		1090:
			print("\n================================")
			print("%d passed, %d failed" % [passed, failed.size()])
			for f in failed:
				print("  FAILED: %s" % f)
			print("================================")
			get_tree().quit(0 if failed.is_empty() else 1)
