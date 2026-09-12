class_name HudLayer
extends Graphics2D
## Everything drawn in screen space and on top of the world: the mini map, the
## HUD, every menu, and the debug readout.
##
## Split out from GamePanel so the lighting and effect layers can sit between
## the world and the UI - the darkness has to fall on the world without dimming
## the health bar.

var gp


func _ready() -> void:
	gp = get_parent()
	z_index = 10


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:

	if gp == null or gp.ui == null:
		return

	reset_pen()

	# TITLE SCREEN
	if gp.game_state == gp.TITLE_STATE:
		gp.ui.draw(self)
	# MAP SCREEN
	elif gp.game_state == gp.MAP_STATE:
		gp.map.draw_full_map_screen(self)
	# OTHERS
	else:
		gp.map.draw_mini_map(self)
		gp.ui.draw(self)

	# DEBUG
	if gp.key_h.check_draw_time == true:
		set_font(gp.ui.maru_monica, 24)
		set_color(gp.ui.kamiblack)
		draw_str("Col: " + str(gp.player.world_x / 48), 12, 434)
		draw_str("Row: " + str(gp.player.world_y / 48), 12, 466)
		draw_str("WorldX: " + str(gp.player.world_x), 12, 498)
		draw_str("WorldY: " + str(gp.player.world_y), 12, 530)

		set_color(gp.ui.kamiwhite)
		draw_str("Col: " + str(gp.player.world_x / 48), 10, 432)
		draw_str("Row: " + str(gp.player.world_y / 48), 10, 464)
		draw_str("WorldX: " + str(gp.player.world_x), 10, 496)
		draw_str("WorldY: " + str(gp.player.world_y), 10, 528)
