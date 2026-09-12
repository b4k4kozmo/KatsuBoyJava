@tool
class_name NpcMarker
extends PlacementMarker
## A friendly character. Java equivalent: one entry in AssetSetter.setNPC().

@export_enum("OldMan", "NanaMan", "Merchant") var npc: String = "OldMan":
	set(value):
		npc = value
		refresh()

const PREVIEWS := {
	"OldMan": "oldman_down_01", "NanaMan": "nanaman_3", "Merchant": "kamimon_down_1",
}


func preview_texture() -> Texture2D:
	if PREVIEWS.has(npc):
		return load("res://assets/npc/%s.png" % PREVIEWS[npc])
	return null


func marker_color() -> Color:
	return Color(0.4, 0.9, 1)


func marker_label() -> String:
	return npc
