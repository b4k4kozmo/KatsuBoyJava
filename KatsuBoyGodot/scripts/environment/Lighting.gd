class_name Lighting
extends RefCounted
## Java: environment/Lighting.java

var gp
## Java built a screen sized BufferedImage and painted a RadialGradientPaint
## into it. Godot's GradientTexture2D does the same job, so we only have to
## rebuild it when the player's light source changes.
var darkness_filter: Texture2D
var filter_pos: Vector2 = Vector2.ZERO
var filter_size: int
var day_counter: int
var filter_alpha: float = 0.0

const DAY := 0
const DUSK := 1
const NIGHT := 2
const DAWN := 3
var day_state: int = DAY


func _init(gp) -> void:
	self.gp = gp
	# A square that is as wide as the screen, centred on the light, always
	# covers the whole 960x576 view - and being square keeps the light a
	# circle instead of squashing it into an ellipse.
	filter_size = gp.screen_width
	set_light_source()


func set_light_source() -> void:

	var gradient := Gradient.new()

	# A light with no radius would collapse the radial gradient onto a single
	# point (and render as nothing), so treat it as no light at all.
	var light = gp.player.current_light
	if light != null and light.light_radius <= 0:
		light = null

	if light == null:
		# No light: a flat sheet of darkness over the whole screen.
		gradient.set_color(0, Color8(26, 2, 43, 240))
		gradient.set_color(1, Color8(26, 2, 43, 240))
		filter_pos = Vector2.ZERO
	else:
		# Create a gradation effect within the light circle
		gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
		gradient.colors = PackedColorArray([
			Color8(26, 2, 43, 25),   # kamiblack at various opacities
			Color8(26, 2, 43, 75),
			Color8(26, 2, 43, 150),
			Color8(26, 2, 43, 225),
			Color8(26, 2, 43, 240),
		])

		# Get the centre x and y of the light circle
		@warning_ignore("integer_division")
		var center_x: int = gp.player.screen_x + gp.tile_size / 2
		@warning_ignore("integer_division")
		var center_y: int = gp.player.screen_y + gp.tile_size / 2
		filter_pos = Vector2(center_x - filter_size / 2.0, center_y - filter_size / 2.0)

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = filter_size
	texture.height = filter_size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	var radius: float = 1.0
	if light != null:
		radius = float(light.light_radius) / filter_size
	texture.fill_to = Vector2(0.5 + radius, 0.5)
	darkness_filter = texture


func reset_day() -> void:
	day_state = DAY
	filter_alpha = 0.0


func update() -> void:

	if gp.player.light_updated == true:
		set_light_source()
		gp.player.light_updated = false

	# Check the state of the day
	if day_state == DAY:
		day_counter += 1
		if day_counter > 9000:
			day_state = DUSK
			day_counter = 0

	if day_state == DUSK:
		filter_alpha += 0.001
		if filter_alpha > 1.0:
			filter_alpha = 1.0
			day_state = NIGHT

	if day_state == NIGHT:
		day_counter += 1
		if day_counter > 4800:
			day_state = DAWN
			day_counter = 0

	if day_state == DAWN:
		filter_alpha -= 0.001
		if filter_alpha < 0.0:
			filter_alpha = 0.0
			day_state = DAY


func draw(g2) -> void:

	g2.change_alpha(filter_alpha)
	g2.draw_img_scaled(darkness_filter, int(filter_pos.x), int(filter_pos.y), filter_size, filter_size)
	g2.change_alpha(1.0)

	# DEBUG
	# Java always drew the day/night label on top of the game. It is only shown
	# with the rest of the debug overlay here (press T).
	if gp.key_h.check_draw_time == true:
		var situation := ""
		match day_state:
			DAY: situation = "Day"
			DUSK: situation = "Dusk"
			NIGHT: situation = "Night"
			DAWN: situation = "Dawn"
		g2.set_font(gp.ui.maru_monica, 50)
		g2.set_color(gp.ui.kamiwhite)
		g2.draw_str(situation, 800, 500)
