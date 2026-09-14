class_name AssetSetter
extends RefCounted
## Java: main/AssetSetter.java
##
## Java listed every object, NPC and monster in code. Now each one is a marker
## node you place in a map scene (scenes/maps/*.tscn), and this walks those
## scenes and builds the real entities from them.
##
## To add something to a map: open the map scene, add the matching marker under
## Objects / NPCs / Monsters / InteractiveTiles, pick what it is in the
## Inspector, drag it onto a tile. Nothing here needs changing.

var gp

## Which entity came from which NpcMarker, so Speak events can find their NPC.
var npc_by_marker: Dictionary = {}


func _init(gp) -> void:
	self.gp = gp


## The marker nodes under one group of one map, e.g. markers(0, "Monsters").
##
## Looks all the way down, not just at the group's own children, so a big map
## can sort its markers into sub-nodes - "Monsters/Upper Floor", "Objects/Room
## 3" - the way you would sort anything else with a hundred items in it. Tree
## order is preserved, which matters for Events: the first one the player is
## touching wins.
func markers(map_num: int, group_name: String) -> Array:
	if map_num < 0 or map_num >= gp.map_node.size() or gp.map_node[map_num] == null:
		return []
	var group: Node = gp.map_node[map_num].get_node_or_null(group_name)
	if group == null:
		return []
	var out: Array = []
	_gather(group, out)
	return out


func _gather(node: Node, out: Array) -> void:
	for child in node.get_children():
		out.append(child)
		if child.get_child_count() > 0:
			_gather(child, out)


## Blank out the slots nothing was placed in, so a respawn or a restart does not
## leave the previous run's entities behind.
func _clear_rest(array: Array, map_num: int, from: int) -> void:
	var i := from
	while i < array[map_num].size():
		array[map_num][i] = null
		i += 1


func _place(entity: Entity, marker) -> void:
	entity.world_x = marker.tile_col() * gp.tile_size
	entity.world_y = marker.tile_row() * gp.tile_size


## Where the player starts: Vector3i(map, col, row).
## Looks for a PlayerStartMarker anywhere in any map scene; falls back to the
## original hardcoded spot when there isn't one.
func player_start() -> Vector3i:

	for map_num in range(gp.map_node.size()):
		if gp.map_node[map_num] == null:
			continue
		var found: PlayerStartMarker = _find_player_start(gp.map_node[map_num])
		if found != null:
			return Vector3i(map_num, found.tile_col(), found.tile_row())

	return Vector3i(0, 94, 94)


## Somewhere sensible to stand on a given map: its PlayerStartMarker if it has
## one, otherwise the first tile a marker sits on, otherwise the middle.
func player_start_on(map_num: int) -> Vector2i:

	if map_num < gp.map_node.size() and gp.map_node[map_num] != null:
		var found := _find_player_start(gp.map_node[map_num])
		if found != null:
			return Vector2i(found.tile_col(), found.tile_row())
		for group_name in ["NPCs", "Objects", "Monsters", "Events"]:
			for m in markers(map_num, group_name):
				if m is PlacementMarker:
					return Vector2i(m.tile_col(), m.tile_row() + 1)

	@warning_ignore("integer_division")
	return Vector2i(gp.max_world_col / 2, gp.max_world_row / 2)


func _find_player_start(node: Node) -> PlayerStartMarker:
	if node is PlayerStartMarker:
		return node as PlayerStartMarker
	for child in node.get_children():
		var found: PlayerStartMarker = _find_player_start(child)
		if found != null:
			return found
	return null


func set_object() -> void:

	for map_num in range(gp.max_map):
		var i := 0
		for m in markers(map_num, "Objects"):
			if not (m is ObjectMarker):
				continue
			if i >= gp.obj[map_num].size():
				push_warning("Map %d has more objects than slots (%d)." % [map_num, gp.obj[map_num].size()])
				break
			var entity: Entity = gp.e_generator.get_object(m.item, m.item_stats)
			if entity == null:
				push_warning("Unknown object '%s' on map %d." % [m.item, map_num])
				continue
			if m.item == OBJ_Chest.OBJ_NAME:
				var loot: Entity = gp.e_generator.get_object(
						m.chest_loot, m.chest_loot_stats)
				if loot is OBJ_Coin:
					loot.set_value(m.coin_value)
				entity.set_loot(loot)
			elif entity is OBJ_Coin:
				entity.set_value(m.coin_value)
			_place(entity, m)
			gp.obj[map_num][i] = entity
			i += 1
		_clear_rest(gp.obj, map_num, i)


func set_npc() -> void:

	npc_by_marker.clear()

	for map_num in range(gp.max_map):
		var i := 0
		for m in markers(map_num, "NPCs"):
			if not (m is NpcMarker):
				continue
			if i >= gp.npc[map_num].size():
				push_warning("Map %d has more NPCs than slots (%d)." % [map_num, gp.npc[map_num].size()])
				break
			var entity: Entity = gp.e_generator.get_npc(m.npc, m.profile)
			if entity == null:
				push_warning("Unknown NPC '%s' on map %d." % [m.npc, map_num])
				continue
			_place(entity, m)
			# A guide NPC needs to know which dungeon he is pointing at and
			# where he walks when you follow him. Both come from the marker.
			# A shop whose shelf is filled in on the marker rather than in code.
			if entity is NPC_Merchant and not m.shop_stock.is_empty():
				entity.stock_from(m.shop_stock)
			if entity is NPC_OldMan:
				entity.guide_dungeon_id = m.guide_dungeon_id
				var goal: Vector2i = m.guide_tile()
				entity.guide_col = goal.x
				entity.guide_row = goal.y
			gp.npc[map_num][i] = entity
			npc_by_marker[m] = entity
			i += 1
		_clear_rest(gp.npc, map_num, i)


func set_monster() -> void:
	for map_num in range(gp.max_map):
		set_monster_on(map_num)


## Rebuild one map's monsters from its markers.
##
## Called for every map on a new game, on death and when the player rests - and
## for a single map whenever the player walks onto it, which is what makes
## re-entering a place refill it. That is the oldest money loop there is: clear
## the screen, leave, come back, clear it again.
func set_monster_on(map_num: int) -> void:

	if map_num < 0 or map_num >= gp.max_map:
		return

	var i := 0
	for m in markers(map_num, "Monsters"):
		if not (m is MonsterMarker):
			continue
		if i >= gp.monster[map_num].size():
			push_warning("Map %d has more monsters than slots (%d)." % [map_num, gp.monster[map_num].size()])
			break
		var entity: Entity = gp.e_generator.get_monster(m.monster, m.stats)
		if entity == null:
			push_warning("Unknown monster '%s' on map %d." % [m.monster, map_num])
			continue
		_place(entity, m)
		# A boss needs to know which dungeon it guards and which route its
		# death opens. Both are set on the marker in the Inspector.
		if entity is MON_Boss:
			entity.dungeon_id = m.boss_dungeon_id
			entity.reward_ticket = m.reward_ticket
			if m.stats != null:
				entity.apply_stats(m.stats)
		elif m.stats != null and m.monster != "From Stats":
			# An override on a named monster: keep its script and art, take the
			# numbers off the sheet. One tougher Slime, no second Slime script.
			m.stats.apply_to(entity)
		gp.monster[map_num][i] = entity
		i += 1
	_clear_rest(gp.monster, map_num, i)


func set_interactive_tile() -> void:

	for map_num in range(gp.max_map):
		var i := 0
		for m in markers(map_num, "InteractiveTiles"):
			if not (m is InteractiveTileMarker):
				continue
			if i >= gp.i_tile[map_num].size():
				push_warning("Map %d has more interactive tiles than slots (%d)." % [map_num, gp.i_tile[map_num].size()])
				break
			var entity = gp.e_generator.get_interactive_tile(m.kind, m.tile_col(), m.tile_row())
			if entity == null:
				push_warning("Unknown interactive tile '%s' on map %d." % [m.kind, map_num])
				continue
			gp.i_tile[map_num][i] = entity
			i += 1
		_clear_rest(gp.i_tile, map_num, i)

	gp.p_finder.solid_dirty = true
