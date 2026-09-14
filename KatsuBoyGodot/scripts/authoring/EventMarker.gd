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

@export_enum("DamagePit", "HealingPool", "Teleport", "ChangeMap", "Speak", "Boat")
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

## ChangeMap only: which map the door leads to. Drag the destination's .tscn
## straight in from the FileSystem dock and the map number is worked out for
## you at load time by looking it up in GamePanel's "Map Scenes" list.
##
## This is the whole reason Target Map below is usually left alone: counting
## your way down a list in the Inspector to find out that Shadow Deep is map 2
## is exactly the kind of bookkeeping that is wrong the moment someone inserts
## a map above it.
##
## It holds the PATH rather than the scene itself on purpose. Two maps with
## doors into each other would otherwise be two scenes that load each other,
## and Godot cannot open either of them.
@export_file("*.tscn") var target_scene: String:
	set(value):
		target_scene = value
		refresh()

## Where the player ends up. Used by Teleport (same map) and ChangeMap.
##
## Filled in from Target Scene when one is set, so leave it alone unless you
## are wiring a door by hand.
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

## Used by Boat: the dungeon id this dock belongs to. The route back to it is
## hidden while you are standing on it, so the boat never offers to take you
## where you already are. Leave empty for the home port.
@export var dock_of: String = ""


func marker_color() -> Color:
	match kind:
		"DamagePit": return Color(1, 0.3, 0.3)
		"HealingPool": return Color(0.4, 1, 0.6)
		"Teleport": return Color(0.8, 0.5, 1)
		"ChangeMap": return Color(1, 0.6, 0.2)
		"Speak": return Color(0.5, 0.8, 1)
		"Boat": return Color(0.35, 0.75, 0.95)
	return Color(1, 1, 1)


func marker_label() -> String:
	match kind:
		"Teleport": return "Teleport -> %d,%d" % [target_col, target_row]
		"ChangeMap":
			var where: String = ("map %d" % target_map if target_scene.is_empty()
					else target_scene.get_file().get_basename())
			return "ChangeMap -> %s @ %d,%d" % [where, target_col, target_row]
		"Speak": return "Speak"
		"Boat": return "Boat dock" if dock_of.is_empty() else "Boat dock (%s)" % dock_of
	return kind


func _get_configuration_warnings() -> PackedStringArray:

	var warnings := _placement_warnings()

	if kind == "Speak" and speak_npc.is_empty():
		warnings.append("Speak events need an NpcMarker in 'Speak Npc'.")

	if kind == "ChangeMap" and target_scene.is_empty():
		warnings.append("No Target Scene, so this door uses map number %d - "
				% target_map
				+ "which points somewhere else the moment the map list changes. "
				+ "Drag the destination .tscn in instead.")

	if kind == "Boat" and dock_of.is_empty():
		var map: DungeonMap = map_root()
		if map != null and map.dungeon_info != null:
			warnings.append("Dock Of is empty. This map is '%s' - put that here, "
					% map.dungeon_info.id
					+ "or the boat will offer to sail you where you already are.")

	return warnings
