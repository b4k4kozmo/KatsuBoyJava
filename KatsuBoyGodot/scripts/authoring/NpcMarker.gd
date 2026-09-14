@icon("res://assets/npc/oldman_down_01.png")
@tool
class_name NpcMarker
extends PlacementMarker
## A friendly character. Java equivalent: one entry in AssetSetter.setNPC().
##
## Two ways to fill one in:
##
##   * Pick a named character. Those four have scripts, because each of them
##     does something: the merchant opens a shop, the collector takes tickets,
##     the old man walks you to the boat.
##   * Pick "From Stats" and drag an NpcProfile in. That resource IS the
##     character - their art, how they wander, every line they say, and an item
##     they hand over the first time you talk to them. No code at all.

@export_enum("OldMan", "NanaMan", "Merchant", "TicketMan", "From Stats")
var npc: String = "OldMan":
	set(value):
		npc = value
		refresh()

const PREVIEWS := {
	"OldMan": "oldman_down_01", "NanaMan": "nanaman_3", "Merchant": "kamimon_down_1",
	"TicketMan": "oldman_down_02",
}


## The character, when Npc is "From Stats". Drag one in from assets/data/npcs/.
@export var profile: NpcProfile:
	set(value):
		profile = value
		refresh()

## Merchant only: what is on the shelf, as ItemStats resources. Leave it empty
## and the shop keeps its built-in stock - a potion, a bokken, a shield and a
## tent. Boat tickets are added on top either way, from the dungeon files.
@export var shop_stock: Array[ItemStats]:
	set(value):
		shop_stock = value
		refresh()

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
	if npc == "From Stats":
		if profile != null and profile.frames_down.size() > 0:
			return profile.frames_down[0]
		return null
	if PREVIEWS.has(npc):
		return load("res://assets/npc/%s.png" % PREVIEWS[npc])
	return null


func marker_color() -> Color:
	return Color(0.4, 0.9, 1)


func marker_label() -> String:
	if npc == "From Stats":
		if profile == null:
			return "From Stats (empty!)"
		return "%s (%d talks)" % [profile.display_name, profile.spoken_sets()]
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

	if npc == "From Stats":
		if profile == null:
			warnings.append("Npc is 'From Stats' but the Profile slot is empty. "
					+ "Drag an NpcProfile in, or pick a named character.")
		else:
			if not profile.has_art():
				warnings.append("%s has no Frames Down, so they would be invisible. "
						% profile.display_name
						+ "Drop two PNGs into the profile's Looks group.")
			if profile.spoken_sets() == 0:
				warnings.append("%s has nothing to say. Add a conversation to the "
						% profile.display_name + "profile, or they are just scenery.")

	if npc != "Merchant" and not shop_stock.is_empty():
		warnings.append("Only the Merchant runs a shop. Shop Stock does nothing "
				+ "on a %s." % npc)

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
