class_name GameClock
extends RefCounted
## The in-game clock and calendar.
##
## Time moves in fixed steps, Harvest Moon style: every so many frames the clock
## jumps forward a few minutes rather than creeping along. Everything about the
## day - how light it is, whether the merchant pays night prices, what the HUD
## says - is worked out from the hour, so there is one source of truth.
##
## All the numbers below live on GamePanel's "Time of day" Inspector group.

const MINUTES_PER_HOUR := 60
const MINUTES_PER_DAY := 24 * MINUTES_PER_HOUR
const DAY_NAMES := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
		"Friday", "Saturday"]

var gp
## Minutes since midnight of the very first day. Never wraps.
var total_minutes: int = 0
## 0 = Sunday. Rolls over at GamePanel's Day Rollover Hour.
var day_index: int = 0
## Frames counted towards the next time step.
var step_counter: int = 0


func _init(gp) -> void:
	self.gp = gp
	reset()


func reset() -> void:
	total_minutes = gp.start_hour * MINUTES_PER_HOUR + gp.start_minute
	day_index = clampi(gp.start_day, 0, 6)
	step_counter = 0


func update() -> void:
	step_counter += 1
	if step_counter >= gp.frames_per_time_step:
		step_counter = 0
		advance(gp.minutes_per_time_step)


## Push the clock forward. Walks a minute at a time so the day rollover is
## caught no matter how big the jump is.
func advance(minutes_to_add: int) -> void:
	var rollover: int = gp.day_rollover_hour * MINUTES_PER_HOUR
	for _i in range(maxi(minutes_to_add, 0)):
		total_minutes += 1
		if total_minutes % MINUTES_PER_DAY == rollover:
			day_index = (day_index + 1) % 7


## Jump to a specific time. Rolls the calendar forward if that means skipping
## past the rollover hour - which is what sleeping in a tent does.
func set_time(hour: int, minute: int = 0, next_day: bool = false) -> void:
	var target: int = hour * MINUTES_PER_HOUR + minute
	var today_start: int = total_minutes - minute_of_day()
	total_minutes = today_start + target
	if next_day:
		total_minutes += MINUTES_PER_DAY
		day_index = (day_index + 1) % 7


func minute_of_day() -> int:
	return total_minutes % MINUTES_PER_DAY


## The hour as a fraction, e.g. 6:30 is 6.5. Everything that cares about the
## time of day compares against this.
func hour_float() -> float:
	return float(minute_of_day()) / float(MINUTES_PER_HOUR)


func hour() -> int:
	@warning_ignore("integer_division")
	return minute_of_day() / MINUTES_PER_HOUR


func minute() -> int:
	return minute_of_day() % MINUTES_PER_HOUR


func day_name() -> String:
	return DAY_NAMES[day_index % 7]


## "7:35 AM"
func time_string() -> String:
	var h: int = hour()
	var suffix := "AM" if h < 12 else "PM"
	var display_hour: int = h % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minute(), suffix]


## Whether an hour falls inside a window that may wrap past midnight,
## e.g. night runs from 21:00 round to 5:00.
static func in_window(h: float, from_hour: float, to_hour: float) -> bool:
	if from_hour <= to_hour:
		return h >= from_hour and h < to_hour
	return h >= from_hour or h < to_hour


## "Sunrise", "Morning", "Afternoon", "Evening", "Sunset" or "Night".
func period_name() -> String:
	var h: float = hour_float()

	if in_window(h, gp.sunrise_start_hour, gp.sunrise_end_hour):
		return "Sunrise"
	if in_window(h, gp.sunset_start_hour, gp.sunset_end_hour):
		return "Sunset"
	if in_window(h, gp.sunset_end_hour, gp.sunrise_start_hour):
		return "Night"
	if h < gp.midday_hour:
		return "Morning"
	if h < gp.evening_hour:
		return "Afternoon"
	return "Evening"


## 0 in full daylight, 1 at full dark, sliding across sunrise and sunset.
## This is what the darkness shader fades with.
func darkness_amount() -> float:
	var h: float = hour_float()

	# Sunset: light -> dark
	if in_window(h, gp.sunset_start_hour, gp.sunset_end_hour):
		var span: float = _window_length(gp.sunset_start_hour, gp.sunset_end_hour)
		if span <= 0.0:
			return 1.0
		return clampf(_distance_into(h, gp.sunset_start_hour) / span, 0.0, 1.0)

	# Sunrise: dark -> light
	if in_window(h, gp.sunrise_start_hour, gp.sunrise_end_hour):
		var span: float = _window_length(gp.sunrise_start_hour, gp.sunrise_end_hour)
		if span <= 0.0:
			return 0.0
		return clampf(1.0 - _distance_into(h, gp.sunrise_start_hour) / span, 0.0, 1.0)

	if in_window(h, gp.sunset_end_hour, gp.sunrise_start_hour):
		return 1.0  # night
	return 0.0      # day


func _window_length(from_hour: float, to_hour: float) -> float:
	return to_hour - from_hour if to_hour >= from_hour else (24.0 - from_hour) + to_hour


func _distance_into(h: float, from_hour: float) -> float:
	return h - from_hour if h >= from_hour else (24.0 - from_hour) + h
