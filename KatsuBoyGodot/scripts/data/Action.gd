class_name Action
extends RefCounted
## The named input actions the game listens for.
##
## The actual keys are in Project Settings -> Input Map, so you (or a player)
## can rebind them there, add a second key, or add a gamepad button, without
## touching any code. These constants are just the names.

const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const CONFIRM := &"confirm"
const SHOOT := &"shoot"
const GUARD := &"guard"
const RUN := &"run"
const PAUSE := &"pause"
const CHARACTER_SCREEN := &"character_screen"
const OPTIONS := &"options"
const WORLD_MAP := &"world_map"
const MINI_MAP := &"mini_map"
const DEBUG_OVERLAY := &"debug_overlay"

## Checked against every key event, so keep it to the actions the game uses.
const ALL: Array[StringName] = [
	MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT,
	CONFIRM, SHOOT, GUARD, RUN,
	PAUSE, CHARACTER_SCREEN, OPTIONS, WORLD_MAP, MINI_MAP, DEBUG_OVERLAY,
]


## The key currently bound to an action, for the Controls screen.
## Returns the first keyboard binding, e.g. "W" or "ENTER".
static func key_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: int = event.physical_keycode if event.keycode == 0 else event.keycode
			return OS.get_keycode_string(code).to_upper()
	return "?"


## "W/A/S/D" style summary of the four movement keys.
static func movement_keys() -> String:
	return "%s%s%s%s" % [key_name(MOVE_UP), key_name(MOVE_LEFT),
			key_name(MOVE_DOWN), key_name(MOVE_RIGHT)]
