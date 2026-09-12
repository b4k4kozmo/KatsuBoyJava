class_name LightingOverlay
extends Node2D
## Draws the day/night darkness with shaders/darkness.gdshader.
##
## The Lighting class still owns the clock (what time of day it is, how far
## through the fade we are). This node just feeds those numbers to the shader
## and paints one full-screen quad, which is cheaper than the old approach of
## rebuilding a screen-sized gradient image whenever the light changed.

var gp
var material_ref: ShaderMaterial


func _ready() -> void:
	gp = get_parent()
	z_index = 5
	if material is ShaderMaterial:
		material_ref = material


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:

	if gp == null or gp.e_manager == null or gp.e_manager.lighting == null:
		return
	# The title and full-map screens are not the world, so no night on them.
	if gp.game_state == gp.TITLE_STATE or gp.game_state == gp.MAP_STATE:
		return

	var lighting = gp.e_manager.lighting
	if lighting.filter_alpha <= 0.0:
		return

	if material_ref != null:
		material_ref.set_shader_parameter("fade", lighting.filter_alpha)
		material_ref.set_shader_parameter("dark_color", gp.color_black)
		material_ref.set_shader_parameter("darkness", gp.night_darkness / 255.0)
		material_ref.set_shader_parameter("screen_size",
				Vector2(gp.screen_width, gp.screen_height))

		var light = gp.player.current_light
		if light != null and light.light_radius > 0:
			material_ref.set_shader_parameter("light_radius", float(light.light_radius))
			material_ref.set_shader_parameter("light_center", Vector2(
					gp.player.screen_x + gp.tile_size / 2.0,
					gp.player.screen_y + gp.tile_size / 2.0))
		else:
			material_ref.set_shader_parameter("light_radius", 0.0)

	draw_texture_rect(Graphics2D.white_pixel,
			Rect2(0, 0, gp.screen_width, gp.screen_height), false)
