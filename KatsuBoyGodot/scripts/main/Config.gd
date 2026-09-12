class_name Config
extends RefCounted
## Java: main/Config.java
##
## Java wrote config.txt next to the jar. Godot writes to user:// (the platform's
## app data folder) because res:// is read only in an exported game.

const CONFIG_PATH := "user://config.txt"

var gp


func _init(gp) -> void:
	self.gp = gp


func save_config() -> void:

	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return

	# Full screen
	if gp.full_screen_on == true:
		file.store_line("On")
	else:
		file.store_line("Off")

	# Music volume
	file.store_line(str(gp.music.volume_scale))

	# SE volume
	file.store_line(str(gp.se.volume_scale))

	file.close()


func load_config() -> void:

	if not FileAccess.file_exists(CONFIG_PATH):
		return

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return

	# Full screen
	var s: String = file.get_line().strip_edges()
	if s == "On":
		gp.full_screen_on = true
	if s == "Off":
		gp.full_screen_on = false

	# Music volume
	s = file.get_line().strip_edges()
	if s.is_valid_int():
		gp.music.volume_scale = int(s)

	# SE volume
	s = file.get_line().strip_edges()
	if s.is_valid_int():
		gp.se.volume_scale = int(s)

	file.close()
