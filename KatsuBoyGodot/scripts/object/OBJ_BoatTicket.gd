class_name OBJ_BoatTicket
extends Entity
## A boat ticket, as an inventory item.
##
## This exists so tickets can go through the shop and the loot system without
## either of them needing to know what a ticket is. The Merchant stocks it like
## any other item; a chest can hold it; a boss can drop it. Using it hands the
## ticket to the quest log, and the boat reads the quest log.
##
## One item covers every route: call configure() with a DungeonInfo and it
## becomes that route's ticket, taking its name and price from the file. That is
## how Kami Mart stocks tickets without anyone editing code when a dungeon is
## added - see NPC_Merchant.refresh_stock().
##
## The TICKET_ID / OBJ_NAME defaults below are what you get from an unconfigured
## one, so a chest or an ObjectMarker set to "Cave Ticket" still works.

## Which route an unconfigured ticket is for. Must match a DungeonInfo's
## ticket_id.
const TICKET_ID := "mushroom_cave"
const OBJ_NAME := "Cave Ticket"

## The route this particular copy is for. configure() changes it.
var route_id: String = TICKET_ID


func _init(gp) -> void:
	super(gp)

	type = TYPE_CONSUMABLE
	name = OBJ_NAME
	down1 = setup("/objects/key", gp.tile_size, gp.tile_size)
	_describe()
	price = 40
	stackable = false
	set_dialogue()


## Point this ticket at a route. Name, price and blurb all follow from the
## dungeon file, so a new destination needs no new item script.
func configure(info: DungeonInfo) -> void:
	route_id = info.ticket_id
	name = "%s Ticket" % info.display_name
	price = info.ticket_price
	_describe()


func _describe() -> void:
	description = "[" + name + "]\nPassage on the Wunderboat.\nUse it to keep it safe."


func set_dialogue() -> void:
	dialogues[0][0] = "The captain stamped your ticket.\nThe route is open."
	dialogues[1][0] = "You have already booked this one."


func use(_entity) -> bool:
	# Using a ticket does not consume it in any meaningful sense - it registers
	# the route with the quest log, which is what the boat checks. Returning
	# true lets the inventory remove the paper copy.
	if gp.quest == null:
		return false

	if gp.quest.grant_ticket(route_id):
		sound_number = 20
		set_sound()
		gp.play_se(SE.POWER_UP)
		start_dialogue(self, 0)
		return true

	start_dialogue(self, 1)
	return false
