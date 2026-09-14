@icon("res://assets/tiles/wunderboat1.png")
class_name DungeonInfo
extends Resource
## One place the boat can take you.
##
## Make one .tres per destination in assets/data/dungeons/ and drop them into
## GamePanel's "Dungeons" list in the Inspector. Everything about a destination
## - which map it is, what it costs to reach, which days the boat sails there,
## what the NPCs hint about it - lives in the file, so adding a dungeon is
## filling in a form rather than editing code.
##
## See ROADMAP.md for the whole boat/ticket/quest picture.

enum Scale {
	MINI,   ## a handful of rooms, one gimmick, ten minutes
	MAJOR,  ## a real dungeon, close to world-map size, with a boss
}

## Stable key, used in save files and by the ticket and quest systems. Never
## rename one of these after a save exists - the save looks dungeons up by id.
## Lower case, no spaces: "mushroom_cave".
@export var id: String = ""

## What the boat menu and the NPCs call it.
@export var display_name: String = "New Dungeon"

## Index into GamePanel's "Map Scenes" list.
##
## Normally you never touch this. Put a DungeonMap script on the destination
## map's root node, drop THIS resource into its "Dungeon Info" slot, and the
## number is filled in at load time from wherever that scene sits in the list.
## Counting your way down a list of scenes to find that the cave is map 1 is
## exactly the kind of bookkeeping that goes wrong the first time somebody
## reorders it.
@export var map_index: int = 0

## The tile the player steps off the boat onto.
##
## Also filled in for you: it is wherever that map's Boat marker is. Move the
## dock in the editor and the boat follows it. These stay editable for a map
## with no DungeonMap root, which is the only case that still needs them typed.
@export var arrive_col: int = 50
@export var arrive_row: int = 50

@export var scale: Scale = Scale.MINI

## Which days the boat runs this route. Day 0 is Sunday, matching
## GameClock.DAY_NAMES. Leave every day ticked for a route with no timetable.
@export_flags("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
var sail_days: int = 127

## The ticket the player must hold. Usually the same string as `id`. Leave
## empty for a destination that needs no ticket at all, like the home port.
@export var ticket_id: String = ""

## What Kami Mart charges for that ticket. 0 means it is never for sale, so the
## only way to get it is whatever drops it.
@export var ticket_price: int = 0

## Is it on the shelf from the beginning? Leave this off for a route the player
## has to be given first: once they have held its ticket once, Kami Mart starts
## stocking it at `ticket_price` so they can go back.
@export var sold_from_start: bool = false

## The dungeon whose boss must be beaten before this route appears at all, by
## id. Empty means it is open from the start. Use this for the spine of the
## game; use tickets for the things a player can buy their way into.
@export var unlocked_by: String = ""

## Shown by guide NPCs and on the quest line. One sentence, in character.
@export_multiline var hint: String = ""

## The ending. The boat only offers this once every other dungeon is cleared,
## and arriving runs the victory screen rather than loading a map.
@export var is_victory: bool = false

## Home. Tick this for the port you start from: the boat will still sail there,
## but it is not a dungeon, so it has no boss and does not count towards the
## ending. Without it the game would wait forever for you to clear your own
## home town.
@export var is_home_port: bool = false


## Does the timetable include this day? day_index 0 = Sunday.
func sails_on(day_index: int) -> bool:
	return (sail_days & (1 << (day_index % 7))) != 0


## Human-readable timetable, for the boat menu: "Mon, Thu" or "every day".
func timetable_text() -> String:
	if sail_days & 127 == 127:
		return "every day"
	var short := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var days: Array[String] = []
	for i in range(7):
		if sails_on(i):
			days.append(short[i])
	if days.is_empty():
		return "never"
	return ", ".join(days)


func scale_text() -> String:
	return "mini" if scale == Scale.MINI else "major"
