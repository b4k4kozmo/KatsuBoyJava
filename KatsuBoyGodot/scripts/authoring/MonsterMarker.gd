@icon("res://assets/monster/slime_down01.png")
@tool
class_name MonsterMarker
extends PlacementMarker
## A monster spawn. Respawns here whenever the game resets the map
## (death, restart, or resting at the healing pool).
## Java equivalent: one entry in AssetSetter.setMonster().
##
## Two ways to fill one in:
##
##   * Pick one of the named monsters. It brings its own art, behaviour and
##     drop table from scripts/monster/, and the Stats slot below can retune
##     its numbers for this one placement - a tougher Slime at the back of a
##     dungeon without a second Slime script.
##   * Pick "From Stats" and drag a MonsterStats resource in. That resource IS
##     the monster: its art, how it behaves and what it drops. No code at all.

@export_enum("Slime", "Snome", "Kamijack", "Shadow", "Boss", "From Stats")
var monster: String = "Slime":
	set(value):
		monster = value
		refresh()

const PREVIEWS := {
	"Slime": "slime_down01", "Snome": "snome_down_1",
	"Kamijack": "kamijack_down_1", "Shadow": "shadowkatsu_down_1",
}


## The numbers, and for "From Stats" the whole monster. Drag one in from
## assets/data/monsters/.
##
## For a named monster this is an override: leave it empty and the monster uses
## its own sheet. For a Boss it is close to required - the fallback is a beefed
## up Kamijack, which is fine as a placeholder and wrong for a real fight,
## because a boss wants its life and damage tuned against the level the player
## reaches it at.
@export var stats: MonsterStats:
	set(value):
		stats = value
		refresh()

@export_group("Boss")
## Which dungeon this boss guards, by DungeonInfo id - clearing it is what
## ticks the dungeon off in the quest log.
@export var boss_dungeon_id: String = "":
	set(value):
		boss_dungeon_id = value
		refresh()

## The route its death opens, by DungeonInfo ticket_id. Leave empty for a boss
## that unlocks nothing.
@export var reward_ticket: String = "":
	set(value):
		reward_ticket = value
		refresh()


func preview_texture() -> Texture2D:
	if monster == "From Stats":
		if stats != null and stats.frames_down.size() > 0:
			return stats.frames_down[0]
		return null
	if PREVIEWS.has(monster):
		return load("res://assets/monster/%s.png" % PREVIEWS[monster])
	return null


## How much floor this monster needs. Taken from its stat sheet where there is
## one, and from the built-in monster otherwise - a Kamijack is two tiles across
## whether or not anybody dropped a resource on it.
func marker_tiles() -> int:
	if stats != null:
		return stats.sprite_scale
	if monster == "Kamijack" or monster == "Boss":
		return 2
	return 1


func marker_color() -> Color:
	return Color(1, 0.35, 0.4)


func marker_label() -> String:
	if monster == "From Stats":
		if stats == null:
			return "From Stats (empty!)"
		return stats.display_name if stats.display_name != "" else stats.resource_path.get_file()
	return monster


func _get_configuration_warnings() -> PackedStringArray:

	var warnings := _placement_warnings()

	if monster == "From Stats":
		if stats == null:
			warnings.append("Monster is 'From Stats' but the Stats slot is empty. "
					+ "Drag a MonsterStats resource in, or pick a named monster.")
		elif not stats.has_art():
			warnings.append("%s has no Frames Down, so it would be invisible. "
					% stats.resource_path.get_file()
					+ "Drop two PNGs into its Looks group.")

	if monster == "Boss":
		if boss_dungeon_id.is_empty():
			warnings.append("A boss with no Boss Dungeon Id never ticks a dungeon "
					+ "off the quest log. Put the DungeonInfo's id here.")
		if stats == null:
			warnings.append("No Stats: this boss falls back to a beefed up Kamijack. "
					+ "Fine for now, wrong for a real fight.")

	return warnings
