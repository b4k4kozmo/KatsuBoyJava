@tool
extends EditorPlugin
## Captures the editor screenshots used in AUTHORING.md and the online guides.
##
## It is not installed. To regenerate the pictures:
##
##   cp -r tools/screenshots addons/shotter
##   xvfb-run -a -s "-screen 0 1920x1200x24" godot --editor --path . \
##       --rendering-method gl_compatibility --rendering-driver opengl3
##   rm -rf addons/shotter
##
## The editor opens, walks the list of shots below, writes PNGs into
## docs/images/, and quits. Anything that cannot be found is skipped with a
## warning rather than failing the run, so a renamed node costs one picture
## rather than the whole set.

const OUT_DIR := "res://docs/images/"
## Frames to let the editor settle before the first capture. The inspector
## rebuilds itself over several frames when the selection changes, and again
## after the groups are unfolded.
const WARMUP := 90
const SETTLE := 25
const UNFOLD_SETTLE := 20
## How wide to make the inspector dock. The default is about 280 px, which
## truncates half the property names we are trying to show.
const DOCK_WIDTH := 470

var _queue: Array = []
var _frames := 0
var _waiting := 0
var _started := false


func _enter_tree() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_queue = _shots()
	set_process(true)


func _process(_delta: float) -> void:

	_frames += 1
	if _frames < WARMUP:
		return

	if _waiting > 0:
		_waiting -= 1
		return

	if not _started:
		_started = true

	if _queue.is_empty():
		print("[shotter] done.")
		EditorInterface.get_base_control().get_tree().quit()
		return

	var shot: Dictionary = _queue.pop_front()

	if shot.has("setup"):
		_widen_dock()
		shot["setup"].call()
		_waiting = SETTLE
		_queue.push_front({"unfold": true, "capture": shot["capture"], "name": shot["name"],
				"scroll": shot.get("scroll", 0)})
		return

	if shot.has("unfold"):
		# Every @export_group starts folded, which is exactly the information a
		# screenshot is meant to carry. Open them all.
		_unfold_all(EditorInterface.get_inspector())
		_waiting = UNFOLD_SETTLE
		_queue.push_front({"capture": shot["capture"], "name": shot["name"],
				"scroll": shot.get("scroll", 0)})
		return

	# A sheet taller than the dock is captured twice: once from the top, once
	# scrolled down. Two pictures beside the two halves of the guide beats one
	# picture with its bottom cut off.
	var want: int = shot.get("scroll", 0)
	var insp: ScrollContainer = EditorInterface.get_inspector()
	if want > 0 and not shot.get("scrolled", false):
		# Setting the scroll and grabbing the viewport in the same frame gets
		# the view as it was BEFORE the scroll. Let it redraw first.
		insp.scroll_vertical = want
		shot["scrolled"] = true
		_waiting = 6
		_queue.push_front(shot)
		return
	if want == 0:
		insp.scroll_vertical = 0
	_scrolled = want > 0

	_capture(shot["name"], shot["capture"])


## Give the inspector dock room to show a property name in full, and the window
## room to show a fully unfolded resource. The inspector is a scroll container,
## so nothing below its fold is captured - a short window silently truncates the
## very thing the picture is for.
func _widen_dock() -> void:

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1880, 1470))
	DisplayServer.window_set_position(Vector2i(0, 0))

	var node: Node = EditorInterface.get_inspector()
	while node != null:
		if node is SplitContainer and node.get_child_count() >= 2:
			var split: SplitContainer = node
			# The right-hand dock: a negative offset measures from the right edge.
			if split.get_child(1) != null and split.get_child(1).is_ancestor_of(
					EditorInterface.get_inspector()):
				split.split_offset = -DOCK_WIDTH
				return
		node = node.get_parent()


## Open every collapsed section under a control, however deeply nested.
func _unfold_all(node: Node) -> void:
	if node.has_method("unfold"):
		node.call("unfold")
	for child in node.get_children():
		_unfold_all(child)


# ---------------------------------------------------------------- the shots

func _shots() -> Array:

	var out: Array = []

	# The map root: the four tool buttons and the Dungeon Info slot.
	out.append(_node_shot("map-root", "res://scenes/maps/MushroomCave.tscn", ".", "inspector"))
	# The scene tree, so the five group names are visible.
	out.append(_node_shot("scene-tree", "res://scenes/maps/MushroomCave.tscn", ".", "tree"))
	# A monster built from a resource.
	out.append(_node_shot("monster-marker", "res://scenes/maps/MushroomCave.tscn",
			"Monsters/Mushroom1", "inspector"))
	# A chest holding an item that is a resource.
	out.append(_node_shot("object-marker", "res://scenes/maps/MushroomCave.tscn",
			"Objects/Chest0", "inspector"))
	# A character built from a profile.
	out.append(_node_shot("npc-marker", "res://scenes/maps/WorldMap.tscn",
			"NPCs/DriftwoodNan", "inspector"))
	# A door that points at a scene rather than a number.
	out.append(_node_shot("event-changemap", "res://scenes/maps/WorldMap.tscn",
			"Events/ChangeMap", "inspector"))
	# The boat dock, which is what makes a map a destination.
	out.append(_node_shot("event-boat", "res://scenes/maps/MushroomCave.tscn",
			"Events/BoatDock", "inspector"))
	# An interactive tile, the simplest marker there is.
	out.append(_node_shot("guide-npc", "res://scenes/maps/WorldMap.tscn",
			"NPCs/DockGuide", "inspector"))

	# The tile sheet tool, which is where a new sheet gets turned into tiles.
	out.append(_node_shot("tile-sheet", "res://scenes/tools/TileSheet.tscn", ".",
			"inspector"))
	# A monster that takes up more than one tile.
	out.append(_node_shot("big-monster", "res://scenes/maps/WorldMap.tscn",
			"Monsters/Kamijack", "inspector"))

	# The three resources, opened in the inspector on their own.
	out.append(_res_shot("sheet-monster", "res://assets/data/monsters/example_custom.tres"))
	out.append(_res_shot("sheet-monster-2", "res://assets/data/monsters/example_custom.tres", 620))
	out.append(_res_shot("sheet-item", "res://assets/data/items/example_consumable.tres"))
	out.append(_res_shot("sheet-item-2", "res://assets/data/items/example_consumable.tres", 620))
	out.append(_res_shot("sheet-npc", "res://assets/data/npcs/example_villager.tres"))
	out.append(_res_shot("sheet-dungeon", "res://assets/data/dungeons/mushroom_cave.tres"))

	return out


func _node_shot(shot_name: String, scene_path: String, node_path: String,
		region: String, scroll: int = 0) -> Dictionary:
	return {
		"name": shot_name,
		"capture": region,
		"scroll": scroll,
		"setup": func() -> void:
			EditorInterface.open_scene_from_path(scene_path)
			EditorInterface.set_main_screen_editor("2D")
			var root: Node = EditorInterface.get_edited_scene_root()
			if root == null:
				push_warning("[shotter] no scene root for %s" % scene_path)
				return
			var target: Node = root if node_path == "." else root.get_node_or_null(node_path)
			if target == null:
				push_warning("[shotter] missing node %s in %s" % [node_path, scene_path])
				return
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(target)
			EditorInterface.edit_node(target)
	}


func _res_shot(shot_name: String, res_path: String, scroll: int = 0) -> Dictionary:
	return {
		"name": shot_name,
		"capture": "inspector",
		"scroll": scroll,
		"setup": func() -> void:
			var res: Resource = load(res_path)
			if res == null:
				push_warning("[shotter] missing resource %s" % res_path)
				return
			EditorInterface.get_selection().clear()
			EditorInterface.edit_resource(res)
	}


# ---------------------------------------------------------------- capturing

var _scrolled := false


func _capture(shot_name: String, region: String) -> void:

	var base: Control = EditorInterface.get_base_control()
	var image: Image = base.get_viewport().get_texture().get_image()
	if image == null:
		push_warning("[shotter] no image for %s" % shot_name)
		return

	var rect: Rect2i = _region_rect(region, base, image)
	if region == "inspector" and not _scrolled:
		var cut: int = _inherited_section_top()
		if cut > rect.position.y + 60:
			rect.size.y = mini(rect.size.y, cut - rect.position.y)
	if rect.size.x > 8 and rect.size.y > 8:
		image = image.get_region(rect)

	var path: String = OUT_DIR + shot_name + ".png"
	var err: int = image.save_png(path)
	print("[shotter] %s -> %s (%d x %d) err=%d" % [
		shot_name, path, image.get_width(), image.get_height(), err])


## The top of the SECOND class heading in the inspector - the one for the class
## this thing inherits from. Everything above it is what the script or resource
## itself declares, which is the only part worth a picture; below it is
## Transform, CanvasItem and Node, the same on every node in Godot.
func _inherited_section_top() -> int:

	var headers: Array[float] = []
	_collect_categories(EditorInterface.get_inspector(), headers)
	# The category control and a child of it both report as a category, so the
	# same heading shows up twice. Collapse them before picking the second one.
	headers.sort()
	var unique: Array[float] = []
	for y in headers:
		if unique.is_empty() or absf(y - unique[-1]) > 4.0:
			unique.append(y)
	if unique.size() < 2:
		return -1
	return int(unique[1])


func _collect_categories(node: Node, out: Array[float]) -> void:
	if node is Control and node.visible and "InspectorCategory" in node.get_class():
		out.append(node.get_global_rect().position.y)
	for child in node.get_children():
		_collect_categories(child, out)


## Where on screen the thing we want actually is, asked of the editor rather
## than guessed, so a different editor layout still crops correctly.
func _region_rect(region: String, base: Control, image: Image) -> Rect2i:

	var full := Rect2i(Vector2i.ZERO, Vector2i(image.get_width(), image.get_height()))
	var control: Control = null

	match region:
		"inspector":
			control = EditorInterface.get_inspector()
		"tree":
			var found: Array = base.find_children("*", "Tree", true, false)
			for c in found:
				if c is Control and c.get_global_rect().size.x > 150 \
						and c.get_global_rect().position.x < base.size.x * 0.35:
					control = c
					break
		"full":
			return full

	if control == null:
		return full

	# A little breathing room, then clamp back inside the window.
	var r: Rect2 = control.get_global_rect()
	var pad := 10
	var out := Rect2i(
			int(r.position.x) - pad, int(r.position.y) - pad - 26,
			int(r.size.x) + pad * 2, int(r.size.y) + pad * 2 + 26)
	return out.intersection(full)
