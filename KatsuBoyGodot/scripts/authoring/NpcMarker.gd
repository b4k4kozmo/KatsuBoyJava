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

## Where he walks to after speaking. Drag the marker he should lead you to -
## the Boat dock's EventMarker, usually - and the tile is read off it, so
## moving the dock moves him with it.
@export var guide_target: NodePath:
	set(value):
		guide_target = value
		refresh()

## The tile he walks to, in map grid coordinates, for a destination that has no
## marker of its own. Ignored when Guide Target is set. -1 on either means he
## stays put and wanders as usual.
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


## The tile this NPC walks to, from whichever of the two ways it was set.
func guide_tile() -> Vector2i:
	if not guide_target.is_empty():
		var target: Node = get_node_or_null(guide_target)
		if target is PlacementMarker:
			return Vector2i(target.tile_col(), target.tile_row())
	return Vector2i(guide_col, guide_row)


func _get_configuration_warnings() -> PackedStringArray:

	var warnings := _placement_warnings()

	if not guide_target.is_empty() and not (get_node_or_null(guide_target) is PlacementMarker):
		warnings.append("Guide Target does not point at a marker any more.")

	if npc != "OldMan" and not guide_dungeon_id.is_empty():
		warnings.append("Only an OldMan leads anywhere. Guide Dungeon Id does "
				+ "nothing on a %s." % npc)

	var tile: Vector2i = guide_tile()
	if not guide_dungeon_id.is_empty() and tile.x < 0:
		warnings.append("He points at '%s' but has nowhere to walk. Drag a marker "
				% guide_dungeon_id + "into Guide Target so he can lead the way.")

	var map: DungeonMap = map_root()
	if map != null and tile.x >= 0 and map.tile_is_solid(tile.x, tile.y):
		warnings.append("He would walk to tile %d,%d, which is a wall." % [tile.x, tile.y])

	return warnings
