class_name Particle
extends Entity
## Java: entity/Particle.java

var generator
var color: Color
var size: int
var xd: int
var yd: int


func _init(gp, generator, color: Color, size: int, speed: int, max_life: int, xd: int, yd: int) -> void:
	super(gp)
	self.generator = generator
	self.color = color
	self.size = size
	self.speed = speed
	self.max_life = max_life
	self.xd = xd
	self.yd = yd

	life = max_life
	@warning_ignore("integer_division")
	var offset: int = (gp.tile_size / 2) - (size / 2)
	world_x = generator.world_x + offset
	world_y = generator.world_y + offset


func update() -> void:
	life -= 1

	@warning_ignore("integer_division")
	if life < max_life / 3:
		yd += 1

	world_x += xd * speed
	world_y += yd * speed
	if life == 0:
		alive = false


func draw(g2) -> void:

	var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
	var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

	g2.set_color(color)
	g2.fill_rect(screen_x, screen_y, size, size)
