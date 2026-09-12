@tool
class_name MonsterMarker
extends PlacementMarker
## A monster spawn. Respawns here whenever the game resets the map
## (death, restart, or resting at the healing pool).
## Java equivalent: one entry in AssetSetter.setMonster().

@export_enum("Slime", "Snome", "Kamijack", "Shadow") var monster: String = "Slime":
	set(value):
		monster = value
		refresh()

const PREVIEWS := {
	"Slime": "slime_down01", "Snome": "snome_down_1",
	"Kamijack": "kamijack_down_1", "Shadow": "shadowkatsu_down_1",
}


func preview_texture() -> Texture2D:
	if PREVIEWS.has(monster):
		return load("res://assets/monster/%s.png" % PREVIEWS[monster])
	return null


func marker_color() -> Color:
	return Color(1, 0.35, 0.4)


func marker_label() -> String:
	return monster
