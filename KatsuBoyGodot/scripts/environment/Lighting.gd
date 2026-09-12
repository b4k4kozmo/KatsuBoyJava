class_name Lighting
extends RefCounted
## Java: environment/Lighting.java

var gp
var day_counter: int
var filter_alpha: float = 0.0

const DAY := 0
const DUSK := 1
const NIGHT := 2
const DAWN := 3
var day_state: int = DAY


func _init(gp) -> void:
	self.gp = gp


## Kept so player.light_updated still has something to poke; the shader reads
## the light's radius straight off the player each frame, so there is nothing
## to rebuild any more.
func set_light_source() -> void:
	pass


func reset_day() -> void:
	day_state = DAY
	filter_alpha = 0.0


func update() -> void:

	if gp.player.light_updated == true:
		set_light_source()
		gp.player.light_updated = false

	# Check the state of the day
	if day_state == DAY:
		day_counter += 1
		if day_counter > gp.day_length_frames:
			day_state = DUSK
			day_counter = 0

	if day_state == DUSK:
		filter_alpha += gp.dusk_fade_speed
		if filter_alpha > 1.0:
			filter_alpha = 1.0
			day_state = NIGHT

	if day_state == NIGHT:
		day_counter += 1
		if day_counter > gp.night_length_frames:
			day_state = DAWN
			day_counter = 0

	if day_state == DAWN:
		filter_alpha -= gp.dawn_fade_speed
		if filter_alpha < 0.0:
			filter_alpha = 0.0
			day_state = DAY


## Drawing moved to LightingOverlay (a node in main.tscn with the darkness
## shader on it). This class still owns the clock: what time of day it is and
## how far through the fade we are.
