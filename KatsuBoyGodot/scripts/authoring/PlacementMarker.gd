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


func refresh() -> void:
	if not is_inside_tree():
		return
	queue_redraw()
	update_configuration_warnings()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var tex: Texture2D = preview_texture()
	if tex != null:
		draw_texture_rect(tex, Rect2(0, 0, TILE, TILE), false)
	draw_rect(Rect2(0, 0, TILE, TILE), marker_color(), false, 2.0)

	var label: String = marker_label()
	if label != "":
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(0, TILE + 14), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, marker_color())
