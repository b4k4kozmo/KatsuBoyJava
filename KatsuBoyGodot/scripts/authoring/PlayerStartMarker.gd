@tool
class_name PlayerStartMarker
extends PlacementMarker
## Where Katsu Boy appears on a new game, and where he respawns after dying.
##
## Put exactly one of these in one map scene, anywhere in the tree. If there
## isn't one, the game falls back to tile 94,94 on map 0 (the original spot).


func preview_texture() -> Texture2D:
	return load("res://assets/player/boy_down_1.png")


func marker_color() -> Color:
	return Color(1, 1, 1)


func marker_label() -> String:
	return "Player start"
