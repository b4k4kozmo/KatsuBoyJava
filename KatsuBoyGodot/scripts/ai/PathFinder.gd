class_name PathFinder
extends RefCounted
## Java: ai/PathFinder.java - A* search over the tile grid.

var gp
var node: Array = []                # node[col][row]
var open_list: Array[PathNode] = []
var path_list: Array[PathNode] = []
var start_node: PathNode
var goal_node: PathNode
var current_node: PathNode
var goal_reached: bool = false
var step: int = 0
## Every node we flipped open/checked on during the last search, so reset_nodes()
## only has to undo those instead of walking all 10,000 nodes again.
var touched_list: Array[PathNode] = []
## Which map the solid flags were built for, and whether they need rebuilding.
var solid_map: int = -1
var solid_dirty: bool = true


func _init(gp) -> void:
	self.gp = gp
	instantiate_nodes()


func instantiate_nodes() -> void:
	node = []
	for col in range(gp.max_world_col):
		var column: Array = []
		for row in range(gp.max_world_row):
			column.append(PathNode.new(col, row))
		node.append(column)


func reset_nodes() -> void:

	# Reset open and checked state on the nodes the last search actually used.
	# (Java re-walked the entire 100x100 grid on every call, which is most of
	#  why chasing monsters ground the Java build to a halt.)
	for n in touched_list:
		n.open = false
		n.checked = false
	touched_list.clear()

	# Reset other settings
	open_list.clear()
	path_list.clear()
	goal_reached = false
	step = 0


## Which tiles can never be walked through. This only changes when the map
## changes or an interactive tile is destroyed, so it is cached rather than
## rebuilt on every search.
func set_solid_nodes() -> void:

	if solid_map == gp.current_map and solid_dirty == false:
		return

	for col in range(gp.max_world_col):
		for row in range(gp.max_world_row):
			# CHECK TILES
			var tile_num: int = gp.tile_m.map_tile_num[gp.current_map][col][row]
			node[col][row].solid = gp.tile_m.tile[tile_num].collision

	# CHECK INTERACTIVE TILES
	# (Java ran this loop inside the col/row loop above, 10,000 times over,
	#  even though it does not depend on col or row at all.)
	for i in range(gp.i_tile[1].size()):
		if gp.i_tile[gp.current_map][i] != null and gp.i_tile[gp.current_map][i].destructable == true:
			@warning_ignore("integer_division")
			var it_col: int = gp.i_tile[gp.current_map][i].world_x / gp.tile_size
			@warning_ignore("integer_division")
			var it_row: int = gp.i_tile[gp.current_map][i].world_y / gp.tile_size
			node[it_col][it_row].solid = true

	solid_map = gp.current_map
	solid_dirty = false


func set_nodes(start_col: int, start_row: int, goal_col: int, goal_row: int) -> void:

	reset_nodes()
	set_solid_nodes()

	# Set Start and Goal node
	start_node = node[start_col][start_row]
	current_node = start_node
	goal_node = node[goal_col][goal_row]
	open_list.append(current_node)
	touched_list.append(current_node)
	get_cost(start_node)


func get_cost(n: PathNode) -> void:
	# G Cost
	var x_distance: int = absi(n.col - start_node.col)
	var y_distance: int = absi(n.row - start_node.row)
	n.g_cost = x_distance + y_distance
	# H Cost
	x_distance = absi(n.col - goal_node.col)
	y_distance = absi(n.row - goal_node.row)
	n.h_cost = x_distance + y_distance
	# F Cost
	n.f_cost = n.g_cost + n.h_cost


func search() -> bool:
	while goal_reached == false and step < 500:

		var col: int = current_node.col
		var row: int = current_node.row

		# Check the current node
		current_node.checked = true
		open_list.erase(current_node)

		# Open the Up node
		if row - 1 >= 0:
			open_node(node[col][row - 1])
		# Open the left node
		if col - 1 >= 0:
			open_node(node[col - 1][row])
		# Open the down node
		if row + 1 < gp.max_world_row:
			open_node(node[col][row + 1])
		# Open the right node
		if col + 1 < gp.max_world_col:
			open_node(node[col + 1][row])

		# Find the best node
		var best_node_index: int = 0
		var best_node_f_cost: int = 999

		for i in range(open_list.size()):
			# Check if this node's F cost is better
			if open_list[i].f_cost < best_node_f_cost:
				best_node_index = i
				best_node_f_cost = open_list[i].f_cost
			# If F cost is equal, check the G cost
			elif open_list[i].f_cost == best_node_f_cost:
				if open_list[i].g_cost < open_list[best_node_index].g_cost:
					best_node_index = i

		# If there is no node in the open list, end the loop
		if open_list.size() == 0:
			break

		# After the loop, open_list[best_node_index] is the next step (= current node)
		current_node = open_list[best_node_index]

		if current_node == goal_node:
			goal_reached = true
			track_the_path()
		step += 1

	return goal_reached


func open_node(n: PathNode) -> void:
	if n.open == false and n.checked == false and n.solid == false:
		n.open = true
		n.parent = current_node
		# Java pre-computed the cost of all 10,000 nodes in set_nodes(). The
		# formula is unchanged, we just work it out when a node is opened.
		get_cost(n)
		open_list.append(n)
		touched_list.append(n)


func track_the_path() -> void:
	var current: PathNode = goal_node

	while current != start_node:
		path_list.insert(0, current)
		current = current.parent
