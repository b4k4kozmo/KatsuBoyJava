@tool
extends SceneTree
## Builds assets/data/sound_bank.tres from the wav files, in SE.gd's slot order.
## Run: godot --headless --path . --script res://tools/build_sound_bank.gd
## Only needed once; after this you edit the bank in the Inspector.

const FILES := [
	"KatsuBoySong", "coin", "powerup", "unlock", "fanfare", "nightbeat",
	"hitmonster", "receivedamage", "swingweapon", "enemydeath", "dialogue",
	"cursormove", "death", "door", "sleep", "block", "parry",
	"text", "text2", "text3", "text4",
]


func _init() -> void:
	var bank := SoundBank.new()
	var streams: Array[AudioStream] = []
	for f in FILES:
		var s: AudioStream = load("res://assets/sound/%s.wav" % f)
		if s == null:
			push_error("missing sound: " + f)
		streams.append(s)
	bank.sounds = streams
	var err := ResourceSaver.save(bank, "res://assets/data/sound_bank.tres")
	print("sound bank: %d slots, err=%d" % [streams.size(), err])
	quit()
