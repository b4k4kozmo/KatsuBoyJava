class_name OBJ_Snowball
extends Projectile
## Java: object/OBJ_Snowball.java

const OBJ_NAME := "Snow-ball"


func _init(gp) -> void:
	super(gp)

	name = OBJ_NAME
	speed = 4
	max_life = 100
	life = max_life
	attack = 3
	use_cost = 1
	alive = false
	price = 10
	get_image()
	knock_back_power = 1


func get_image() -> void:
	up1 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	up2 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	down1 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	down2 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	left1 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	left2 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	right1 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)
	right2 = setup("/projectile/snowball1", gp.tile_size, gp.tile_size)


func have_resource(user) -> bool:
	var result := false
	if user.ammo >= use_cost:
		result = true
	return result


func subtract_resource(user) -> void:
	user.ammo -= use_cost


func get_particle_color() -> Color: return gp.ui.kamiwhite
func get_particle_size() -> int: return 10  # pixel size
func get_particle_speed() -> int: return 1
func get_particle_max_life() -> int: return 20
