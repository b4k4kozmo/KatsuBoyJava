class_name QuestLog
extends RefCounted
## What the player has done and what they are meant to do next.
##
## Deliberately small: three arrays and an integer. A game this size does not
## need an objective graph, and a flat list of cleared dungeon ids answers
## every question the boat, the NPCs and the ending need to ask.
##
## Saved and loaded by DataStorage / SaveLoad alongside level and coins.

## Boarding passes: route id -> how many trips the collector has stamped you
## for. A pass is spent when the boat leaves, so this goes down as well as up.
##
## A paper ticket in the inventory is NOT a pass. The ticket is the thing you
## buy and carry; the pass is what you get when the collector at the dock takes
## it off you. That split is what stops a ticket being "used" from the menu in
## the middle of a dungeon.
var passes: Dictionary = {}

## Routes the player has ever held a ticket for. Kami Mart starts stocking a
## route once you have had its ticket once, so a route a boss opened up can be
## bought again afterwards.
var known: Array[String] = []

## Dungeon ids whose boss is dead.
var cleared: Array[String] = []

## Which dungeon the player is currently pointed at, by id. Empty means "no
## particular objective", which is the state you are in before talking to
## anyone. Set by guide NPCs and when a boss dies.
var current_target: String = ""


## Can the player board this route right now? A route with no ticket id - the
## home port, the way home at the end - is always free.
func has_ticket(ticket_id: String) -> bool:
	return ticket_id.is_empty() or passes.get(ticket_id, 0) > 0


func pass_count(ticket_id: String) -> int:
	return passes.get(ticket_id, 0)


## Stamp a boarding pass. Called by the ticket collector when he takes a paper
## ticket, and by a boss handing over the route it guards.
## Returns false only for a route with no ticket id.
func grant_ticket(ticket_id: String) -> bool:
	if ticket_id.is_empty():
		return false
	passes[ticket_id] = passes.get(ticket_id, 0) + 1
	mark_known(ticket_id)
	return true


## Use up one trip. Returns false when there was nothing to spend, which is how
## the boat refuses to sail.
func spend_pass(ticket_id: String) -> bool:
	if ticket_id.is_empty():
		return true          # the home port and the ending cost nothing
	var left: int = passes.get(ticket_id, 0)
	if left <= 0:
		return false
	if left == 1:
		passes.erase(ticket_id)
	else:
		passes[ticket_id] = left - 1
	return true


## "You have held one of these before", which is what puts it on Kami Mart's
## shelf for good.
func mark_known(ticket_id: String) -> void:
	if not ticket_id.is_empty() and not known.has(ticket_id):
		known.append(ticket_id)


func is_known(ticket_id: String) -> bool:
	return known.has(ticket_id)


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
func objective_text(dungeons: Array, carried: Array = []) -> String:
	var real := countable(dungeons)
	if real.is_empty():
		return "Explore."

	if all_cleared(dungeons):
		return "Every dungeon is cleared. Take the boat home."

	# Whatever a guide last pointed at, if it is still outstanding.
	if not current_target.is_empty() and not is_cleared(current_target):
		for d in real:
			if d.id == current_target:
				return _next_step(d, carried)

	# Otherwise the first dungeon that is actually reachable.
	for d in real:
		if is_cleared(d.id):
			continue
		if not d.unlocked_by.is_empty() and not is_cleared(d.unlocked_by):
			continue
		return _next_step(d, carried)

	return "Ask around the port about the next route."


## The one useful sentence about a dungeon that is not cleared yet. `carried` is
## the routes the player has paper tickets for, so somebody holding a ticket is
## sent to the collector rather than back to the shop.
func _next_step(d: DungeonInfo, carried: Array) -> String:
	if has_ticket(d.ticket_id):
		return "Clear %s." % d.display_name
	if carried.has(d.ticket_id):
		return "Take your %s ticket to the collector." % d.display_name
	return "Get a ticket to %s." % d.display_name


func to_dict() -> Dictionary:
	return {
		"passes": passes,
		"known": known,
		"cleared": cleared,
		"current_target": current_target,
	}


func apply_dict(d: Dictionary) -> void:
	passes = {}
	var raw_passes = d.get("passes", {})
	if raw_passes is Dictionary:
		for key in raw_passes.keys():
			var n := int(raw_passes[key])
			if n > 0:
				passes[str(key)] = n

	known.assign(_string_array(d.get("known", [])))

	# Saves written before tickets were spendable stored a flat list of routes
	# you held. Read them as one trip each, and as routes you have seen.
	for route in _string_array(d.get("tickets", [])):
		if not passes.has(route):
			passes[route] = 1
		mark_known(route)

	cleared.assign(_string_array(d.get("cleared", [])))
	current_target = str(d.get("current_target", ""))


## Saves come back from disk as untyped Arrays, so coerce rather than assign.
static func _string_array(raw) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for v in raw:
			out.append(str(v))
	return out
