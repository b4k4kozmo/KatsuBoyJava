class_name BoatService
extends RefCounted
## Works out where the boat will take you today.
##
## Pure logic on purpose - it takes a list of DungeonInfo, a QuestLog and a day
## number, and returns rows. It touches no nodes and no global state, which is
## why the test suite can check the whole timetable without running the game.

## Why a route is not available. Ordered by which reason to show when more than
## one applies: a player who is missing the ticket AND the story flag should be
## told about the story first.
enum Block {
	NONE,
	LOCKED,      ## an earlier dungeon has not been cleared
	NO_TICKET,   ## no ticket for this route
	NOT_TODAY,   ## the boat does not sail here on this day
	NOT_YET,     ## the victory route, before everything is cleared
}


## One row of the boat menu.
## { info: DungeonInfo, sailing: bool, block: Block, reason: String,
##   cleared: bool }
static func destinations(dungeons: Array, quest: QuestLog, day_index: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []

	for d in dungeons:
		if not (d is DungeonInfo) or d.id.is_empty():
			continue

		var block := Block.NONE

		if d.is_victory:
			# The way home only exists once the job is done.
			if not quest.all_cleared(dungeons):
				continue
			if not d.sails_on(day_index):
				block = Block.NOT_TODAY
		else:
			if not d.unlocked_by.is_empty() and not quest.is_cleared(d.unlocked_by):
				block = Block.LOCKED
			elif not quest.has_ticket(d.ticket_id):
				block = Block.NO_TICKET
			elif not d.sails_on(day_index):
				block = Block.NOT_TODAY

		rows.append({
			"info": d,
			"sailing": block == Block.NONE,
			"block": block,
			"reason": reason_text(d, block),
			"cleared": quest.is_cleared(d.id),
		})

	return rows


## A route the player cannot even see yet is left out of the menu entirely;
## everything else shows with a reason, so the timetable teaches itself.
static func reason_text(info: DungeonInfo, block: int) -> String:
	match block:
		Block.LOCKED:
			return "no charts yet"
		Block.NO_TICKET:
			if info.ticket_price > 0:
				return "ticket %d coins at Kami Mart" % info.ticket_price
			return "need a ticket"
		Block.NOT_TODAY:
			return "sails %s" % info.timetable_text()
		Block.NOT_YET:
			return "not yet"
	return ""


## Only the rows the boat will actually take you to, in menu order.
static func sailable(dungeons: Array, quest: QuestLog, day_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in destinations(dungeons, quest, day_index):
		if row["sailing"]:
			out.append(row)
	return out


## Look a dungeon up by id. Returns null if there is no such dungeon, which is
## what happens when a save mentions a dungeon that has since been removed.
static func by_id(dungeons: Array, id: String) -> DungeonInfo:
	for d in dungeons:
		if d is DungeonInfo and d.id == id:
			return d
	return null


## The soonest day this route runs, counting from today, or -1 if it never
## does. Lets an NPC say "come back Thursday" instead of listing a timetable.
static func next_sailing_day(info: DungeonInfo, day_index: int) -> int:
	for offset in range(7):
		if info.sails_on((day_index + offset) % 7):
			return (day_index + offset) % 7
	return -1
