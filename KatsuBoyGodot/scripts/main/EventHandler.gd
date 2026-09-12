class_name EventHandler
extends RefCounted
## Java: main/EventHandler.java

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


func _init(gp) -> void:
	self.gp = gp

	event_master = Entity.new(gp)

	set_dialogue()


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

		if hit(0, 95, 95, "any") == true: damage_pit(gp.DIALOGUE_STATE)
		elif hit(0, 5, 71, "down") == true: healing_pool(gp.DIALOGUE_STATE)
		elif hit(0, 97, 97, "any") == true: teleport(gp.DIALOGUE_STATE, 5, 70)
		elif hit(0, 8, 46, "any") == true: change_map(1, 26, 32)
		elif hit(1, 26, 32, "any") == true: change_map(0, 8, 46)
		elif hit(1, 26, 20, "up") == true: speak(gp.npc[1][1])

		elif hit(0, 10, 9, "up") == true: change_map(2, 82, 67)
		elif hit(2, 82, 67, "any") == true: change_map(0, 10, 9)


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
	gp.play_se(4)
	event_master.start_dialogue(event_master, 0)
	gp.player.world_x = gp.tile_size * x
	gp.player.world_y = gp.tile_size * y


func damage_pit(game_state: int) -> void:
	gp.game_state = game_state
	gp.play_se(7)
	event_master.start_dialogue(event_master, 1)
	gp.player.life -= 1
	can_touch_event = false


func healing_pool(game_state: int) -> void:

	if gp.key_h.enter_pressed == true:
		gp.game_state = game_state
		gp.player.attack_canceled = true
		gp.stop_se()
		gp.play_se(2)
		event_master.start_dialogue(event_master, 2)
		gp.player.life = gp.player.max_life
		gp.player.mana = gp.player.max_mana
		gp.a_setter.set_monster()
		gp.player.is_cursed = false
		gp.save_load.save()


func change_map(current_map: int, x: int, y: int) -> void:
	gp.game_state = gp.TRANSITION_STATE
	temp_map = current_map
	temp_col = x
	temp_row = y
	can_touch_event = false
	gp.play_se(13)


func speak(entity) -> void:

	if gp.key_h.enter_pressed == true:
		gp.game_state = gp.DIALOGUE_STATE
		gp.player.attack_canceled = true
		entity.speak()
		event_master.sound_number = 20
		event_master.set_sound()
