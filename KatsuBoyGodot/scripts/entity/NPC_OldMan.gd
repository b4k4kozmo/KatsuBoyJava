class_name NPC_OldMan
extends Entity
## Java: entity/NPC_OldMan.java
##
## Doubles as the game's guide. Fill in "Guide Dungeon Id" on his NpcMarker and
## he stops being scenery: he tells you about that dungeon, writes it into the
## quest log as your objective, and then walks to "Guide Col"/"Guide Row" so you
## can follow him - point that at the boat dock and he walks you to the boat.


## The tile he heads for once you have spoken to him. Overridden per marker by
## AssetSetter; this default is the shrine path from the original demo.
const DEFAULT_GOAL_COL := 75
const DEFAULT_GOAL_ROW := 95

## Dialogue set reserved for the generated guide line, kept clear of the
## hand-written sets 0-2.
const GUIDE_SET := 9

## Set from the NpcMarker. See NpcMarker for what each one does.
var guide_dungeon_id: String = ""
var guide_col: int = -1
var guide_row: int = -1


func _init(gp) -> void:
	super(gp)

	direction = "down"
	speed = 1

	solid_area = Rect.new()
	solid_area.x = 8
	solid_area.y = 16
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
	solid_area.width = 28
	solid_area.height = 28

	# Starts at -1 so that the first speak() lands on dialogue set 0.
	dialogue_set = -1
	sound_number = 17

	get_image()
	set_dialogue()


func get_image() -> void:
	up1 = setup("/npc/oldman_up_01", gp.tile_size, gp.tile_size)
	up2 = setup("/npc/oldman_up_02", gp.tile_size, gp.tile_size)
	down1 = setup("/npc/oldman_down_01", gp.tile_size, gp.tile_size)
	down2 = setup("/npc/oldman_down_02", gp.tile_size, gp.tile_size)
	left1 = setup("/npc/oldman_left_01", gp.tile_size, gp.tile_size)
	left2 = setup("/npc/oldman_left_02", gp.tile_size, gp.tile_size)
	right1 = setup("/npc/oldman_right_01", gp.tile_size, gp.tile_size)
	right2 = setup("/npc/oldman_right_02", gp.tile_size, gp.tile_size)


func set_dialogue() -> void:
	dialogues[0][0] = "Hello, Katsu boy!\nAre you ready for your adventure?"
	dialogues[0][1] = "There's something useful in the\nforest."
	dialogues[0][2] = "Welcome to the lost hood."
	dialogues[0][3] = "Hmmm... you don't remember?"
	dialogues[0][4] = "Try going up north."
	dialogues[0][5] = "I'm here as long as you need me.."

	dialogues[1][0] = "Between you and me theres \na secret teleporter nearby \nthat takes you to a save point!"
	dialogues[1][1] = "Don't tell anyone i told you though..."
	dialogues[1][2] = "Seriously.. DON'T"
	dialogues[1][3] = "You can also reset that \nweird night curse at the KamiMart"
	dialogues[1][4] = "I think I can trust you."
	dialogues[1][5] = "Sell your items at night. \nCatch that stinkin' gnome..."

	dialogues[2][0] = "Well, if it isn't the well known adventurer!"
	dialogues[2][1] = "KATSU BOY!"


func set_action() -> void:

	if on_path == true:
		var goal_col: int = guide_col if guide_col >= 0 else DEFAULT_GOAL_COL
		var goal_row: int = guide_row if guide_row >= 0 else DEFAULT_GOAL_ROW

		# Stop once he is standing on the tile rather than shuffling on it
		# forever, so a guide who has reached the dock stays at the dock.
		if _on_tile(goal_col, goal_row):
			on_path = false
			direction = "down"
			return

		search_path(goal_col, goal_row)
	else:
		action_lock_counter += 1

		if action_lock_counter == 120:
			var i: int = randi() % 100 + 1  # pick a number between 1 and 100

			if i < 25: direction = "up"
			if i > 25 and i <= 50: direction = "down"
			if i > 50 and i <= 75: direction = "left"
			if i > 75 and i <= 100: direction = "right"

			action_lock_counter = 0


func speak() -> void:

	# Character specific stuff
	set_sound()
	face_player()

	# A guide says the same useful thing every time instead of cycling through
	# small talk - a signpost that only works once is not a signpost.
	if _build_guide_dialogue():
		start_dialogue(self, GUIDE_SET)
	else:
		start_dialogue(self, dialogue_set)

		dialogue_set += 1
		if dialogues[dialogue_set][0] == null:
			dialogue_set = 0

	on_path = true


## Writes the hint for his dungeon into GUIDE_SET and points the quest log at
## it. Returns false when he is not a guide, or when the dungeon he was pointed
## at no longer exists, in which case he falls back to his normal dialogue.
func _build_guide_dialogue() -> bool:

	if guide_dungeon_id.is_empty() or gp.quest == null:
		return false

	var info: DungeonInfo = BoatService.by_id(gp.dungeons, guide_dungeon_id)
	if info == null:
		return false

	for i in range(dialogues[GUIDE_SET].size()):
		dialogues[GUIDE_SET][i] = null

	if gp.quest.is_cleared(info.id):
		dialogues[GUIDE_SET][0] = "%s is quiet now.\nThat was good work, Katsu boy." % info.display_name
		return true

	# Whatever the dungeon file says, in the author's own words.
	var line: String = info.hint
	if line.is_empty():
		line = "You should take the boat to\n%s." % info.display_name
	dialogues[GUIDE_SET][0] = line

	var next := 1

	if not gp.quest.has_ticket(info.ticket_id):
		if info.ticket_price > 0:
			dialogues[GUIDE_SET][next] = "You will need a ticket.\nKami Mart sells them, %d coins." % info.ticket_price
		else:
			dialogues[GUIDE_SET][next] = "You will need a ticket for that\nroute. They are not for sale."
		next += 1

	dialogues[GUIDE_SET][next] = "The boat runs that way %s.\nFollow me, I will show you the dock." % info.timetable_text()

	# So the pause screen agrees with what he just said.
	gp.quest.current_target = info.id
	return true


func _on_tile(col: int, row: int) -> bool:
	@warning_ignore("integer_division")
	var my_col: int = (world_x + solid_area.x) / gp.tile_size
	@warning_ignore("integer_division")
	var my_row: int = (world_y + solid_area.y) / gp.tile_size
	return my_col == col and my_row == row
