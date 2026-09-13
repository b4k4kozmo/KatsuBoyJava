class_name NPC_TicketMan
extends Entity
## The ticket collector who stands at the boat dock.
##
## He is the only way a paper ticket becomes passage. Buy a ticket at Kami Mart
## or take one off a boss, walk it down to the dock, and talk to him: he takes
## the ticket and stamps you for one trip. Selecting the ticket in the inventory
## does nothing wherever you are standing, which is the point - the journey
## starts at the quay, not in your bag.
##
## Place him with an NpcMarker set to "TicketMan", on the tile between the
## shore and the dock so the player has to deal with him on the way past.
##
## He is drawn with the old man's sprites because they are the only four-way
## set in the project; give him his own art and only get_image() changes.

const STAMPED_SET := 1
const NOTHING_TO_STAMP := 0
const ALREADY_STAMPED := 2


func _init(gp) -> void:
	super(gp)

	name = "Ticket Collector"
	direction = "down"
	speed = 0            # he has stood here for thirty years

	solid_area = Rect.new()
	solid_area.x = 8
	solid_area.y = 16
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
	solid_area.width = 28
	solid_area.height = 28

	sound_number = 18

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
	dialogues[NOTHING_TO_STAMP][0] = "No ticket, no boat.\nThat's the whole job, son."
	dialogues[ALREADY_STAMPED][0] = "You're stamped. Mind the gap."


## He stands where he is put.
func set_action() -> void:
	action_lock_counter = 0


func speak() -> void:

	set_sound()
	face_player()

	if gp.quest == null:
		start_dialogue(self, NOTHING_TO_STAMP)
		return

	var index: int = _ticket_in_bag()

	if index >= 0:
		var ticket = gp.player.inventory[index]
		var route: String = ticket.route_id
		gp.player.inventory.remove_at(index)
		gp.quest.grant_ticket(route)
		gp.play_se(SE.UNLOCK)
		_write_stamped_line(route)
		start_dialogue(self, STAMPED_SET)
		return

	if _any_pass():
		start_dialogue(self, ALREADY_STAMPED)
		return

	_write_refusal()
	start_dialogue(self, NOTHING_TO_STAMP)


## The first boat ticket in the player's bag, or -1.
func _ticket_in_bag() -> int:
	for i in range(gp.player.inventory.size()):
		if gp.player.inventory[i] is OBJ_BoatTicket:
			return i
	return -1


func _any_pass() -> bool:
	for route in gp.quest.passes.keys():
		if gp.quest.passes[route] > 0:
			return true
	return false


## What he says when he takes one. Built from the dungeon file so the timetable
## he quotes is the timetable the boat actually keeps.
func _write_stamped_line(route: String) -> void:

	var info: DungeonInfo = BoatService.by_id(gp.dungeons, route)
	if info == null:
		dialogues[STAMPED_SET][0] = "Stamped. Don't lose it twice."
		dialogues[STAMPED_SET][1] = null
		return

	dialogues[STAMPED_SET][0] = "Stamped. One trip to %s." % info.display_name
	dialogues[STAMPED_SET][1] = "She sails %s.\nBoard at the end of the pier." % info.timetable_text()
	dialogues[STAMPED_SET][2] = null


## Point an empty-handed player at wherever the next ticket comes from.
func _write_refusal() -> void:

	dialogues[NOTHING_TO_STAMP][0] = "No ticket, no boat.\nThat's the whole job, son."
	dialogues[NOTHING_TO_STAMP][1] = null

	for d in gp.dungeons:
		if not (d is DungeonInfo) or d.is_victory or d.is_home_port:
			continue
		if gp.quest.is_cleared(d.id):
			continue
		if not d.unlocked_by.is_empty() and not gp.quest.is_cleared(d.unlocked_by):
			continue
		if d.ticket_price > 0 and (d.sold_from_start or gp.quest.is_known(d.ticket_id)):
			dialogues[NOTHING_TO_STAMP][1] = "Kami Mart sells passage to\n%s. %d coins." % [
					d.display_name, d.ticket_price]
		else:
			dialogues[NOTHING_TO_STAMP][1] = "Passage to %s isn't sold.\nSomeone out there is holding it." % d.display_name
		return
