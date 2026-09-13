class_name MON_Boss
extends Entity
## A dungeon boss: the thing whose death clears a dungeon and opens the next
## route on the boat.
##
## Mechanically it is a monster with two extra jobs. The first time it dies it
## tells the quest log which dungeon is finished and stamps a boarding pass for
## the route it unlocks - which also puts that route on Kami Mart's shelf, so
## the player can go back later by buying a ticket like anyone else.
##
## Place one with a MonsterMarker set to "Boss" and fill in "Boss Dungeon Id"
## and "Reward Ticket" in the Inspector. Both come from your DungeonInfo files:
## the first is the id of the dungeon this boss sits in, the second the
## ticket_id of the route it opens up.
##
## It has two phases. Above half health it hangs back and shoots; below it, it
## charges. Override set_action() in a subclass for something more interesting.

const STATS := preload("res://assets/data/monsters/kamijack.tres")

## Which dungeon this boss guards, by DungeonInfo id. Set from the marker.
var dungeon_id: String = ""
## The route its death opens, by DungeonInfo ticket_id. Set from the marker.
var reward_ticket: String = ""

var _phase_two: bool = false


func _init(gp) -> void:
	super(gp)

	STATS.apply_to(self)

	# A boss should not die like a slime. Tune per boss in a subclass, or give
	# it its own .tres.
	max_life = STATS.max_life * 6
	life = max_life
	attack = STATS.attack * 2
	defense = STATS.defense + 2
	exp = STATS.exp_reward * 8
	name = "Boss"

	get_image()


func get_image() -> void:
	var s: int = gp.tile_size * 2
	up1 = setup("/monster/kamijack_down_1", s, s)
	up2 = setup("/monster/kamijack_down_2", s, s)
	down1 = up1
	down2 = up2
	left1 = up1
	left2 = up2
	right1 = up1
	right2 = up2


func set_action() -> void:

	# Half health flips it from keeping its distance to charging.
	if not _phase_two and life <= max_life / 2:
		_phase_two = true
		speed = maxi(speed + 1, 2)

	if _phase_two:
		# Chase, using the pathfinder the other monsters use.
		if gp.player != null:
			@warning_ignore("integer_division")
			var goal_col: int = gp.player.world_x / gp.tile_size
			@warning_ignore("integer_division")
			var goal_row: int = gp.player.world_y / gp.tile_size
			search_path(goal_col, goal_row)
		return

	action_lock_counter += 1
	if action_lock_counter >= 60:
		var i: int = randi() % 100 + 1
		if i < 25: direction = "up"
		elif i <= 50: direction = "down"
		elif i <= 75: direction = "left"
		else: direction = "right"
		action_lock_counter = 0


func damage_reaction() -> void:
	action_lock_counter = 0


## Death. This is where a dungeon actually gets marked off.
func check_drop() -> void:

	if gp.quest == null:
		drop_item(OBJ_Coin.worth(gp, randi_range(60, 90)))
		return

	# The first kill pays for the whole trip. Later ones still pay - a boss is
	# worth beating twice - but not enough to make farming it the best way to
	# earn a living.
	var first_time: bool = not gp.quest.is_cleared(_drop_dungeon_id())
	drop_item(OBJ_Coin.worth(gp,
			randi_range(60, 90) if first_time else randi_range(15, 25)))

	var id: String = _drop_dungeon_id()

	# Only the first kill counts. Bosses are rebuilt from their markers whenever
	# the map resets - resting at a healing pool does it - so without this the
	# same boss could be farmed for boarding passes.
	if not gp.quest.mark_cleared(id):
		return

	gp.ui.add_message("%s cleared!" % _dungeon_name(id))

	if gp.quest.grant_ticket(reward_ticket):
		var route := BoatService.by_id(gp.dungeons, reward_ticket)
		var route_name := route.display_name if route != null else reward_ticket
		gp.ui.add_message("Boat ticket: %s" % route_name)
		# Point the player at what they just unlocked.
		gp.quest.current_target = reward_ticket

	# Everything done means the way home is open, which the boat works out for
	# itself - this is just so the player hears about it.
	if gp.quest.all_cleared(gp.dungeons):
		gp.ui.add_message("The Wunderboat can take you home.")


## Which dungeon this death clears. Falls back to whichever one the boat
## dropped the player in, so a boss placed without an explicit id still works.
func _drop_dungeon_id() -> String:
	if not dungeon_id.is_empty():
		return dungeon_id
	return gp.current_dungeon_id


func _dungeon_name(id: String) -> String:
	var info := BoatService.by_id(gp.dungeons, id)
	return info.display_name if info != null else "The dungeon"
