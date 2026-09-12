class_name IT_DryTree
extends InteractiveTile
## Java: tile_interactive/IT_DryTree.java


func _init(gp, col: int, row: int) -> void:
	super(gp, col, row)

	self.world_x = gp.tile_size * col
	self.world_y = gp.tile_size * row

	down1 = setup("/tiles_interactive/drytree", gp.tile_size, gp.tile_size)
	destructable = true
	life = 3


func is_correct_item(entity) -> bool:
	var result := false
	if entity.current_weapon.type == TYPE_AXE:
		result = true
	return result


func play_se() -> void:
	gp.play_se(SE.SWING_WEAPON)


func get_destroyed_form() -> InteractiveTile:
	@warning_ignore("integer_division")
	return IT_Trunk.new(gp, world_x / gp.tile_size, world_y / gp.tile_size)


func get_particle_color() -> Color: return gp.ui.kamiblack
func get_particle_size() -> int: return 6  # pixel size
func get_particle_speed() -> int: return 1
func get_particle_max_life() -> int: return 20
