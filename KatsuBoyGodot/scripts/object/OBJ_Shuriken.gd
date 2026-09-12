class_name OBJ_Shuriken
extends Projectile
## Java: object/OBJ_Shuriken.java

const OBJ_NAME := "Shuriken"


func _init(gp) -> void:
	super(gp)

	name = OBJ_NAME
	speed = 12
	max_life = 80
	life = max_life
	attack = 3
	use_cost = 1
	alive = false
	price = 10
	get_image()
	knock_back_power = 3


func get_image() -> void:
	up1 = setup("/projectile/shuriken_down1", gp.tile_size, gp.tile_size)
	up2 = setup("/projectile/shuriken_down2", gp.tile_size, gp.tile_size)
	down1 = setup("/projectile/shuriken_down1", gp.tile_size, gp.tile_size)
	down2 = setup("/projectile/shuriken_down2", gp.tile_size, gp.tile_size)
	left1 = setup("/projectile/shuriken_down1", gp.tile_size, gp.tile_size)
	left2 = setup("/projectile/shuriken_down2", gp.tile_size, gp.tile_size)
	right1 = setup("/projectile/shuriken_down1", gp.tile_size, gp.tile_size)
	right2 = setup("/projectile/shuriken_down2", gp.tile_size, gp.tile_size)


func have_resource(user) -> bool:
	var result := false
	if user.mana >= use_cost:
		result = true
	return result


func subtract_resource(user) -> void:
	user.mana -= use_cost


func get_particle_color() -> Color: return gp.ui.kamipink
func get_particle_size() -> int: return 10  # pixel size
func get_particle_speed() -> int: return 1
func get_particle_max_life() -> int: return 20
