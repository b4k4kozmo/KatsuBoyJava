@tool
extends SceneTree
## Writes assets/data/player.tres with the original starting values.
## Run: godot --headless --path . --script res://tools/build_player_stats.gd

func _init() -> void:
	var s := PlayerStats.new()
	var err := ResourceSaver.save(s, "res://assets/data/player.tres")
	print("player.tres err=%d" % err)
	quit()
