class_name SoundBank
extends Resource
## Every piece of audio in the game, in one editable list.
##
## Open assets/data/sound_bank.tres in the Inspector to swap a sound, and see
## scripts/data/SE.gd for what each slot is called. GamePanel holds the bank in
## its "Sound Bank" property, so you can point the game at a different one.

@export var sounds: Array[AudioStream] = []


func get_stream(index: int) -> AudioStream:
	if index < 0 or index >= sounds.size():
		return null
	return sounds[index]
