class_name Projectile
extends Entity
## Java: entity/Projectile.java

var user


func _init(gp) -> void:
	super(gp)


## Java: set(...) - renamed because set() is an Object method in Godot.
func set_projectile(world_x: int, world_y: int, direction: String, alive: bool, user) -> void:
	self.world_x = world_x
	self.world_y = world_y
	self.direction = direction
	self.alive = alive
	self.user = user
	self.life = self.max_life


func update() -> void:

	if user == gp.player:
		var monster_index: int = gp.c_checker.check_entity(self, gp.monster)
		if monster_index != 999:
			gp.player.damage_monster(monster_index, self, gp.player.ranged_attack(self), knock_back_power)
			generate_particle(user.projectile, gp.monster[gp.current_map][monster_index])
			alive = false

	if user != gp.player:
		var contact_player: bool = gp.c_checker.check_player(self)
		if gp.player.invincible == false and contact_player == true:
			damage_player(attack)
			generate_particle(user.projectile, user.projectile)
			alive = false

	match direction:
		"up": world_y -= speed
		"down": world_y += speed
		"left": world_x -= speed
		"right": world_x += speed

	life -= 1
	if life <= 0:
		alive = false

	sprite_counter += 1
	if sprite_counter > 6:
		if sprite_num == 1:
			sprite_num = 2
		elif sprite_num == 2:
			sprite_num = 1
		sprite_counter = 0


func have_resource(_user) -> bool:
	return false


func subtract_resource(_user) -> void:
	pass
