class_name NPC_Merchant
extends Entity
## Java: entity/NPC_Merchant.java


func _init(gp) -> void:
	super(gp)

	direction = "down"
	speed = 1

	solid_area = Rect.new()
	solid_area.x = 8
	solid_area.y = 16
	solid_area.width = 32
	solid_area.height = 32
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	sound_number = 20

	get_image()
	set_dialogue()
	set_items()
	set_sound()


func get_image() -> void:
	up1 = setup("/npc/kamimon_down_1", gp.tile_size, gp.tile_size)
	up2 = setup("/npc/kamimon_down_2", gp.tile_size, gp.tile_size)
	down1 = setup("/npc/kamimon_down_1", gp.tile_size, gp.tile_size)
	down2 = setup("/npc/kamimon_down_2", gp.tile_size, gp.tile_size)
	left1 = setup("/npc/kamimon_down_1", gp.tile_size, gp.tile_size)
	left2 = setup("/npc/kamimon_down_2", gp.tile_size, gp.tile_size)
	right1 = setup("/npc/kamimon_down_1", gp.tile_size, gp.tile_size)
	right2 = setup("/npc/kamimon_down_2", gp.tile_size, gp.tile_size)


func set_dialogue() -> void:
	dialogues[0][0] = "Welcome to Kami Mart! \nWhat'll it be?"
	dialogues[0][1] = "Welcome to the bargain jungle!"
	dialogues[1][0] = "See ya next time!"
	dialogues[2][0] = "No... that's too low!"
	dialogues[3][0] = "Thank you for your purchase!"
	dialogues[4][0] = "Your pockets are full!"
	dialogues[5][0] = "I don't got time for jokes!"
	dialogues[6][0] = "Ohhhhh baby!"
	dialogues[7][0] = "Sure.. I'll take that off your hands.."
	dialogues[8][0] = "I dont sell to the likes of you"
	dialogues[9][0] = "Shut today! Come back tomorrow."


func set_items() -> void:
	inventory.append(OBJ_Potion_Green.new(gp))
	inventory.append(OBJ_Kamibokken.new(gp))
	inventory.append(OBJ_Kami_Shield.new(gp))
	inventory.append(OBJ_Tent.new(gp))


func speak() -> void:
	# Some days the shop is shut - see assets/data/days/
	if not gp.today().shop_open:
		start_dialogue(self, 9)
		return

	start_dialogue(self, dialogue_set)
	gp.game_state = gp.TRADE_STATE
	gp.ui.npc = self
