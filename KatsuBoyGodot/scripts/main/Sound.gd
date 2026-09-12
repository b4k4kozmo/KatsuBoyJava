class_name Sound
extends RefCounted
## Java: main/Sound.java
##
## One AudioStreamPlayer stands in for the javax.sound Clip. volume_scale keeps
## the original 0-5 steps and the same decibel values.

var gp
var player: AudioStreamPlayer
var sound_url: Array[String] = []
var volume_scale: int = 3
var volume: float
## loop() in Java used Clip.LOOP_CONTINUOUSLY; here we just restart the stream
## whenever it finishes, which works for any audio format Godot imports.
var looping: bool = false


func _init(gp) -> void:
	self.gp = gp

	player = AudioStreamPlayer.new()
	gp.add_child(player)
	player.finished.connect(_on_finished)

	sound_url.resize(30)
	sound_url[0] = "KatsuBoySong"
	sound_url[1] = "coin"
	sound_url[2] = "powerup"
	sound_url[3] = "unlock"
	sound_url[4] = "fanfare"
	sound_url[5] = "nightbeat"
	sound_url[6] = "hitmonster"
	sound_url[7] = "receivedamage"
	sound_url[8] = "swingweapon"
	sound_url[9] = "enemydeath"
	sound_url[10] = "dialogue"
	sound_url[11] = "cursormove"
	sound_url[12] = "death"
	sound_url[13] = "door"
	sound_url[14] = "sleep"
	sound_url[15] = "block"
	sound_url[16] = "parry"
	sound_url[17] = "text"
	sound_url[18] = "text2"
	sound_url[19] = "text3"
	sound_url[20] = "text4"


func set_file(i: int) -> void:
	if i < 0 or i >= sound_url.size() or sound_url[i] == null or sound_url[i] == "":
		return
	var stream: AudioStream = load("res://assets/sound/" + sound_url[i] + ".wav")
	if stream == null:
		return
	# Java made a fresh Clip every time, so a sound always restarts from 0 and
	# never loops unless loop() is called. Mirror that here.
	if stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	looping = false
	player.stream = stream
	check_volume()


func play() -> void:
	if player.stream != null:
		player.play()


func loop() -> void:
	looping = true


func stop() -> void:
	looping = false
	player.stop()


func _on_finished() -> void:
	if looping == true:
		player.play()


func check_volume() -> void:
	match volume_scale:
		0: volume = -80.0
		1: volume = -20.0
		2: volume = -12.0
		3: volume = -5.0
		4: volume = 1.0
		5: volume = 6.0
	player.volume_db = volume
