@icon("res://assets/monster/slime_down01.png")
@tool
class_name MonsterMarker
extends PlacementMarker
## A monster spawn. Respawns here whenever the game resets the map
## (death, restart, or resting at the healing pool).
## Java equivalent: one entry in AssetSetter.setMonster().

@export_enum("Slime", "Snome", "Kamijack", "Shadow", "Boss") var monster: String = "Slime":
	set(value):
		monster = value
		refresh()

const PREVIEWS := {
	"Slime": "slime_down01", "Snome": "snome_down_1",
	"Kamijack": "kamijack_down_1", "Shadow": "shadowkatsu_down_1",
}


## Boss only. Which dungeon this boss guards, by DungeonInfo id - clearing it
## is what ticks the dungeon off in the quest log.
@export var boss_dungeon_id: String = "":
	set(value):
		boss_dungeon_id = value
		refresh()

## Boss only. The route its death opens, by DungeonInfo ticket_id. Leave empty
## for a boss that unlocks nothing.
@export var reward_ticket: String = "":
	set(value):
		reward_ticket = value
		refresh()


func preview_texture() -> Texture2D:
	if PREVIEWS.has(monster):
		return load("res://assets/monster/%s.png" % PREVIEWS[monster])
	return null


func marker_color() -> Color:
	return Color(1, 0.35, 0.4)


func marker_label() -> String:
	return monster
