class_name EventHandler
extends RefCounted
## Java: main/EventHandler.java
##
## Java had one hardcoded line per event in checkEvent(). Now every event is an
## EventMarker node you drop under a map scene's "Events" group and configure in
## the Inspector. This walks those markers in tree order and runs the first one
## the player is standing on - so if two overlap, the one higher in the tree
## wins, exactly like the old if/else-if chain.

var gp
## Java allocated an EventRect for every tile of every map - 10 x 100 x 100 =
## 100,000 objects at startup, of which 8 are ever used. We create them on
## demand instead and keep them keyed by (map, col, row).
var event_rect: Dictionary = {}
var event_master: Entity

var prev_event_x: int
var prev_event_y: int
var can_touch_event: bool = true
var temp_map: int
var temp_col: int
var temp_row: int
## Every EventMarker in the game: {"marker": EventMarker, "map": int}
var events: Array[Dictionary] = []


func _init(gp) -> void:
	self.gp = gp

	event_master = Entity.new(gp)

	collect_events()
	set_dialogue()


## Gather the EventMarker nodes out of every map scene.
func collect_events() -> void:

	events.clear()

	for map_num in range(gp.max_map):
		if map_num >= gp.map_node.size() or gp.map_node[map_num] == null:
			continue
		var group: Node = gp.map_node[map_num].get_node_or_null("Events")
		if group == null:
			continue
		for m in group.get_children():
			if m is EventMarker:
				events.append({"marker": m, "map": map_num})


func get_event_rect(map: int, col: int, row: int) -> EventRect:

	var key := Vector3i(map, col, row)
	if not event_rect.has(key):
		var r := EventRect.new()
		r.x = 23
		r.y = 23
		r.width = 2
		r.height = 2
		r.event_rect_default_x = r.x
		r.event_rect_default_y = r.y
		event_rect[key] = r
	return event_rect[key]


func set_dialogue() -> void:

	event_master.dialogues[0][0] = "Surprise!"

	event_master.dialogues[1][0] = "Ouch! You fell down"

	event_master.dialogues[2][0] = "Mmmmm... that was tasty. \nYou feel refreshed.\nThe game has been saved!!"

	event_master.dialogues[2][1] = "I love this stuff!"


func check_event() -> void:

	# check if the player character is more than 1 tile away from the last event
	var x_distance: int = absi(gp.player.world_x - prev_event_x)
	var y_distance: int = absi(gp.player.world_y - prev_event_y)
	var distance: int = maxi(x_distance, y_distance)
	if distance > gp.tile_size:
		can_touch_event = true

	if can_touch_event == true:

		for e in events:
			var marker: EventMarker = e["marker"]
			if e["map"] != gp.current_map:
				continue
			if hit(e["map"], marker.tile_col(), marker.tile_row(), marker.required_direction) == true:
				run_event(marker)
				break


func run_event(marker: EventMarker) -> void:

	match marker.kind:
		"DamagePit":
			damage_pit(gp.DIALOGUE_STATE)
		"HealingPool":
			healing_pool(gp.DIALOGUE_STATE)
		"Teleport":
			teleport(gp.DIALOGUE_STATE, marker.target_col, marker.target_row)
		"ChangeMap":
			change_map(marker.target_map, marker.target_col, marker.target_row)
		"Speak":
			var entity := resolve_speak_target(marker)
			if entity != null:
				speak(entity)
		"Boat":
			board_boat(marker)


## Turn an EventMarker's "Speak Npc" NodePath into the live NPC entity that
## AssetSetter built from that marker.
func resolve_speak_target(marker: EventMarker) -> Entity:

	if marker.speak_npc.is_empty():
		return null
	var npc_marker: Node = marker.get_node_or_null(marker.speak_npc)
	if npc_marker == null:
		push_warning("Speak event '%s' points at a node that is not there." % marker.name)
		return null
	return gp.a_setter.npc_by_marker.get(npc_marker)


func hit(map: int, col: int, row: int, req_direction: String) -> bool:

	var did_hit := false

	if map == gp.current_map:
		var rect: EventRect = get_event_rect(map, col, row)

		gp.player.solid_area.x = gp.player.world_x + gp.player.solid_area.x
		gp.player.solid_area.y = gp.player.world_y + gp.player.solid_area.y
		rect.x = col * gp.tile_size + rect.x
		rect.y = row * gp.tile_size + rect.y

		if gp.player.solid_area.intersects(rect) and rect.event_done == false:
			if gp.player.direction == req_direction or req_direction == "any":
				did_hit = true
				event_master.sound_number = 18
				event_master.set_sound()
				prev_event_x = gp.player.world_x
				prev_event_y = gp.player.world_y

		gp.player.solid_area.x = gp.player.solid_area_default_x
		gp.player.solid_area.y = gp.player.solid_area_default_y
		rect.x = rect.event_rect_default_x
		rect.y = rect.event_rect_default_y

	return did_hit


func teleport(game_state: int, x: int, y: int) -> void:
	gp.game_state = game_state
	gp.play_se(SE.FANFARE)
	event_master.start_dialogue(event_master, 0)
	gp.player.world_x = gp.tile_size * x
	gp.player.world_y = gp.tile_size * y


func damage_pit(game_state: int) -> void:
	gp.game_state = game_state
	gp.play_se(SE.RECEIVE_DAMAGE)
	event_master.start_dialogue(event_master, 1)
	gp.player.life -= 1
	can_touch_event = false


func healing_pool(game_state: int) -> void:

	if gp.key_h.enter_pressed == true:
		gp.game_state = game_state
		gp.player.attack_canceled = true
		gp.stop_se()
		gp.play_se(SE.POWER_UP)
		event_master.start_dialogue(event_master, 2)
		gp.player.life = gp.player.max_life
		gp.player.mana = gp.player.max_mana
		gp.a_setter.set_monster()
		gp.player.is_cursed = false
		gp.save_load.save()
		# Saving also reports progress, so a player who never dies still shows
		# up on the web high-score board.
		WebScore.post_progress(gp.player.level, gp.player.coin)


## Step onto a dock and the timetable opens. Needs a deliberate button press
## rather than firing on contact, so walking past the dock does not hijack the
## screen.
func board_boat(marker: EventMarker) -> void:

	if gp.key_h.enter_pressed != true:
		return

	gp.key_h.enter_pressed = false
	gp.player.attack_canceled = true
	gp.stop_se()
	gp.play_se(SE.DOOR)
	gp.ui.boat_dock_of = marker.dock_of
	gp.ui.command_num = 0
	gp.game_state = gp.BOAT_STATE
	can_touch_event = false


## Take the boat somewhere. Called by the boat menu once a destination is
## chosen; the menu has already checked the route is sailing today.
func sail_to(info: DungeonInfo) -> void:

	if info == null:
		return

	if info.is_victory:
		# Sailing home with everything cleared is the ending.
		gp.ui.game_finished = true
		gp.game_state = gp.ENDING_STATE
		gp.stop_music()
		gp.play_se(SE.FANFARE)
		# Report the finished run to the web high-score board.
		WebScore.post_progress(gp.player.level, gp.player.coin)
		return

	gp.current_dungeon_id = info.id
	gp.play_se(SE.DOOR)
	change_map(info.map_index, info.arrive_col, info.arrive_row)


func change_map(current_map: int, x: int, y: int) -> void:
	gp.game_state = gp.TRANSITION_STATE
	temp_map = current_map
	temp_col = x
	temp_row = y
	can_touch_event = false
	gp.play_se(SE.DOOR)


func speak(entity) -> void:

	if gp.key_h.enter_pressed == true:
		gp.game_state = gp.DIALOGUE_STATE
		gp.player.attack_canceled = true
		entity.speak()
		event_master.sound_number = 20
		event_master.set_sound()
