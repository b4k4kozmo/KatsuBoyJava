class_name NPC_Merchant
extends Entity
## Java: entity/NPC_Merchant.java


func _init(gp) -> void:
	super(gp)

	direction = "down"
	speed = 1

	solid_area = Rect.new()
	solid_area.x = 12
	solid_area.y = 20
	solid_area.width = 24
	solid_area.height = 26
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
	refresh_stock()


## Replace the shelf with a list of ItemStats from the marker, so what the shop
## sells is a field in the Inspector rather than the four lines above. Called
## by AssetSetter when the marker's Shop Stock has anything in it.
func stock_from(sheets: Array) -> void:

	inventory.clear()
	for sheet in sheets:
		if sheet is ItemStats:
			inventory.append(OBJ_Custom.new(gp, sheet))
	refresh_stock()


## Boat tickets are stocked from the dungeon files rather than listed here, so
## adding a destination with a ticket_price puts it on the shelf by itself.
##
## A ticket is good for one trip, so the shelf is never emptied by owning one -
## it is a ferry office, it keeps selling tickets. What does gate the shelf is
## whether the route is public: a dungeon marked "sold from start" is on sale
## immediately, and anything else appears only once the player has held one of
## its tickets, which is usually the one a boss handed over.
func refresh_stock() -> void:

	for i in range(inventory.size() - 1, -1, -1):
		if inventory[i] is OBJ_BoatTicket:
			inventory.remove_at(i)

	if gp.quest == null:
		return

	for d in gp.dungeons:
		if not (d is DungeonInfo) or d.is_victory or d.is_home_port:
			continue
		if d.ticket_price <= 0 or d.ticket_id.is_empty():
			continue
		if not d.sold_from_start and not gp.quest.is_known(d.ticket_id):
			continue
		# A route whose charts are not drawn yet is not on sale either, so the
		# shop never spoils what is coming.
		if not d.unlocked_by.is_empty() and not gp.quest.is_cleared(d.unlocked_by):
			continue
		var ticket := OBJ_BoatTicket.new(gp)
		ticket.configure(d)
		inventory.append(ticket)


func speak() -> void:
	# Some days the shop is shut - see assets/data/days/
	if not gp.today().shop_open:
		start_dialogue(self, 9)
		return

	# Re-shelve before opening so the tickets match what the player needs now.
	refresh_stock()

	start_dialogue(self, dialogue_set)
	gp.game_state = gp.TRADE_STATE
	gp.ui.npc = self
