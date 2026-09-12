@tool
extends SceneTree
## Writes the game's input actions into project.godot (Project Settings ->
## Input Map). Run once:
##   godot --headless --path . --script res://tools/build_input_map.gd
##
## After that, rebind keys in the editor - this does not need running again.
## It is safe to re-run; it overwrites only these actions.

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"confirm": [KEY_ENTER, KEY_KP_ENTER],
	"shoot": [KEY_SPACE],
	"guard": [KEY_CTRL],
	"run": [KEY_SHIFT],
	"pause": [KEY_P],
	"character_screen": [KEY_C],
	"options": [KEY_ESCAPE],
	"world_map": [KEY_M],
	"mini_map": [KEY_X],
	"debug_overlay": [KEY_T],
}


func _init() -> void:
	for action_name in ACTIONS:
		var events := []
		for code in ACTIONS[action_name]:
			var ev := InputEventKey.new()
			ev.keycode = code
			events.append(ev)
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": 0.2,
			"events": events,
		})
	var err := ProjectSettings.save()
	print("input map: %d actions written, err=%d" % [ACTIONS.size(), err])
	quit()
