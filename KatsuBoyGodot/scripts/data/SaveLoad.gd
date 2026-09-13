class_name SaveLoad
extends RefCounted
## Java: data/SaveLoad.java
##
## Java wrote save.dat next to the jar with ObjectOutputStream. We write the
## same fields to user://save.dat with FileAccess.store_var().

const SAVE_PATH := "user://save.dat"

var gp


func _init(gp) -> void:
	self.gp = gp


func save() -> void:

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Save Exception!")
		return

	var ds := DataStorage.new()

	ds.level = gp.player.level
	ds.max_life = gp.player.max_life
	ds.life = gp.player.life          # Java stored player.mana here by mistake
	ds.max_mana = gp.player.max_mana
	ds.mana = gp.player.mana
	ds.strength = gp.player.strength
	ds.dexterity = gp.player.dexterity
	ds.exp = gp.player.exp
	ds.next_level_exp = gp.player.next_level_exp
	ds.coin = gp.player.coin

	ds.has_boots = gp.player.has_boots

	ds.quest = gp.quest.to_dict()
	ds.current_dungeon_id = gp.current_dungeon_id

	# PLAYER INVENTORY
	for i in range(gp.player.inventory.size()):
		ds.item_names.append(gp.player.inventory[i].name)
		ds.item_amounts.append(gp.player.inventory[i].amount)

	# PLAYER EQUIPMENT
	ds.current_weapon_slot = gp.player.get_current_weapon_slot()
	ds.current_shield_slot = gp.player.get_current_shield_slot()

	# OBJECTS ON MAP
	for map_num in range(gp.max_map):

		var names: Array = []
		var xs: Array = []
		var ys: Array = []
		var loots: Array = []
		var opened: Array = []
		var values: Array = []

		for i in range(gp.obj[1].size()):

			if gp.obj[map_num][i] == null:
				names.append("NA")
				xs.append(0)
				ys.append(0)
				loots.append("")
				opened.append(false)
				values.append(0)
			else:
				names.append(gp.obj[map_num][i].name)
				xs.append(gp.obj[map_num][i].world_x)
				ys.append(gp.obj[map_num][i].world_y)
				if gp.obj[map_num][i].loot != null:
					loots.append(gp.obj[map_num][i].loot.name)
				else:
					loots.append("")
				opened.append(gp.obj[map_num][i].opened)
				values.append(gp.obj[map_num][i].value if gp.obj[map_num][i] is OBJ_Coin else 0)

		ds.map_object_names.append(names)
		ds.map_object_world_x.append(xs)
		ds.map_object_world_y.append(ys)
		ds.map_object_loot_names.append(loots)
		ds.map_object_opened.append(opened)
		ds.map_object_values.append(values)

	# Write the DataStorage object
	file.store_var(ds.to_dict())
	file.close()


## Java: load() - renamed because load() is a GDScript built-in.
func load_game() -> void:

	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No save file yet.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Load Exception!")
		return

	var raw = file.get_var()
	file.close()

	if typeof(raw) != TYPE_DICTIONARY:
		push_warning("Load Exception!")
		return

	# Read the DataStorage object
	var ds := DataStorage.from_dict(raw)

	gp.player.level = ds.level
	gp.player.max_life = ds.max_life
	gp.player.life = ds.life
	gp.player.max_mana = ds.max_mana
	gp.player.mana = ds.mana           # Java reset mana to max_mana here
	gp.player.strength = ds.strength
	gp.player.dexterity = ds.dexterity
	gp.player.exp = ds.exp
	gp.player.next_level_exp = ds.next_level_exp
	gp.player.coin = ds.coin
	gp.player.has_boots = ds.has_boots

	gp.quest.apply_dict(ds.quest)
	gp.current_dungeon_id = ds.current_dungeon_id

	# PLAYER INVENTORY
	gp.player.inventory.clear()
	for i in range(ds.item_names.size()):
		var item: Entity = gp.e_generator.get_object(ds.item_names[i])
		if item == null:
			continue
		item.amount = ds.item_amounts[i]
		gp.player.inventory.append(item)

	# PLAYER EQUIPMENT
	if ds.current_weapon_slot < gp.player.inventory.size():
		gp.player.current_weapon = gp.player.inventory[ds.current_weapon_slot]
	if ds.current_shield_slot < gp.player.inventory.size():
		gp.player.current_shield = gp.player.inventory[ds.current_shield_slot]
	gp.player.get_attack()
	gp.player.get_defense()
	gp.player.get_attack_image()

	# OBJECTS ON MAP
	for map_num in range(gp.max_map):

		if map_num >= ds.map_object_names.size():
			break

		for i in range(gp.obj[1].size()):

			if i >= ds.map_object_names[map_num].size():
				break

			var obj_name: String = ds.map_object_names[map_num][i]

			if obj_name == "NA" or obj_name == "":
				gp.obj[map_num][i] = null
			else:
				gp.obj[map_num][i] = gp.e_generator.get_object(obj_name)
				if gp.obj[map_num][i] == null:
					continue
				gp.obj[map_num][i].world_x = ds.map_object_world_x[map_num][i]
				gp.obj[map_num][i].world_y = ds.map_object_world_y[map_num][i]
				var loot_name: String = ds.map_object_loot_names[map_num][i]
				if loot_name != "":
					gp.obj[map_num][i].set_loot(gp.e_generator.get_object(loot_name))
				gp.obj[map_num][i].opened = ds.map_object_opened[map_num][i]
				if (gp.obj[map_num][i] is OBJ_Coin
						and map_num < ds.map_object_values.size()
						and i < ds.map_object_values[map_num].size()
						and int(ds.map_object_values[map_num][i]) > 0):
					gp.obj[map_num][i].set_value(int(ds.map_object_values[map_num][i]))
				if gp.obj[map_num][i].opened == true:
					gp.obj[map_num][i].down1 = gp.obj[map_num][i].image2
