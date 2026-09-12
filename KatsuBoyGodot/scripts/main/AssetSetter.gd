class_name AssetSetter
extends RefCounted
## Java: main/AssetSetter.java - places everything on the maps.

var gp


func _init(gp) -> void:
	self.gp = gp


## Small helper so the long "gp.obj[map][i] = ...; worldX = ...; worldY = ..."
## blocks below stay one readable line each.
func _place(array: Array, map_num: int, i: int, entity: Entity, col: int, row: int) -> void:
	array[map_num][i] = entity
	entity.world_x = col * gp.tile_size
	entity.world_y = row * gp.tile_size


func set_object() -> void:

	var map_num := 0
	var i := 0
	_place(gp.obj, map_num, i, OBJ_Coin.new(gp), 50, 97); i += 1
	_place(gp.obj, map_num, i, OBJ_Carbo.new(gp), 52, 98); i += 1
	_place(gp.obj, map_num, i, OBJ_Key.new(gp), 96, 96); i += 1
	_place(gp.obj, map_num, i, OBJ_Coin.new(gp), 96, 97); i += 1
	_place(gp.obj, map_num, i, OBJ_Coin.new(gp), 97, 90); i += 1
	_place(gp.obj, map_num, i, OBJ_Kamibokken.new(gp), 98, 98); i += 1
	_place(gp.obj, map_num, i, OBJ_Kami_Shield.new(gp), 97, 98); i += 1
	_place(gp.obj, map_num, i, OBJ_Potion_Green.new(gp), 89, 97); i += 1
	_place(gp.obj, map_num, i, OBJ_Heart.new(gp), 95, 91); i += 1
	_place(gp.obj, map_num, i, OBJ_Kamiaxe.new(gp), 94, 91); i += 1
	_place(gp.obj, map_num, i, OBJ_Door.new(gp), 85, 97); i += 1

	var chest := OBJ_Chest.new(gp)
	chest.set_loot(OBJ_Key.new(gp))
	_place(gp.obj, map_num, i, chest, 91, 92); i += 1

	_place(gp.obj, map_num, i, OBJ_Candle.new(gp), 92, 92); i += 1
	_place(gp.obj, map_num, i, OBJ_Tent.new(gp), 92, 93); i += 1

	# Clear any slot the previous game left behind (restart / load).
	while i < gp.obj[map_num].size():
		gp.obj[map_num][i] = null
		i += 1


func set_npc() -> void:

	var map_num := 0
	var i := 0
	_place(gp.npc, map_num, i, NPC_OldMan.new(gp), 96, 95); i += 1

	map_num = 1
	i = 0
	_place(gp.npc, map_num, i, NPC_NanaMan.new(gp), 11, 23); i += 1
	_place(gp.npc, map_num, i, NPC_Merchant.new(gp), 26, 18); i += 1


func set_monster() -> void:

	var map_num := 0
	var i := 0
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 82, 95); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 58, 79); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 8, 55); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 8, 51); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 8, 46); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 8, 35); i += 1
	_place(gp.monster, map_num, i, MON_Slime.new(gp), 84, 93); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 80, 90); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 80, 88); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 80, 87); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 79, 87); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 78, 87); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 77, 87); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 77, 86); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 76, 86); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 77, 85); i += 1
	_place(gp.monster, map_num, i, MON_Snome.new(gp), 76, 87); i += 1
	_place(gp.monster, map_num, i, MON_KamiJack.new(gp), 88, 77); i += 1
	_place(gp.monster, map_num, i, MON_KamiJack.new(gp), 92, 73); i += 1
	_place(gp.monster, map_num, i, MON_KamiJack.new(gp), 27, 79); i += 1
	_place(gp.monster, map_num, i, MON_KamiJack.new(gp), 79, 52); i += 1
	_place(gp.monster, map_num, i, MON_KamiJack.new(gp), 66, 45); i += 1
	_place(gp.monster, map_num, i, MON_ShadowKatsu.new(gp), 7, 59); i += 1

	# Respawning wipes the slots the previous wave left behind.
	while i < gp.monster[map_num].size():
		gp.monster[map_num][i] = null
		i += 1


func set_interactive_tile() -> void:
	var map_num := 0
	var i := 0
	gp.i_tile[map_num][i] = IT_DryTree.new(gp, 86, 97); i += 1

	while i < gp.i_tile[map_num].size():
		gp.i_tile[map_num][i] = null
		i += 1

	gp.p_finder.solid_dirty = true
