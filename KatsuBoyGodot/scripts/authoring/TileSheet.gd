@icon("res://assets/tiles/tree.png")
@tool
class_name TileSheet
extends Node
## Turns a sheet drawn in Aseprite into the game's tile set, without anybody
## editing a list of file names in code.
##
## The old way was three steps and one of them was a code edit: add a PNG per
## tile, add its name to TILE_NAMES in tools/build_tileset.gd, run the script,
## run the importer, then tick collision in the TileSet editor. Now: export one
## sheet from Aseprite, drop it in assets/tiles/, press **Rebuild from sheet**.
##
## HOW TO USE IT
##
##   1. Open scenes/tools/TileSheet.tscn (or add a TileSheet node to any scene).
##   2. Point **Sheet** at your PNG and **Tile Set** at katsuboy_tileset.tres.
##   3. Press **Rebuild from sheet**.
##
## It creates a tile for every cell that has something drawn in it, removes
## tiles whose cell has gone empty, and - the part Godot's own "create tiles in
## non-transparent regions" button does not do - KEEPS the collision flags you
## already ticked, matched up by position in the sheet.
##
## ASEPRITE SETTINGS THAT MATTER
##
##   * Tiles are **16x16**. That is what everything in this game is drawn at.
##   * Lay the sheet out in a grid with no padding and no gaps between tiles.
##   * Export as PNG at 1x - do NOT upscale. This tool does the upscaling.
##   * Leave a cell completely empty to skip it. Anything with a single pixel
##     drawn in it becomes a tile.
##
## SIXTEEN IN, FORTY-EIGHT OUT
##
## The game runs at three times the art: GamePanel has ORIGINAL_TILE_SIZE 16 and
## SCALE 3, so a tile is 48x48 on screen and the whole world grid is measured in
## 48s. The tile set therefore needs 48x48 tiles.
##
## So there are two pictures. The SHEET is the one you draw, at 16. The ATLAS is
## generated from it - every cell blown up three times with nearest-neighbour,
## which is exactly the scaling the sprites get at load - and it is the atlas the
## tile set points at. You never open the atlas; it is a build artefact.
##
## Nothing here upscales twice and nothing interpolates, so the pixels stay
## square. The project's texture filter is Nearest as well.
##
## WHICH TILES ARE WALLS
##
## Collision lives in the tile set, where you tick it on a tile and see the
## result immediately. **Write solid map** and **Read solid map** copy those
## ticks to and from a plain text file next to the sheet, so what is solid is
## something you can read in a diff and edit in any text editor rather than
## only by clicking.

## What the art is drawn at, and how much bigger the game draws it. Both come
## from GamePanel so there is one place that decides.
const ART := GamePanel.ORIGINAL_TILE_SIZE     # 16
const SCALE := GamePanel.SCALE                # 3
const TILE := ART * SCALE                     # 48, the size in the tile set

## The sheet you drew, with 16x16 cells.
@export_file("*.png") var sheet: String = "res://assets/tiles/katsuboy_sheet.png":
	set(value):
		sheet = value
		update_configuration_warnings()

## Where to write the upscaled picture the tile set actually uses. Generated -
## do not edit it, and do not draw in it.
@export_file("*.png") var atlas: String = "res://assets/tiles/katsuboy_atlas.png":
	set(value):
		atlas = value
		update_configuration_warnings()

## The tile set to build into. Every map's Tiles layer points at this same one.
@export var tile_set: TileSet:
	set(value):
		tile_set = value
		update_configuration_warnings()

@export_group("Tools")
## Creates tiles for every drawn cell, drops tiles whose cell went empty, and
## keeps the collision you already ticked.
@export_tool_button("Rebuild from sheet", "TileSet") var rebuild_action = _rebuild
## Reports what the sheet and the tile set currently disagree about.
@export_tool_button("Check the sheet", "Search") var check_action = _report
## Writes which tiles are solid to a readable text file beside the sheet.
@export_tool_button("Write solid map", "Save") var write_action = _write_solid
## Reads that file back and re-ticks collision from it.
@export_tool_button("Read solid map", "Load") var read_action = _read_solid


# ---------------------------------------------------------------- the tools

func _rebuild() -> void:

	var source: TileSetAtlasSource = _source()
	if source == null:
		return

	var image: Image = _sheet_image()
	if image == null:
		return

	# Remember what was ticked before anything is touched.
	var was_solid: Dictionary = _collision_map(source)

	var cols: int = _cols(image)
	var rows: int = _rows(image)

	# Blow the sheet up to the size the world grid is measured in. Nearest
	# neighbour and a whole-number factor, so every drawn pixel becomes an
	# exact 3x3 block and nothing is ever half a pixel wide.
	if not _write_atlas(image, cols, rows):
		return

	source.texture = load(atlas)
	source.texture_region_size = Vector2i(TILE, TILE)

	var added := 0
	var removed := 0
	var kept := 0

	for row in range(rows):
		for col in range(cols):
			var at := Vector2i(col, row)
			var drawn: bool = _cell_has_art(image, at)
			var exists: bool = source.has_tile(at)

			if drawn and not exists:
				source.create_tile(at)
				added += 1
			elif exists and not drawn:
				source.remove_tile(at)
				removed += 1

			if drawn and was_solid.get(at, false):
				var data: TileData = source.get_tile_data(at, 0)
				if data != null:
					data.set_custom_data("collision", true)
					kept += 1

	# Tiles left over past the edge of a sheet that got smaller.
	for i in range(source.get_tiles_count() - 1, -1, -1):
		var at: Vector2i = source.get_tile_id(i)
		if at.x >= cols or at.y >= rows:
			source.remove_tile(at)
			removed += 1

	print("[%s] %d x %d cells of %d px, drawn at %d: %d tile(s) added, %d removed, %d collision flag(s) kept."
			% [name, cols, rows, ART, TILE, added, removed, kept])
	_save_tile_set()
	update_configuration_warnings()


func _report() -> void:
	var problems: PackedStringArray = _problems()
	if problems.is_empty():
		var source := _source()
		var image := _sheet_image()
		print("[%s] sheet and tile set agree: %d tiles, %d solid, %d x %d cells." % [
			name, source.get_tiles_count(), _solid_count(source),
			_cols(image), _rows(image)])
	else:
		print("[%s] %d problem(s):" % [name, problems.size()])
		for p in problems:
			print("   - " + p)
	update_configuration_warnings()


## A picture of the sheet in text: # is solid, . is walkable, a space is a cell
## with nothing drawn in it. Readable in a diff, editable in any editor.
func _write_solid() -> void:

	var source := _source()
	var image := _sheet_image()
	if source == null or image == null:
		return

	var lines := PackedStringArray()
	lines.append("; Which tiles in %s block movement." % sheet.get_file())
	lines.append(";   #  solid      .  walkable      (space)  no tile here")
	lines.append("; Edit this and press 'Read solid map' to apply it.")
	lines.append(";")
	lines.append("; A row of the sheet is a line of nothing but those three")
	lines.append("; characters. Anything else is a note like this one.")

	for row in range(_rows(image)):
		var line := ""
		for col in range(_cols(image)):
			var at := Vector2i(col, row)
			if not source.has_tile(at):
				line += " "
			elif _is_solid(source, at):
				line += "#"
			else:
				line += "."
		lines.append(line)

	var path: String = _solid_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[%s] cannot write %s" % [name, path])
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("[%s] wrote %s" % [name, path])


func _read_solid() -> void:

	var source := _source()
	if source == null:
		return

	var path: String = _solid_path()
	if not FileAccess.file_exists(path):
		print("[%s] no %s yet - press 'Write solid map' first." % [name, path.get_file()])
		return

	var rows := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if is_grid_row(line):
			rows.append(line)

	var changed := 0
	for row in range(rows.size()):
		var line: String = rows[row]
		for col in range(line.length()):
			var at := Vector2i(col, row)
			if not source.has_tile(at):
				continue
			var data: TileData = source.get_tile_data(at, 0)
			if data == null:
				continue
			var want: bool = line[col] == "#"
			if bool(data.get_custom_data("collision")) != want:
				data.set_custom_data("collision", want)
				changed += 1

	print("[%s] read %s: %d tile(s) changed." % [name, path.get_file(), changed])
	_save_tile_set()


## Write the upscaled picture the tile set points at. Returns false if it could
## not be written, in which case nothing else should touch the tile set.
func _write_atlas(image: Image, cols: int, rows: int) -> bool:

	if atlas == sheet:
		push_error("[%s] the sheet and the atlas are the same file. The atlas is "
				% name + "generated; point it somewhere else.")
		return false

	var big := Image.create_empty(cols * TILE, rows * TILE, false, Image.FORMAT_RGBA8)

	for row in range(rows):
		for col in range(cols):
			var cell: Image = image.get_region(
					Rect2i(col * ART, row * ART, ART, ART))
			cell.convert(Image.FORMAT_RGBA8)
			cell.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
			big.blit_rect(cell, Rect2i(0, 0, TILE, TILE),
					Vector2i(col * TILE, row * TILE))

	var err: int = big.save_png(atlas)
	if err != OK:
		push_error("[%s] could not write %s (error %d)" % [name, atlas, err])
		return false

	# Godot will not see a file rewritten under its feet until it is reimported.
	if Engine.is_editor_hint():
		var fs := EditorInterface.get_resource_filesystem()
		fs.update_file(atlas)
		fs.reimport_files(PackedStringArray([atlas]))

	print("[%s] wrote %s at %d x %d." % [name, atlas, big.get_width(), big.get_height()])
	return true


# ---------------------------------------------------------------- checking

func _get_configuration_warnings() -> PackedStringArray:
	return _problems()


func _problems() -> PackedStringArray:

	var out := PackedStringArray()

	if tile_set == null:
		out.append("No Tile Set. Drag assets/tiles/katsuboy_tileset.tres in.")
		return out

	var source := _source(false)
	if source == null:
		out.append("The tile set's first source is not an atlas.")
		return out

	var image := _sheet_image(false)
	if image == null:
		out.append("Cannot read %s." % sheet)
		return out

	if image.get_width() % ART != 0 or image.get_height() % ART != 0:
		out.append("The sheet is %d x %d, which is not a whole number of %d px tiles. "
				% [image.get_width(), image.get_height(), ART]
				+ "Tiles are %d x %d - export from Aseprite at 1x with no padding."
				% [ART, ART])

	# A sheet already blown up by hand is the easy mistake to make, and it looks
	# like a sheet with four times as many tiles in it.
	if image.get_width() % TILE == 0 and image.get_height() % TILE == 0 \
			and image.get_width() > ART * 4:
		out.append("This looks like it may already be upscaled: %d x %d divides by %d. "
				% [image.get_width(), image.get_height(), TILE]
				+ "Draw at %d and let the tool do the rest." % ART)

	if source.texture == null or source.texture.resource_path != atlas:
		var points_at: String = "nothing"
		if source.texture != null:
			points_at = source.texture.resource_path.get_file()
		out.append("The tile set is pointing at %s rather than %s. Press 'Rebuild from sheet'."
				% [points_at, atlas.get_file()])
		return out

	var missing := 0
	var extra := 0
	for row in range(_rows(image)):
		for col in range(_cols(image)):
			var at := Vector2i(col, row)
			var drawn: bool = _cell_has_art(image, at)
			if drawn and not source.has_tile(at):
				missing += 1
			elif source.has_tile(at) and not drawn:
				extra += 1

	if missing > 0:
		out.append("%d cell(s) are drawn in the sheet but have no tile. "
				% missing + "Press 'Rebuild from sheet'.")
	if extra > 0:
		out.append("%d tile(s) point at an empty cell. " % extra
				+ "Press 'Rebuild from sheet' to drop them.")

	return out


# ---------------------------------------------------------------- lookups

func _source(complain := true) -> TileSetAtlasSource:
	if tile_set == null:
		if complain:
			push_error("[%s] no tile set." % name)
		return null
	if tile_set.get_source_count() == 0:
		if complain:
			push_error("[%s] the tile set has no sources." % name)
		return null
	var source := tile_set.get_source(tile_set.get_source_id(0)) as TileSetAtlasSource
	if source == null and complain:
		push_error("[%s] the tile set's first source is not an atlas." % name)
	return source


func _sheet_image(complain := true) -> Image:
	if not ResourceLoader.exists(sheet):
		if complain:
			push_error("[%s] no such sheet: %s" % [name, sheet])
		return null
	var tex: Texture2D = load(sheet)
	if tex == null:
		return null
	var image: Image = tex.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	return image


## Measured on the SHEET, so in art pixels - 16 - not the 48 the tile set uses.
func _cols(image: Image) -> int:
	@warning_ignore("integer_division")
	return maxi(image.get_width() / ART, 1) if image != null else 0


func _rows(image: Image) -> int:
	@warning_ignore("integer_division")
	return maxi(image.get_height() / ART, 1) if image != null else 0


## Is anything drawn in this cell? A single opaque pixel is enough - the test is
## deliberately generous, because a tile that is mostly transparent by design
## (a bridge railing, say) is still a tile.
func _cell_has_art(image: Image, at: Vector2i) -> bool:
	for y in range(ART):
		for x in range(ART):
			var px := Vector2i(at.x * ART + x, at.y * ART + y)
			if px.x >= image.get_width() or px.y >= image.get_height():
				continue
			if image.get_pixelv(px).a > 0.01:
				return true
	return false


## Is this line of the solid map a row of the sheet, rather than a note?
##
## By what it contains, not by what it starts with. A row whose leftmost tile is
## solid begins with a "#", and testing the first character for a comment marker
## quietly dropped every such row - which is exactly the row a map's left wall
## lives in.
static func is_grid_row(line: String) -> bool:
	var stripped: String = line.strip_edges(false, true)
	if stripped.strip_edges().is_empty():
		return false
	for i in range(stripped.length()):
		if not (stripped[i] in ["#", ".", " "]):
			return false
	return true


func _is_solid(source: TileSetAtlasSource, at: Vector2i) -> bool:
	var data: TileData = source.get_tile_data(at, 0)
	return data != null and bool(data.get_custom_data("collision"))


func _collision_map(source: TileSetAtlasSource) -> Dictionary:
	var out := {}
	for i in range(source.get_tiles_count()):
		var at: Vector2i = source.get_tile_id(i)
		if _is_solid(source, at):
			out[at] = true
	return out


func _solid_count(source: TileSetAtlasSource) -> int:
	return _collision_map(source).size()


func _solid_path() -> String:
	return sheet.get_basename() + ".solid.txt"


func _save_tile_set() -> void:
	if tile_set == null or tile_set.resource_path.is_empty():
		return
	var err := ResourceSaver.save(tile_set, tile_set.resource_path)
	if err != OK:
		push_error("[%s] could not save %s (error %d)" % [name, tile_set.resource_path, err])
