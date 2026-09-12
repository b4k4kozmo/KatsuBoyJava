@tool
extends SceneTree
## Writes assets/data/monsters/*.tres from the numbers that used to be
## hardcoded in each monster script.
## Run: godot --headless --path . --script res://tools/build_monster_stats.gd

const DATA := [
	{"file": "slime", "name": "Slime", "life": 3, "atk": 5, "def": 0, "exp": 1,
	 "speed": 1, "kb": 0, "solid": Rect2i(3, 18, 42, 30),
	 "area": Rect2i(0, 0, 0, 0), "m1": 0, "m2": 0},
	{"file": "snome", "name": "Snome", "life": 12, "atk": 2, "def": 2, "exp": 3,
	 "speed": 1, "kb": 0, "solid": Rect2i(3, 18, 42, 30),
	 "area": Rect2i(0, 0, 0, 0), "m1": 0, "m2": 0},
	{"file": "kamijack", "name": "Kamijack", "life": 111, "atk": 20, "def": 6, "exp": 250,
	 "speed": 12, "kb": 0, "solid": Rect2i(3, 18, 42, 30),
	 "area": Rect2i(0, 0, 0, 0), "m1": 0, "m2": 0},
	{"file": "shadow_katsu", "name": "Shadow", "life": 200, "atk": 7, "def": 4, "exp": 600,
	 "speed": 1, "kb": 5, "solid": Rect2i(4, 4, 40, 44),
	 "area": Rect2i(0, 0, 48, 48), "m1": 40, "m2": 85},
]


func _init() -> void:
	for d in DATA:
		var s := MonsterStats.new()
		s.display_name = d["name"]
		s.max_life = d["life"]
		s.attack = d["atk"]
		s.defense = d["def"]
		s.exp_reward = d["exp"]
		s.speed = d["speed"]
		s.knock_back_power = d["kb"]
		s.solid_area = d["solid"]
		s.attack_area = d["area"]
		s.motion1_duration = d["m1"]
		s.motion2_duration = d["m2"]
		var err := ResourceSaver.save(s, "res://assets/data/monsters/%s.tres" % d["file"])
		print("%s.tres err=%d" % [d["file"], err])
	quit()
