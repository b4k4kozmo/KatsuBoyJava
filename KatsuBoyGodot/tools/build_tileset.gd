@tool
extends SceneTree
## LEGACY. Packs the loose per-tile PNGs in assets/tiles/ into one sheet.
##
## This is how the sheet was built when every tile was its own file and adding
## one meant editing the list below - a code change to add a picture. It is kept
## because that is how the shipped sheet was made, and re-running it reproduces
## exactly the atlas the maps were painted against.
##
## DO NOT USE IT FOR NEW TILES. Draw into assets/tiles/katsuboy_sheet.png - the
## 16x16 sheet - and press "Rebuild from sheet" on scenes/tools/TileSheet.tscn.
## That path touches no code, keeps the collision you have already ticked, does
## the x3 upscale for you, and does not care how wide your sheet is.
## See AUTHORING.md.
##
## Note this script's TILE is 48: it upscales each 16x16 source PNG on the way
## in, which is the same thing TileSheet now does from a sheet.
##
## Run:  godot --headless --path . --script res://tools/build_tileset.gd
## then: godot --headless --path . --import

## Tile order defines the tile ID used in map data and in the old res/maps
## text files. NEVER reorder these - append new tiles to the end.
const TILE_NAMES := [
	"grass00", "grass01",
	"road00", "road01", "road02", "road03", "road04", "road05", "road06",
	"road07", "road08", "road09", "road10", "road11", "road12",
	"sand", "tree", "wall",
	"water01", "water02", "water03", "water04", "water05", "water06", "water07",
	"water08", "water09", "water10", "water11", "water12", "water13",
	"wildmushroom",
	"wunderboat1", "wunderboat10", "wunderboat11", "wunderboat12", "wunderboat2",
	"wunderboat3", "wunderboat4", "wunderboat5", "wunderboat6", "wunderboat7",
	"wunderboat8", "wunderboat9",
]

const COLS := 11
const TILE := 48


func _init() -> void:
	var rows: int = ceili(TILE_NAMES.size() / float(COLS))
	var atlas := Image.create_empty(COLS * TILE, rows * TILE, false, Image.FORMAT_RGBA8)

	for i in range(TILE_NAMES.size()):
		var tex: Texture2D = load("res://assets/tiles/%s.png" % TILE_NAMES[i])
		if tex == null:
			push_error("missing tile: " + TILE_NAMES[i])
			continue
		var img: Image = tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
		img.convert(Image.FORMAT_RGBA8)
		@warning_ignore("integer_division")
		atlas.blit_rect(img, Rect2i(0, 0, TILE, TILE),
				Vector2i((i % COLS) * TILE, (i / COLS) * TILE))

	var err := atlas.save_png("res://assets/tiles/katsuboy_atlas.png")
	print("atlas: %d tiles, %dx%d, err=%d" % [TILE_NAMES.size(), atlas.get_width(), atlas.get_height(), err])
	quit()
