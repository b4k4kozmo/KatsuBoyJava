class_name Entity
extends RefCounted
## Java: entity/Entity.java - the base class for the player, NPCs, monsters,
## items, projectiles, particles and interactive tiles.

var gp

# SPRITES
var up1: Texture2D
var up2: Texture2D
var down1: Texture2D
var down2: Texture2D
var left1: Texture2D
var left2: Texture2D
var right1: Texture2D
var right2: Texture2D
var attack_up1: Texture2D
var attack_up2: Texture2D
var attack_down1: Texture2D
var attack_down2: Texture2D
var attack_left1: Texture2D
var attack_left2: Texture2D
var attack_right1: Texture2D
var attack_right2: Texture2D
var guard_up: Texture2D
var guard_down: Texture2D
var guard_left: Texture2D
var guard_right: Texture2D
var image: Texture2D
var image2: Texture2D
var image3: Texture2D

var solid_area: Rect = Rect.new(0, 0, 48, 48)
var attack_area: Rect = Rect.new(0, 0, 0, 0)
var solid_area_default_x: int
var solid_area_default_y: int
var collision_on: bool = false
var dialogues: Array = new_dialogue_table()
var attacker: Entity

# STATE
var world_x: int
var world_y: int
var direction: String = "down"
var sprite_num: int = 1
var dialogue_set: int = 0
var dialogue_index: int = 0
var collision: bool = false
var invincible: bool = false
var attacking: bool = false
var alive: bool = true
var dying: bool = false
var hp_bar_on: bool = false
var on_path: bool = false
var knock_back: bool = false
var knock_back_direction: String
var guarding: bool = false
var transparent: bool = false
var off_balance: bool = false
var loot: Entity
var opened: bool = false

# COUNTER
var sprite_counter: int = 0
var action_lock_counter: int = 0
var invincible_counter: int = 0
var shot_available_counter: int = 0
var slow_down: int = 0
var dying_counter: int = 0
var hp_bar_counter: int = 0
var knock_back_counter: int = 0
var guard_counter: int = 0
var off_balance_counter: int = 0

# CHARACTER STATUS
var name: String = ""
var default_speed: int
var speed: int
var max_life: int
var life: int
var max_mana: int
var mana: int
var ammo: int
var level: int
var strength: int
var dexterity: int
var attack: int
var defense: int
@warning_ignore("shadowed_global_identifier")
var exp: int
var next_level_exp: int
var coin: int
var motion1_duration: int
var motion2_duration: int
var sound_number: int
var prev_sound_num: int
var current_weapon: Entity
var current_shield: Entity
var current_light: Entity
var projectile: Entity

# ITEM ATTRIBUTES
var inventory: Array[Entity] = []
const MAX_INVENTORY_SIZE := 20
var value: int
var attack_value: int
var defense_value: int
var description: String = ""
var use_cost: int
var price: int
var knock_back_power: int = 0
var stackable: bool = false
var amount: int = 1
var light_radius: int

# TYPE
var type: int  # 0 = player, 1 = npc, 2 = monster
const TYPE_PLAYER := 0
const TYPE_NPC := 1
const TYPE_MONSTER := 2
const TYPE_SWORD := 3
const TYPE_AXE := 4
const TYPE_SHIELD := 5
const TYPE_CONSUMABLE := 6
const TYPE_PICKUP_ONLY := 7
const TYPE_OBSTACLE := 8
const TYPE_LIGHT := 9


func _init(gp) -> void:
	self.gp = gp


## Java: String dialogues[][] = new String[20][20] (null filled)
static func new_dialogue_table() -> Array:
	var table: Array = []
	for _i in range(20):
		var row: Array = []
		row.resize(20)
		table.append(row)
	return table


func get_left_x() -> int:
	return world_x + solid_area.x


func get_right_x() -> int:
	return world_x + solid_area.x + solid_area.width


func get_top_y() -> int:
	return world_y + solid_area.y


func get_bottom_y() -> int:
	return world_y + solid_area.y + solid_area.height


func get_col() -> int:
	return (world_x + solid_area.x) / gp.tile_size


func get_row() -> int:
	return (world_y + solid_area.y) / gp.tile_size


func get_x_distance(_entity) -> int:
	return absi(world_x - gp.player.world_x)


func get_y_distance(_entity) -> int:
	return absi(world_y - gp.player.world_y)


func get_tile_distance(target) -> int:
	return (get_x_distance(target) + get_y_distance(target)) / gp.tile_size


func get_goal_col(target) -> int:
	return (target.world_x + target.solid_area.x) / gp.tile_size


func get_goal_row(target) -> int:
	return (target.world_y + target.solid_area.y) / gp.tile_size


func reset_counter() -> void:
	sprite_counter = 0
	action_lock_counter = 0
	invincible_counter = 0
	shot_available_counter = 0
	slow_down = 0
	dying_counter = 0
	hp_bar_counter = 0
	knock_back_counter = 0
	guard_counter = 0
	off_balance_counter = 0


# --- overridden by subclasses ---
func set_loot(_loot) -> void: pass
func set_action() -> void: pass
func damage_reaction() -> void: pass
func speak() -> void: pass
func interact() -> void: pass
func use(_entity) -> bool: return false
func check_drop() -> void: pass
func get_particle_color() -> Color: return Color(0, 0, 0, 0)
func get_particle_size() -> int: return 0      # pixel size
func get_particle_speed() -> int: return 0
func get_particle_max_life() -> int: return 0


func set_sound() -> void:
	prev_sound_num = gp.ui.sound_num
	gp.ui.sound_num = sound_number


func face_player() -> void:
	match gp.player.direction:
		"up": direction = "down"
		"down": direction = "up"
		"left": direction = "right"
		"right": direction = "left"


func start_dialogue(entity, set_num: int) -> void:
	gp.game_state = gp.DIALOGUE_STATE
	gp.ui.npc = entity
	dialogue_set = set_num


func drop_item(dropped_item) -> void:
	for i in range(gp.obj[1].size()):
		if gp.obj[gp.current_map][i] == null:
			gp.obj[gp.current_map][i] = dropped_item
			gp.obj[gp.current_map][i].world_x = world_x
			gp.obj[gp.current_map][i].world_y = world_y
			break


func generate_particle(generator, target) -> void:
	var color: Color = generator.get_particle_color()
	var size: int = generator.get_particle_size()
	var particle_speed: int = generator.get_particle_speed()
	var particle_max_life: int = generator.get_particle_max_life()

	var p1 := Particle.new(gp, target, color, size, particle_speed, particle_max_life, 2, -1)
	var p2 := Particle.new(gp, target, color, size, particle_speed, particle_max_life, -2, 1)
	var p3 := Particle.new(gp, target, color, size, particle_speed, particle_max_life, -2, -1)
	var p4 := Particle.new(gp, target, color, size, particle_speed, particle_max_life, 2, 1)
	gp.particle_list.append(p1)
	gp.particle_list.append(p2)
	gp.particle_list.append(p3)
	gp.particle_list.append(p4)


func check_collision() -> void:
	collision_on = false
	gp.c_checker.check_tile(self)
	gp.c_checker.check_object(self, false)
	gp.c_checker.check_entity(self, gp.npc)
	gp.c_checker.check_entity(self, gp.monster)
	gp.c_checker.check_entity(self, gp.i_tile)
	var contact_player: bool = gp.c_checker.check_player(self)

	if type == TYPE_MONSTER and contact_player == true:
		damage_player(attack)


func update() -> void:

	if knock_back == true:

		check_collision()

		if collision_on == true:
			knock_back_counter = 0
			knock_back = false
			speed = default_speed
		else:
			match knock_back_direction:
				"up": world_y -= speed
				"down": world_y += speed
				"left": world_x -= speed
				"right": world_x += speed

		knock_back_counter += 1
		if knock_back_counter == 10:
			knock_back_counter = 0
			knock_back = false
			speed = default_speed

	elif attacking == true:
		do_attacking()

	else:
		set_action()
		check_collision()

		# IF COLLISION IS FALSE, ENTITY CAN MOVE
		if collision_on == false:
			match direction:
				"up": world_y -= speed
				"down": world_y += speed
				"left": world_x -= speed
				"right": world_x += speed

		sprite_counter += 1
		if sprite_counter > 24:
			if sprite_num == 1:
				sprite_num = 2
			elif sprite_num == 2:
				sprite_num = 1
			sprite_counter = 0

	if invincible == true:
		invincible_counter += 1
		if invincible_counter > 30:
			invincible = false
			invincible_counter = 0

	if shot_available_counter < 30:
		shot_available_counter += 1

	if off_balance == true:
		off_balance_counter += 1
		if off_balance_counter > 60:
			off_balance = false
			off_balance_counter = 0


func check_attacking(rate: int, straight: int, horizontal: int) -> void:
	var target_in_range := false
	var x_dis: int = get_x_distance(gp.player)
	var y_dis: int = get_y_distance(gp.player)

	match direction:
		"up":
			if gp.player.world_y < world_y and y_dis < straight and x_dis < horizontal:
				target_in_range = true
		"down":
			if gp.player.world_y > world_y and y_dis < straight and x_dis < horizontal:
				target_in_range = true
		"left":
			if gp.player.world_x < world_x and x_dis < straight and y_dis < horizontal:
				target_in_range = true
		"right":
			if gp.player.world_x > world_x and x_dis < straight and y_dis < horizontal:
				target_in_range = true

	if target_in_range == true:
		# Check if it initiates an attack
		var i: int = randi() % rate
		if i == 0:
			attacking = true
			sprite_num = 1
			sprite_counter = 0
			shot_available_counter = 0


func check_shooting(rate: int, shot_interval: int) -> void:
	var i: int = randi() % rate + 1
	if i == 1 and projectile.alive == false and shot_available_counter == shot_interval:

		projectile.set_projectile(world_x, world_y, direction, true, self)

		# CHECK VACANCY
		for ii in range(gp.projectile[1].size()):
			if gp.projectile[gp.current_map][ii] == null:
				gp.projectile[gp.current_map][ii] = projectile
				break

		shot_available_counter = 0


func check_start_chasing(target, distance: int, rate: int) -> void:
	if get_tile_distance(target) < distance:
		if randi() % rate == 0:
			on_path = true


func check_stop_chasing(target, distance: int, rate: int) -> void:
	if get_tile_distance(target) > distance:
		if randi() % rate == 0:
			on_path = false


func get_random_direction() -> void:
	action_lock_counter += 1

	if action_lock_counter == 120:
		var i: int = randi() % 100 + 1  # pick a number between 1 and 100

		if i < 25: direction = "up"
		if i > 25 and i <= 50: direction = "down"
		if i > 50 and i <= 75: direction = "left"
		if i > 75 and i <= 100: direction = "right"
		action_lock_counter = 0


func get_opposite_direction(dir: String) -> String:
	match dir:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
	return ""


## Java: Entity.attacking() - renamed because "attacking" is also a field here.
func do_attacking() -> void:

	sprite_counter += 1

	if sprite_counter <= motion1_duration:
		sprite_num = 1

	if sprite_counter > motion1_duration and sprite_counter <= motion2_duration:
		sprite_num = 2

		# Save the current x, y, solid_area
		var current_world_x: int = world_x
		var current_world_y: int = world_y
		var solid_area_width: int = solid_area.width
		var solid_area_height: int = solid_area.height

		# Adjust the entity's world_x/y for the attack_area
		match direction:
			"up": world_y -= attack_area.height
			"down": world_y += attack_area.height
			"left": world_x -= attack_area.width
			"right": world_x += attack_area.width

		# attack_area becomes solid_area
		solid_area.width = attack_area.width
		solid_area.height = attack_area.height

		if type == TYPE_MONSTER:
			if gp.c_checker.check_player(self) == true:
				damage_player(attack)
		else:  # player
			# Check monster collision with the updated world_x, world_y and solid_area
			var monster_index: int = gp.c_checker.check_entity(self, gp.monster)
			gp.player.damage_monster(monster_index, self, attack, current_weapon.knock_back_power)

			var i_tile_index: int = gp.c_checker.check_entity(self, gp.i_tile)
			gp.player.damage_interactive_tile(i_tile_index)

			# ATTACKING PROJECTILE
			var projectile_index: int = gp.c_checker.check_entity(self, gp.projectile)
			gp.player.damage_projectile(projectile_index)

		# Restore values to the saved values prior to collision
		world_x = current_world_x
		world_y = current_world_y
		solid_area.width = solid_area_width
		solid_area.height = solid_area_height

	if sprite_counter > motion2_duration:
		sprite_num = 1
		sprite_counter = 0
		attacking = false


func damage_player(atk: int) -> void:
	if gp.player.invincible == false:

		var damage: int = atk - gp.player.defense

		# Get an opposite direction of the attacker
		var can_guard_direction: String = get_opposite_direction(direction)

		if gp.player.guarding == true and gp.player.direction == can_guard_direction:

			# Parry
			if gp.player.guard_counter < 10:
				damage = 0
				gp.play_se(SE.PARRY)
				set_knock_back(self, gp.player, knock_back_power)
				off_balance = true
				sprite_counter = -60
			else:
				# Normal Guard
				@warning_ignore("integer_division")
				damage = damage / 3
				gp.play_se(SE.BLOCK)
				@warning_ignore("integer_division")
				set_knock_back(gp.player, self, knock_back_power / 5)

		else:
			# Not guarding
			gp.play_se(SE.RECEIVE_DAMAGE)
			if damage < 1:
				damage = 1

		if damage != 0:
			gp.player.transparent = true
			set_knock_back(gp.player, self, knock_back_power)

		gp.player.life -= damage
		gp.player.invincible = true


func set_knock_back(target, atkr, power: int) -> void:
	self.attacker = atkr
	target.knock_back_direction = atkr.direction
	target.speed += power
	target.knock_back = true


func draw(g2) -> void:

	var img: Texture2D = null

	var screen_x: int = world_x - gp.player.world_x + gp.player.screen_x
	var screen_y: int = world_y - gp.player.world_y + gp.player.screen_y

	if (world_x + gp.tile_size > gp.player.world_x - gp.player.screen_x
			and world_x - gp.tile_size < gp.player.world_x + gp.player.screen_x
			and world_y + gp.tile_size > gp.player.world_y - gp.player.screen_y
			and world_y - gp.tile_size < gp.player.world_y + gp.player.screen_y):

		var temp_screen_x: int = screen_x
		var temp_screen_y: int = screen_y

		match direction:
			"up":
				if attacking == false:
					if sprite_num == 1: img = up1
					if sprite_num == 2: img = up2
				if attacking == true:
					temp_screen_y = screen_y - gp.tile_size
					if sprite_num == 1: img = attack_up1
					if sprite_num == 2: img = attack_up2
			"down":
				if attacking == false:
					if sprite_num == 1: img = down1
					if sprite_num == 2: img = down2
				if attacking == true:
					if sprite_num == 1: img = attack_down1
					if sprite_num == 2: img = attack_down2
			"left":
				if attacking == false:
					if sprite_num == 1: img = left1
					if sprite_num == 2: img = left2
				if attacking == true:
					temp_screen_x = screen_x - gp.tile_size
					if sprite_num == 1: img = attack_left1
					if sprite_num == 2: img = attack_left2
			"right":
				if attacking == false:
					if sprite_num == 1: img = right1
					if sprite_num == 2: img = right2
				if attacking == true:
					if sprite_num == 1: img = attack_right1
					if sprite_num == 2: img = attack_right2

		# Monster HP bar
		if type == TYPE_MONSTER and hp_bar_on == true:

			var one_scale: float = float(gp.tile_size) / max_life
			var hp_bar_value: float = one_scale * life

			g2.set_color(gp.ui.kamiblack)
			g2.fill_rect(screen_x - 1, screen_y - 16, gp.tile_size + 2, 12)

			g2.set_color(gp.ui.kamigreen)
			g2.fill_rect(screen_x, screen_y - 15, int(hp_bar_value), 10)

			hp_bar_counter += 1
			if hp_bar_counter > 600:
				hp_bar_counter = 0
				hp_bar_on = false

		if invincible == true:
			hp_bar_on = true
			hp_bar_counter = 0
			g2.change_alpha(0.4)

		if dying == true:
			dying_animation(g2)
			hp_bar_on = false

		g2.draw_img(img, temp_screen_x, temp_screen_y)

		g2.change_alpha(1.0)


func dying_animation(g2) -> void:

	dying_counter += 1

	var i := 5

	if dying_counter <= i: g2.change_alpha(0.0)
	if dying_counter > i and dying_counter <= i * 2: g2.change_alpha(1.0)
	if dying_counter > i * 2 and dying_counter <= i * 3: g2.change_alpha(0.0)
	if dying_counter > i * 3 and dying_counter <= i * 4: g2.change_alpha(1.0)
	if dying_counter > i * 4 and dying_counter <= i * 5: g2.change_alpha(0.0)
	if dying_counter > i * 5 and dying_counter <= i * 6: g2.change_alpha(1.0)
	if dying_counter > i * 6 and dying_counter <= i * 7: g2.change_alpha(0.0)
	if dying_counter > i * 7 and dying_counter <= i * 8: g2.change_alpha(1.0)
	if dying_counter > i * 8:
		dying = false
		alive = false


## Java: setup(imagePath, width, height) - load the sprite and pre-scale it.
func setup(image_path: String, width: int, height: int) -> Texture2D:
	var u_tool := UtilityTool.new()
	var texture: Texture2D = load("res://assets" + image_path + ".png")
	if texture == null:
		push_warning("Missing sprite: res://assets" + image_path + ".png")
		return null
	return u_tool.scale_image(texture, width, height)


func search_path(goal_col: int, goal_row: int) -> void:

	var start_col: int = (world_x + solid_area.x) / gp.tile_size
	var start_row: int = (world_y + solid_area.y) / gp.tile_size

	gp.p_finder.set_nodes(start_col, start_row, goal_col, goal_row)

	if gp.p_finder.search() == true:

		# Next world_x & world_y
		var next_x: int = gp.p_finder.path_list[0].col * gp.tile_size
		var next_y: int = gp.p_finder.path_list[0].row * gp.tile_size

		# Entity's solid_area position
		var en_left_x: int = world_x + solid_area.x
		var en_right_x: int = world_x + solid_area.x + solid_area.width
		var en_top_y: int = world_y + solid_area.y
		var en_bottom_y: int = world_y + solid_area.y + solid_area.height

		if en_top_y > next_y and en_left_x >= next_x and en_right_x < next_x + gp.tile_size:
			direction = "up"
		elif en_top_y < next_y and en_left_x >= next_x and en_right_x < next_x + gp.tile_size:
			direction = "down"
		elif en_top_y >= next_y and en_bottom_y < next_y + gp.tile_size:
			# left or right
			if en_left_x > next_x:
				direction = "left"
			if en_left_x < next_x:
				direction = "right"
		elif en_top_y > next_y and en_left_x > next_x:
			# up or left
			direction = "up"
			check_collision()
			if collision_on == true:
				direction = "left"
		elif en_top_y > next_y and en_left_x < next_x:
			# up or right
			direction = "up"
			check_collision()
			if collision_on == true:
				direction = "right"
		elif en_top_y < next_y and en_left_x > next_x:
			# down or left
			direction = "down"
			check_collision()
			if collision_on == true:
				direction = "left"
		elif en_top_y < next_y and en_left_x < next_x:
			# down or right
			direction = "down"
			check_collision()
			if collision_on == true:
				direction = "right"


func get_detected(user, target: Array, target_name: String) -> int:

	var index := 999
	# Check the surrounding object
	var next_world_x: int = user.get_right_x()
	var next_world_y: int = user.get_top_y()

	match user.direction:
		"up": next_world_y = user.get_top_y() - gp.player.speed
		"down": next_world_y = user.get_bottom_y() + gp.player.speed
		"left": next_world_x = user.get_left_x() - gp.player.speed
		"right": next_world_x = user.get_right_x() + gp.player.speed

	var col: int = next_world_x / gp.tile_size
	var row: int = next_world_y / gp.tile_size

	for i in range(target[1].size()):
		if target[gp.current_map][i] != null:
			if (target[gp.current_map][i].get_col() == col
					and target[gp.current_map][i].get_row() == row
					and target[gp.current_map][i].name == target_name):
				index = i
				break
	return index
