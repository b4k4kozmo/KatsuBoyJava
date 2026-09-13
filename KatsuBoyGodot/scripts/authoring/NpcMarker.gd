@icon("res://assets/npc/oldman_down_01.png")
@tool
class_name NpcMarker
extends PlacementMarker
## A friendly character. Java equivalent: one entry in AssetSetter.setNPC().

@export_enum("OldMan", "NanaMan", "Merchant", "TicketMan") var npc: String = "OldMan":
	set(value):
		npc = value
		refresh()

const PREVIEWS := {
	"OldMan": "oldman_down_01", "NanaMan": "nanaman_3", "Merchant": "kamimon_down_1",
	"TicketMan": "oldman_down_02",
}


## Guide behaviour. Leave these alone for an ordinary NPC.
##
## An OldMan with a "Guide Dungeon Id" becomes a signpost: talk to him and he
## tells you about that dungeon, sets it as your objective, and then walks to
## the tile below so you can follow him there. Point one at the boat dock and
## you have the "old man who walks to the boat" from the design notes.

## Which dungeon this NPC points you at, by DungeonInfo id. Empty means he just
## runs his normal dialogue and never leads anywhere.
@export var guide_dungeon_id: String = "":
	set(value):
		guide_dungeon_id = value
		refresh()

## The tile he walks to after speaking, in map grid coordinates. -1 on either
## means he stays put and wanders as usual. The boat dock on the world map is
## (87, 97).
@export var guide_col: int = -1:
	set(value):
		guide_col = value
		refresh()

@export var guide_row: int = -1:
	set(value):
		guide_row = value
		refresh()


func preview_texture() -> Texture2D:
	if PREVIEWS.has(npc):
		return load("res://assets/npc/%s.png" % PREVIEWS[npc])
	return null


func marker_color() -> Color:
	return Color(0.4, 0.9, 1)


func marker_label() -> String:
	if not guide_dungeon_id.is_empty():
		return "%s > %s" % [npc, guide_dungeon_id]
	return npc
