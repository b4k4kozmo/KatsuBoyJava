@tool
extends SceneTree
## Writes assets/data/days/*.tres.
## Run: godot --headless --path . --script res://tools/build_day_effects.gd
## After this, tune them in the Inspector.

const DAYS := [
	{"file": "sunday", "name": "Sunday",
	 "note": "Sunday. The market is shut, but rest does you more good.",
	 "shop_open": false, "heal": 1.5},
	{"file": "monday", "name": "Monday",
	 "note": "Monday. Everything hits a little harder today.",
	 "taken": 1.3},
	{"file": "tuesday", "name": "Tuesday", "note": ""},
	{"file": "wednesday", "name": "Wednesday", "note": ""},
	{"file": "thursday", "name": "Thursday", "note": ""},
	{"file": "friday", "name": "Friday",
	 "note": "Friday. Kami Mart has knocked its prices down.",
	 "price": 0.75},
	{"file": "saturday", "name": "Saturday",
	 "note": "Saturday. You feel strong - your blows land harder.",
	 "dealt": 1.3},
]


func _init() -> void:
	for d in DAYS:
		var e := DayEffect.new()
		e.display_name = d["name"]
		e.note = d["note"]
		e.damage_dealt_multiplier = d.get("dealt", 1.0)
		e.damage_taken_multiplier = d.get("taken", 1.0)
		e.shop_open = d.get("shop_open", true)
		e.shop_price_multiplier = d.get("price", 1.0)
		e.healing_multiplier = d.get("heal", 1.0)
		var err := ResourceSaver.save(e, "res://assets/data/days/%s.tres" % d["file"])
		print("%s.tres err=%d" % [d["file"], err])
	quit()
