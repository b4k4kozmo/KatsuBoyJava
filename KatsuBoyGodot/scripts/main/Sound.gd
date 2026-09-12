class_name Sound
extends RefCounted
## Java: main/Sound.java
##
## One AudioStreamPlayer stands in for the javax.sound Clip. Which file each
## slot plays now comes from a SoundBank resource you can edit in the Inspector
## (assets/data/sound_bank.tres) rather than a hardcoded list of paths.
## volume_scale keeps the original 0-5 steps and the same decibel values.

var gp
var player: AudioStreamPlayer
var bank: SoundBank
var volume_scale: int = 3
var volume: float
## loop() in Java used Clip.LOOP_CONTINUOUSLY; here we just restart the stream
## whenever it finishes, which works for any audio format Godot imports.
var looping: bool = false


func _init(gp, bank: SoundBank = null) -> void:
	self.gp = gp
	self.bank = bank

	player = AudioStreamPlayer.new()
	gp.add_child(player)
	player.finished.connect(_on_finished)


func set_file(i: int) -> void:
	if bank == null:
		return
	var stream: AudioStream = bank.get_stream(i)
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
