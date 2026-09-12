class_name Player
extends Entity
## Java: entity/Player.java

var key_h: KeyHandler
var screen_x: int
var screen_y: int
var stand_counter: int = 0
var has_boots: bool = false
var attack_canceled: bool = false
var light_updated: bool = false
var is_cursed: bool = false


func _init(gp, key_h: KeyHandler) -> void:
	super(gp)

	self.key_h = key_h

	@warning_ignore("integer_division")
	screen_x = gp.screen_width / 2 - (gp.tile_size / 2)
	@warning_ignore("integer_division")
	screen_y = gp.screen_height / 2 - (gp.tile_size / 2)

	solid_area = Rect.new()
	solid_area.x = 8
	solid_area.y = 16
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y
	solid_area.width = 32
	solid_area.height = 32

	set_default_values()


func set_default_values() -> void:

	world_x = gp.tile_size * 94
	world_y = gp.tile_size * 94
	default_speed = 4
	speed = default_speed
	direction = "down"

	# PLAYER STATUS
	level = 1
	max_life = 6
	life = max_life
	max_mana = 4
	mana = max_mana
	ammo = 10
	strength = 1   # the more strength he has the more damage he gives
	dexterity = 1  # the more dexterity he has, the less damage he receives
	exp = 0
	next_level_exp = 5
	coin = 999
	current_weapon = OBJ_Sword_Normal.new(gp)
	current_shield = OBJ_Shield_Puffa.new(gp)
	current_light = null
	# runs on mana
	projectile = OBJ_Shuriken.new(gp)
	# runs on ammo
#	projectile = OBJ_Snowball.new(gp)
	attack = get_attack()    # the total attack value is decided by strength and weapon
	defense = get_defense()  # the total defense value is decided by dexterity and shield

	get_image()
	get_attack_image()
	get_guard_image()
	set_items()


func set_default_positions() -> void:
	world_x = gp.tile_size * 94
	world_y = gp.tile_size * 94
	direction = "down"


func set_dialogue() -> void:
	dialogues[0][0] = "You are now " + str(level) + "!\nYou can feel the power!"


func restore_status() -> void:
	life = max_life
	mana = max_mana
	speed = default_speed
	invincible = false
	transparent = false
	attacking = false
	knock_back = false
	light_updated = true


func set_items() -> void:
	inventory.clear()
	get_attack_image()
	inventory.append(current_weapon)
	inventory.append(current_shield)


func get_attack() -> int:
	attack_area = current_weapon.attack_area
	motion1_duration = current_weapon.motion1_duration
	motion2_duration = current_weapon.motion2_duration
	attack = strength * current_weapon.attack_value
	return attack


func get_defense() -> int:
	defense = dexterity * current_shield.defense_value
	return defense


func get_current_weapon_slot() -> int:
	var current_weapon_slot := 0
	for i in range(inventory.size()):
		if inventory[i] == current_weapon:
			current_weapon_slot = i
	return current_weapon_slot


func get_current_shield_slot() -> int:
	var current_shield_slot := 0
	for i in range(inventory.size()):
		if inventory[i] == current_shield:
			current_shield_slot = i
	return current_shield_slot


func get_image() -> void:
	up1 = setup("/player/boy_up_1", gp.tile_size, gp.tile_size)
	up2 = setup("/player/boy_up_2", gp.tile_size, gp.tile_size)
	down1 = setup("/player/boy_down_1", gp.tile_size, gp.tile_size)
	down2 = setup("/player/boy_down_2", gp.tile_size, gp.tile_size)
	left1 = setup("/player/boy_left_1", gp.tile_size, gp.tile_size)
	left2 = setup("/player/boy_left_2", gp.tile_size, gp.tile_size)
	right1 = setup("/player/boy_right_1", gp.tile_size, gp.tile_size)
	right2 = setup("/player/boy_right_2", gp.tile_size, gp.tile_size)


func get_sleeping_image(img: Texture2D) -> void:
	up1 = img
	up2 = img
	down1 = img
	down2 = img
	left1 = img
	left2 = img
	right1 = img
	right2 = img


func get_attack_image() -> void:

	if current_weapon.name == "Normal Sword":
		attack_up1 = setup("/player/boy_up_attack_1", gp.tile_size, gp.tile_size * 2)
		attack_up2 = setup("/player/boy_up_attack_2", gp.tile_size, gp.tile_size * 2)
		attack_down1 = setup("/player/boy_down_attack_1", gp.tile_size, gp.tile_size * 2)
		attack_down2 = setup("/player/boy_down_attack_2", gp.tile_size, gp.tile_size * 2)
		attack_left1 = setup("/player/boy_left_attack_1", gp.tile_size * 2, gp.tile_size)
		attack_left2 = setup("/player/boy_left_attack_2", gp.tile_size * 2, gp.tile_size)
		attack_right1 = setup("/player/boy_right_attack_1", gp.tile_size * 2, gp.tile_size)
		attack_right2 = setup("/player/boy_right_attack_2", gp.tile_size * 2, gp.tile_size)

	if current_weapon.name == "Kami no Bokken":
		attack_up1 = setup("/player/boy_up_bokken_1", gp.tile_size, gp.tile_size * 2)
		attack_up2 = setup("/player/boy_up_bokken_2", gp.tile_size, gp.tile_size * 2)
		attack_down1 = setup("/player/boy_down_bokken_1", gp.tile_size, gp.tile_size * 2)
		attack_down2 = setup("/player/boy_down_bokken_2", gp.tile_size, gp.tile_size * 2)
		attack_left1 = setup("/player/boy_left_bokken_1", gp.tile_size * 2, gp.tile_size)
		attack_left2 = setup("/player/boy_left_bokken_2", gp.tile_size * 2, gp.tile_size)
		attack_right1 = setup("/player/boy_right_bokken_1", gp.tile_size * 2, gp.tile_size)
		attack_right2 = setup("/player/boy_right_bokken_2", gp.tile_size * 2, gp.tile_size)

	if current_weapon.type == TYPE_AXE:
		attack_up1 = setup("/player/boy_up_axe_1", gp.tile_size, gp.tile_size * 2)
		attack_up2 = setup("/player/boy_up_axe_2", gp.tile_size, gp.tile_size * 2)
		attack_down1 = setup("/player/boy_down_axe_1", gp.tile_size, gp.tile_size * 2)
		attack_down2 = setup("/player/boy_down_axe_2", gp.tile_size, gp.tile_size * 2)
		attack_left1 = setup("/player/boy_left_axe_1", gp.tile_size * 2, gp.tile_size)
		attack_left2 = setup("/player/boy_left_axe_2", gp.tile_size * 2, gp.tile_size)
		attack_right1 = setup("/player/boy_right_axe_1", gp.tile_size * 2, gp.tile_size)
		attack_right2 = setup("/player/boy_right_axe_2", gp.tile_size * 2, gp.tile_size)


func get_guard_image() -> void:
	guard_up = setup("/player/guard_boy_up", gp.tile_size, gp.tile_size)
	guard_down = setup("/player/guard_boy_down", gp.tile_size, gp.tile_size)
	guard_left = setup("/player/guard_boy_left", gp.tile_size, gp.tile_size)
	guard_right = setup("/player/guard_boy_right", gp.tile_size, gp.tile_size)


func update() -> void:

	if knock_back == true:

		collision_on = false
		gp.c_checker.check_tile(self)
		gp.c_checker.check_object(self, true)
		gp.c_checker.check_entity(self, gp.npc)
		gp.c_checker.check_entity(self, gp.monster)
		gp.c_checker.check_entity(self, gp.i_tile)

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

	elif key_h.control_pressed == true:
		guarding = true
		guard_counter += 1

	elif (key_h.up_pressed == true or key_h.down_pressed == true
			or key_h.left_pressed == true or key_h.right_pressed == true
			or key_h.enter_pressed == true):

		if key_h.up_pressed == true:
			direction = "up"
		elif key_h.down_pressed == true:
			direction = "down"
		elif key_h.left_pressed == true:
			direction = "left"
		elif key_h.right_pressed == true:
			direction = "right"

		# Shift run
		if key_h.shift_pressed == true and has_boots == true:
			speed = 10
		elif key_h.shift_pressed == false and has_boots == true:
			speed = 6

		# CHECK TILE COLLISION
		collision_on = false
		gp.c_checker.check_tile(self)

		# CHECK OBJECT COLLISION
		var obj_index: int = gp.c_checker.check_object(self, true)
		pick_up_object(obj_index)

		# CHECK NPC COLLISION
		var npc_index: int = gp.c_checker.check_entity(self, gp.npc)
		interact_npc(npc_index)

		# CHECK MONSTER COLLISION
		var monster_index: int = gp.c_checker.check_entity(self, gp.monster)
		contact_monster(monster_index)

		# CHECK INTERACTIVE TILE COLLISION
		gp.c_checker.check_entity(self, gp.i_tile)

		# CHECK EVENT
		gp.e_handler.check_event()

		# IF COLLISION IS FALSE, PLAYER CAN MOVE
		if collision_on == false and key_h.enter_pressed == false:
			match direction:
				"up": world_y -= speed
				"down": world_y += speed
				"left": world_x -= speed
				"right": world_x += speed

		if key_h.enter_pressed == true and attack_canceled == false:
			gp.play_se(8)
			attacking = true
			sprite_counter = 0

		attack_canceled = false
		gp.key_h.enter_pressed = false
		guarding = false
		guard_counter = 0

		sprite_counter += 1
		if sprite_counter > 12:
			if sprite_num == 1:
				sprite_num = 2
			elif sprite_num == 2:
				sprite_num = 1
			sprite_counter = 0

	else:
		stand_counter += 1
		if stand_counter == 20:
			sprite_num = 1
			stand_counter = 0
		guarding = false
		guard_counter = 0

	if (gp.key_h.shot_key_pressed == true and projectile.alive == false
			and shot_available_counter == 30 and projectile.have_resource(self) == true):

		# SET DEFAULT COORDINATES, DIRECTION AND USER
		projectile.set_projectile(world_x, world_y, direction, true, self)

		# SUBTRACT THE COST (MANA, AMMO)
		projectile.subtract_resource(self)

		# CHECK VACANCY
		for i in range(gp.projectile[1].size()):
			if gp.projectile[gp.current_map][i] == null:
				gp.projectile[gp.current_map][i] = projectile
				break

		shot_available_counter = 0

		gp.play_se(8)

	# This needs to be outside the key if statement!
	if invincible == true:
		invincible_counter += 1
		if invincible_counter > 60:
			invincible = false
			transparent = false
			invincible_counter = 0

	if shot_available_counter < 30:
		shot_available_counter += 1

	if life > max_life:
		life = max_life
	if mana > max_mana:
		mana = max_mana

	if life <= 0:
		gp.game_state = gp.GAME_OVER_STATE
		gp.ui.command_num = -1
		gp.stop_se()
		gp.stop_music()
		gp.play_se(12)


func pick_up_object(i: int) -> void:

	if i != 999:

		# PICKUP ONLY ITEMS
		if gp.obj[gp.current_map][i].type == TYPE_PICKUP_ONLY:
			gp.obj[gp.current_map][i].use(self)
			gp.obj[gp.current_map][i] = null

		# OBSTACLE
		elif gp.obj[gp.current_map][i].type == TYPE_OBSTACLE:
			if key_h.enter_pressed == true:
				attack_canceled = true
				gp.obj[gp.current_map][i].interact()

		# INVENTORY ITEMS
		else:
			var text: String
			if can_obtain_item(gp.obj[gp.current_map][i]) == true:
				gp.play_se(1)
				text = "Got a " + gp.obj[gp.current_map][i].name + "!"
			else:
				text = "Your inventory is full!"
			gp.ui.add_message(text)
			gp.obj[gp.current_map][i] = null


func interact_npc(i: int) -> void:
	if i != 999:
		if gp.key_h.enter_pressed == true:
			attack_canceled = true
			gp.stop_se()
			gp.play_se(10)
			gp.npc[gp.current_map][i].speak()
			gp.key_h.enter_pressed = false


func contact_monster(i: int) -> void:

	if i != 999:
		if invincible == false:
			if gp.monster[gp.current_map][i].life > 0:
				gp.play_se(7)

				var damage: int = gp.monster[gp.current_map][i].attack - defense
				if damage < 1:
					damage = 1

				life -= damage
				invincible = true
				transparent = true
				if gp.e_manager.lighting.day_state == gp.e_manager.lighting.NIGHT:
					is_cursed = true


func damage_monster(i: int, atkr, atk: int, knock_back_power: int) -> void:

	if i != 999:

		if gp.monster[gp.current_map][i].invincible == false:

			gp.play_se(6)
			if knock_back_power > 0:
				set_knock_back(gp.monster[gp.current_map][i], atkr, knock_back_power)

			if gp.monster[gp.current_map][i].off_balance == true:
				atk *= 3

			var damage: int = atk - gp.monster[gp.current_map][i].defense
			if damage < 0:
				damage = 0

			gp.monster[gp.current_map][i].life -= damage
			gp.ui.add_message(str(damage) + " damage!")

			gp.monster[gp.current_map][i].invincible = true
			gp.monster[gp.current_map][i].damage_reaction()

			if gp.monster[gp.current_map][i].life <= 0:
				gp.monster[gp.current_map][i].dying = true
				gp.stop_se()
				gp.play_se(9)
				gp.ui.add_message("Killed the " + gp.monster[gp.current_map][i].name + "!")
				gp.ui.add_message("Gained " + str(gp.monster[gp.current_map][i].exp) + " exp!")
				exp += gp.monster[gp.current_map][i].exp
				check_level_up()


func damage_interactive_tile(i: int) -> void:
	if (i != 999 and gp.i_tile[gp.current_map][i].destructable == true
			and gp.i_tile[gp.current_map][i].is_correct_item(self) == true
			and gp.i_tile[gp.current_map][i].invincible == false):

		gp.i_tile[gp.current_map][i].play_se()
		gp.i_tile[gp.current_map][i].life -= 1
		gp.i_tile[gp.current_map][i].invincible = true

		# Generate particle
		generate_particle(gp.i_tile[gp.current_map][i], gp.i_tile[gp.current_map][i])

		if gp.i_tile[gp.current_map][i].life == 0:
			gp.i_tile[gp.current_map][i] = gp.i_tile[gp.current_map][i].get_destroyed_form()
			gp.p_finder.solid_dirty = true  # the pathfinder can route through it now


func damage_projectile(i: int) -> void:
	if i != 999:
		var proj = gp.projectile[gp.current_map][i]
		proj.alive = false
		generate_particle(proj, proj)


func check_level_up() -> void:

	while exp >= next_level_exp:
		gp.ui.add_message("Level up!")
		level += 1
		next_level_exp *= 3
		max_life += 2
		if level % 2 == 0:
			max_mana += 1
		life = max_life
		mana = max_mana
		strength += 1
		dexterity += 1
		attack = get_attack()
		defense = get_defense()  # Java had get_attack() here - clearly a typo
		gp.stop_se()
		gp.play_se(4)

		set_dialogue()
		start_dialogue(self, 0)


func select_item() -> void:

	var item_index: int = gp.ui.get_item_index_on_slot(gp.ui.player_slot_col, gp.ui.player_slot_row)

	if item_index < inventory.size():

		var selected_item: Entity = inventory[item_index]

		if selected_item.type == TYPE_SWORD or selected_item.type == TYPE_AXE:
			current_weapon = selected_item
			attack = get_attack()
			get_attack_image()

		if selected_item.type == TYPE_SHIELD:
			current_shield = selected_item
			defense = get_defense()

		if selected_item.type == TYPE_LIGHT:
			if current_light == selected_item:
				current_light = null
			else:
				current_light = selected_item
			light_updated = true

		if selected_item.type == TYPE_CONSUMABLE:
			if selected_item.use(self) == true:
				if selected_item.amount > 1:
					selected_item.amount -= 1
				else:
					inventory.remove_at(item_index)


func search_item_in_inventory(item_name: String) -> int:

	var item_index := 999

	for i in range(inventory.size()):
		if inventory[i].name == item_name:
			item_index = i
			break
	return item_index


func can_obtain_item(item) -> bool:

	var can_obtain := false

	var new_item: Entity = gp.e_generator.get_object(item.name)
	if new_item == null:
		push_warning("EntityGenerator has no entry for: " + item.name)
		return false

	# CHECK IF STACKABLE
	if new_item.stackable == true:

		var index: int = search_item_in_inventory(new_item.name)

		if index != 999:
			inventory[index].amount += 1
			can_obtain = true
		else:  # New item, need to check vacancy
			if inventory.size() != MAX_INVENTORY_SIZE:
				inventory.append(new_item)
				can_obtain = true
	else:  # Not stackable, check vacancy
		if inventory.size() != MAX_INVENTORY_SIZE:
			inventory.append(new_item)
			can_obtain = true

	return can_obtain


func draw(g2) -> void:

	var img: Texture2D = null
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
			if guarding == true:
				img = guard_up
		"down":
			if attacking == false:
				if sprite_num == 1: img = down1
				if sprite_num == 2: img = down2
			if attacking == true:
				if sprite_num == 1: img = attack_down1
				if sprite_num == 2: img = attack_down2
			if guarding == true:
				img = guard_down
		"left":
			if attacking == false:
				if sprite_num == 1: img = left1
				if sprite_num == 2: img = left2
			if attacking == true:
				temp_screen_x = screen_x - gp.tile_size
				if sprite_num == 1: img = attack_left1
				if sprite_num == 2: img = attack_left2
			if guarding == true:
				img = guard_left
		"right":
			if attacking == false:
				if sprite_num == 1: img = right1
				if sprite_num == 2: img = right2
			if attacking == true:
				if sprite_num == 1: img = attack_right1
				if sprite_num == 2: img = attack_right2
			if guarding == true:
				img = guard_right

	if transparent == true:
		g2.change_alpha(0.3)

	g2.draw_img(img, temp_screen_x, temp_screen_y)

	# Reset alpha
	g2.change_alpha(1.0)
