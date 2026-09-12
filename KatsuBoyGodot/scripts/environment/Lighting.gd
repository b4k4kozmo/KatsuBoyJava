class_name Lighting
extends RefCounted
## Java: environment/Lighting.java
##
## Java ran its own timer here: so many frames of day, then fade, then so many
## frames of night. That is gone - the GameClock is the single source of truth
## now, and this just reads the hour off it. So "is it night?" means the same
## thing to the darkness shader, the merchant's night prices, the curse, and
## the clock on the HUD.

var gp
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
	gp.e_manager.clock.reset()
	refresh()


func update() -> void:

	if gp.player.light_updated == true:
		set_light_source()
		gp.player.light_updated = false

	# While sleeping, UI.update_sleep() is scripting the fade by hand.
	if gp.game_state == gp.SLEEP_STATE:
		return

	refresh()


## Read the hour off the clock and work out how dark it is and which part of
## the cycle we are in.
func refresh() -> void:

	var clock: GameClock = gp.e_manager.clock
	filter_alpha = clock.darkness_amount()

	var h: float = clock.hour_float()
	if GameClock.in_window(h, gp.sunrise_start_hour, gp.sunrise_end_hour):
		day_state = DAWN
	elif GameClock.in_window(h, gp.sunset_start_hour, gp.sunset_end_hour):
		day_state = DUSK
	elif GameClock.in_window(h, gp.sunset_end_hour, gp.sunrise_start_hour):
		day_state = NIGHT
	else:
		day_state = DAY


## Drawing moved to LightingOverlay (a node in main.tscn with the darkness
## shader on it). This class still owns the clock: what time of day it is and
## how far through the fade we are.
