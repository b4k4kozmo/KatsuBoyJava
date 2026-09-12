class_name IT_Trunk
extends InteractiveTile
## Java: tile_interactive/IT_Trunk.java


func _init(gp, col: int, row: int) -> void:
	super(gp, col, row)

	self.world_x = gp.tile_size * col
	self.world_y = gp.tile_size * row

	down1 = setup("/tiles_interactive/trunk", gp.tile_size, gp.tile_size)

	# A zero sized solid area never intersects anything, so the stump can be
	# walked over (same as java.awt.Rectangle.intersects()).
	solid_area.x = 0
	solid_area.y = 0
	solid_area.width = 0
	solid_area.height = 0
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
