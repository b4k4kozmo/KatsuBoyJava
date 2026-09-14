@tool
class_name PlacementMarker
extends Node2D
## Base class for everything you place on a map by hand in the Godot editor.
##
## A marker is EDITOR-ONLY furniture. At run time AssetSetter walks the map
## scene, reads each marker's kind and grid position, and creates the real
## RefCounted entity for it - the marker itself never draws in game.
##
## Drop one under the matching group node in a map scene (Objects / NPCs /
## Monsters / InteractiveTiles / Events), pick what it is in the Inspector, and
## drag it onto a tile. Turn on grid snapping (48 px) to keep it aligned.

const TILE := 48


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false


## Sprite shown in the editor so you can see what you are placing.
func preview_texture() -> Texture2D:
	return null


## Outline colour, and the fallback box when there is no preview sprite.
func marker_color() -> Color:
	return Color(1, 1, 1)


## What this marker is, for the label under it in the editor.
func marker_label() -> String:
	return ""


## How many tiles across and down the thing this marker places is. A Kamijack
## is 2. The outline in the editor is drawn at this size, so what you see on
## the map is the space the monster will actually take up.
func marker_tiles() -> int:
	return 1


## Position within the map, in pixels.
##
## NOT global_position: at run time the map scenes live under GamePanel/World,
## which is scrolled to follow the player, so global_position moves every frame.
## Measuring against the map's own root keeps this stable, and lets you nest
## markers under sub-groups (a "Dungeon/Room1" node, say) without breaking them.
func map_position() -> Vector2:
	var root: Node = owner
	if root is Node2D:
		return global_position - (root as Node2D).global_position
	return position


## Grid position. AssetSetter and EventHandler use these, so a marker that is
## not snapped to the 48 px grid still lands on a whole tile.
func tile_col() -> int:
	return int(round(map_position().x / TILE))


func tile_row() -> int:
	return int(round(map_position().y / TILE))


## The DungeonMap this marker belongs to, if the map's root has the script on
## it. Markers use it to ask questions about the map around them - is this tile
## a wall, is something else already standing here.
func map_root() -> DungeonMap:
	var root: Node = owner if owner != null else get_parent()
	while root != null:
		if root is DungeonMap:
			return root
		root = root.get_parent()
	return null


## Is this marker sitting neatly on a tile, or a few pixels off it?
##
## Being off-grid is not fatal - tile_col() rounds - but it means what you see
## in the editor is not quite where the thing lands, and two markers that look
## like neighbours can turn out to share a tile. Turn on snapping (Godot's grid
## snap, set to 48 px) and this never comes up.
func is_on_grid() -> bool:
	var pos: Vector2 = map_position()
	return int(pos.x) % TILE == 0 and int(pos.y) % TILE == 0


## Move to the middle of the tile this marker is nearest.
func snap_to_grid() -> void:
	var pos: Vector2 = map_position()
	position += Vector2(tile_col() * TILE - pos.x, tile_row() * TILE - pos.y)
	refresh()


## The warnings every marker shares: off the grid, in a wall, or stacked on
## something solid. Subclasses call this first and add their own.
##
## All three are things that load fine and then do not work, which is the worst
## kind of mistake to make in a level editor: the map opens, the game runs, and
## the chest is simply unreachable.
func _placement_warnings() -> PackedStringArray:

	var out := PackedStringArray()

	if not is_on_grid():
		out.append("Not on the 48 px grid - it will snap to tile %d,%d at run time. "
				% [tile_col(), tile_row()]
				+ "Use the map's 'Tidy up' button, or turn on grid snapping.")

	var map: DungeonMap = map_root()
	if map == null:
		return out

	# Everything below is checked over the whole footprint, not just the corner
	# tile. A two-tile monster with its head in open floor and its body in a
	# wall looks fine in the editor and cannot move at run time.
	var span: int = maxi(marker_tiles(), 1)

	for dx in range(span):
		for dy in range(span):
			var col: int = tile_col() + dx
			var row: int = tile_row() + dy
			if map.tile_is_solid(col, row):
				if span == 1:
					out.append("Tile %d,%d is a wall. Nothing can reach this."
							% [col, row])
				else:
					out.append("This is %d tiles across and tile %d,%d is a wall."
							% [span, col, row])
				break

	var clash := false
	for dx in range(span):
		for dy in range(span):
			for other in map.markers_on_tile(tile_col() + dx, tile_row() + dy):
				if other == self or clash:
					continue
				if map.is_solid_marker(other) or map.is_solid_marker(self):
					out.append("Sharing tile %d,%d with %s, and one of them blocks the way."
							% [tile_col() + dx, tile_row() + dy, other.name])
					clash = true

	return out


func refresh() -> void:
	if not is_inside_tree():
		return
	queue_redraw()
	update_configuration_warnings()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var span: int = TILE * maxi(marker_tiles(), 1)

	var tex: Texture2D = preview_texture()
	if tex != null:
		draw_texture_rect(tex, Rect2(0, 0, span, span), false)
	draw_rect(Rect2(0, 0, span, span), marker_color(), false, 2.0)

	# A big thing also gets its own tile picked out, so it is obvious which
	# square you actually placed it on.
	if span > TILE:
		draw_rect(Rect2(0, 0, TILE, TILE), marker_color() * Color(1, 1, 1, 0.45),
				false, 1.0)

	var label: String = marker_label()
	if label != "":
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(0, span + 14), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, marker_color())
