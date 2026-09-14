@icon("res://assets/tiles_interactive/drytree.png")
@tool
class_name InteractiveTileMarker
extends PlacementMarker
## A tile you can destroy, like the dry tree you chop with the axe.
## Java equivalent: one entry in AssetSetter.setInteractiveTile().

@export_enum("DryTree") var kind: String = "DryTree":
	set(value):
		kind = value
		refresh()

const PREVIEWS := {"DryTree": "drytree"}


func preview_texture() -> Texture2D:
	if PREVIEWS.has(kind):
		return load("res://assets/tiles_interactive/%s.png" % PREVIEWS[kind])
	return null


func marker_color() -> Color:
	return Color(0.7, 1, 0.5)


func marker_label() -> String:
	return kind


func _get_configuration_warnings() -> PackedStringArray:
	return _placement_warnings()
