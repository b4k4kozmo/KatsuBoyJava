class_name InteractiveTile
extends Entity
## Java: tile_interactive/InteractiveTile.java

var destructable: bool = false


func _init(gp, _col: int, _row: int) -> void:
	super(gp)


func is_correct_item(_entity) -> bool:
	return false


func play_se() -> void:
	pass


func get_destroyed_form() -> InteractiveTile:
	return null


func update() -> void:
	if invincible == true:
		invincible_counter += 1
		if invincible_counter > 20:
			invincible = false
			invincible_counter = 0


# disable this method if you want a transparent effect on attack
func draw(g2) -> void:

	var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
	var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

	if (world_x + gp.tile_size > gp.player.world_x - gp.player.screen_x
			and world_x - gp.tile_size < gp.player.world_x + gp.player.screen_x
			and world_y + gp.tile_size > gp.player.world_y - gp.player.screen_y
			and world_y - gp.tile_size < gp.player.world_y + gp.player.screen_y):

		g2.draw_img(down1, screen_x, screen_y)
