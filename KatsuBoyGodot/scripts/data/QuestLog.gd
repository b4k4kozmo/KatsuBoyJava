class_name QuestLog
extends RefCounted
## What the player has done and what they are meant to do next.
##
## Deliberately small: three arrays and an integer. A game this size does not
## need an objective graph, and a flat list of cleared dungeon ids answers
## every question the boat, the NPCs and the ending need to ask.
##
## Saved and loaded by DataStorage / SaveLoad alongside level and coins.

## Ticket ids the player is carrying. A ticket is spent on nothing - holding it
## is what lets you board - so this only ever grows.
var tickets: Array[String] = []

## Dungeon ids whose boss is dead.
var cleared: Array[String] = []

## Which dungeon the player is currently pointed at, by id. Empty means "no
## particular objective", which is the state you are in before talking to
## anyone. Set by guide NPCs and when a boss dies.
var current_target: String = ""


func has_ticket(ticket_id: String) -> bool:
	return ticket_id.is_empty() or tickets.has(ticket_id)


## Returns false if they already had it, so callers can avoid a second
## "you got a ticket!" message.
func grant_ticket(ticket_id: String) -> bool:
	if ticket_id.is_empty() or tickets.has(ticket_id):
		return false
	tickets.append(ticket_id)
	return true


func is_cleared(dungeon_id: String) -> bool:
	return cleared.has(dungeon_id)


## Returns false if it was already cleared, so a boss cannot be farmed for the
## same reward twice.
func mark_cleared(dungeon_id: String) -> bool:
	if dungeon_id.is_empty() or cleared.has(dungeon_id):
		return false
	cleared.append(dungeon_id)
	return true


## Every dungeon that counts towards the ending: the real ones, not the home
## port and not the victory route.
static func countable(dungeons: Array) -> Array:
	var out: Array = []
	for d in dungeons:
		if d is DungeonInfo and not d.is_victory and not d.is_home_port and not d.id.is_empty():
			out.append(d)
	return out


func all_cleared(dungeons: Array) -> bool:
	var real := countable(dungeons)
	if real.is_empty():
		return false
	for d in real:
		if not is_cleared(d.id):
			return false
	return true


func cleared_count(dungeons: Array) -> int:
	var n := 0
	for d in countable(dungeons):
		if is_cleared(d.id):
			n += 1
	return n


## The line drawn on the pause screen. Picks the most useful thing to say
## rather than tracking a stage number, so it cannot fall out of step with what
## the player has actually done.
func objective_text(dungeons: Array) -> String:
	var real := countable(dungeons)
	if real.is_empty():
		return "Explore."

	if all_cleared(dungeons):
		return "Every dungeon is cleared. Take the boat home."

	# Whatever a guide last pointed at, if it is still outstanding.
	if not current_target.is_empty() and not is_cleared(current_target):
		for d in real:
			if d.id == current_target:
				if not has_ticket(d.ticket_id):
					return "Get a ticket to %s." % d.display_name
				return "Clear %s." % d.display_name

	# Otherwise the first dungeon that is actually reachable.
	for d in real:
		if is_cleared(d.id):
			continue
		if not d.unlocked_by.is_empty() and not is_cleared(d.unlocked_by):
			continue
		if not has_ticket(d.ticket_id):
			return "Get a ticket to %s." % d.display_name
		return "Clear %s." % d.display_name

	return "Ask around the port about the next route."


func to_dict() -> Dictionary:
	return {
		"tickets": tickets,
		"cleared": cleared,
		"current_target": current_target,
	}


func apply_dict(d: Dictionary) -> void:
	tickets.assign(_string_array(d.get("tickets", [])))
	cleared.assign(_string_array(d.get("cleared", [])))
	current_target = str(d.get("current_target", ""))


## Saves come back from disk as untyped Arrays, so coerce rather than assign.
static func _string_array(raw) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for v in raw:
			out.append(str(v))
	return out
