class_name EffectsLayer
extends Node2D
## Hit sparks, drawn with shaders/impact.gdshader.
##
## One material draws every impact, so each one's colour and progress ride in
## on the draw call's modulate: RGB is the colour, ALPHA is how far through its
## life it is. Colours always come from the game's palette.
##
## Call gp.effects.add_impact(...) from anywhere damage lands. Delete this node
## from main.tscn and the game plays exactly the same, minus the sparks.

## Turn the sparks off without removing the node.
@export var enabled: bool = true
## How long a spark lasts, in game frames (60 = 1 second).
@export var impact_life: int = 14
## How big a spark is, in pixels.
@export var impact_size: int = 84

var gp
var impacts: Array[Dictionary] = []


func _ready() -> void:
	gp = get_parent()
	z_index = 6


## world_x / world_y are world coordinates - the same ones entities use.
func add_impact(world_x: int, world_y: int, color: Color, size_scale: float = 1.0) -> void:
	if not enabled:
		return
	impacts.append({
		"world": Vector2(world_x, world_y),
		"age": 0,
		"life": impact_life,
		"color": color,
		"size": impact_size * size_scale,
	})


## Centres a spark on an entity rather than its top-left corner.
func add_impact_on(entity, color: Color, size_scale: float = 1.0) -> void:
	@warning_ignore("integer_division")
	add_impact(entity.world_x + gp.tile_size / 2, entity.world_y + gp.tile_size / 2,
			color, size_scale)


func _physics_process(_delta: float) -> void:
	var i := 0
	while i < impacts.size():
		impacts[i]["age"] += 1
		if impacts[i]["age"] >= impacts[i]["life"]:
			impacts.remove_at(i)
		else:
			i += 1


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:

	if gp == null or gp.player == null or impacts.is_empty():
		return
	if gp.game_state == gp.TITLE_STATE or gp.game_state == gp.MAP_STATE:
		return

	for impact in impacts:
		var progress: float = float(impact["age"]) / float(impact["life"])
		var size: float = impact["size"]
		var screen: Vector2 = gp.to_screen(int(impact["world"].x), int(impact["world"].y))
		var rect := Rect2(screen.x - size / 2.0, screen.y - size / 2.0, size, size)
		var c: Color = impact["color"]
		# alpha carries the progress; the shader works out the real opacity
		draw_texture_rect(Graphics2D.white_pixel, rect, false,
				Color(c.r, c.g, c.b, progress))
