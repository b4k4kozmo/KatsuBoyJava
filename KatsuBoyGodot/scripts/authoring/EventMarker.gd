@icon("res://assets/objects/door.png")
@tool
class_name EventMarker
extends PlacementMarker
## Something that happens when the player steps on a tile: a trap, a save
## point, a teleporter, or the doorway between two maps.
## Java equivalent: one line of EventHandler.checkEvent().
##
## Markers are checked in tree order and the FIRST one the player is touching
## wins, so if two overlap, the one higher up in the scene tree takes priority.

@export_enum("DamagePit", "HealingPool", "Teleport", "ChangeMap", "Speak")
var kind: String = "Teleport":
	set(value):
		kind = value
		refresh()

## The player must be walking this way for the event to fire.
## "any" fires no matter which way they face.
@export_enum("any", "up", "down", "left", "right")
var required_direction: String = "any":
	set(value):
		required_direction = value
		refresh()

## Where the player ends up. Used by Teleport (same map) and ChangeMap.
@export var target_map: int = 0:
	set(value):
		target_map = value
		refresh()
@export var target_col: int = 0:
	set(value):
		target_col = value
		refresh()
@export var target_row: int = 0:
	set(value):
		target_row = value
		refresh()

## Used by Speak - drag the NpcMarker of the character to talk to.
@export var speak_npc: NodePath


func marker_color() -> Color:
	match kind:
		"DamagePit": return Color(1, 0.3, 0.3)
		"HealingPool": return Color(0.4, 1, 0.6)
		"Teleport": return Color(0.8, 0.5, 1)
		"ChangeMap": return Color(1, 0.6, 0.2)
		"Speak": return Color(0.5, 0.8, 1)
	return Color(1, 1, 1)


func marker_label() -> String:
	match kind:
		"Teleport": return "Teleport -> %d,%d" % [target_col, target_row]
		"ChangeMap": return "ChangeMap -> map %d @ %d,%d" % [target_map, target_col, target_row]
		"Speak": return "Speak"
	return kind


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if kind == "Speak" and speak_npc.is_empty():
		warnings.append("Speak events need an NpcMarker in 'Speak Npc'.")
	if kind == "ChangeMap":
		warnings.append_array(PackedStringArray())
	return warnings
