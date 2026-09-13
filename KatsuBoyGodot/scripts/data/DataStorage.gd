class_name DataStorage
extends RefCounted
## Java: data/DataStorage.java
##
## Java serialised this object straight to save.dat. GDScript has no object
## serialisation, so to_dict()/from_dict() below turn it into a plain Dictionary
## that FileAccess.store_var() can write.

# PLAYER STATS
var level: int
var max_life: int
var life: int
var max_mana: int
var mana: int
var strength: int
var dexterity: int
@warning_ignore("shadowed_global_identifier")
var exp: int
var next_level_exp: int
var coin: int

var has_boots: bool

# PLAYER INVENTORY
var item_names: Array[String] = []
var item_amounts: Array[int] = []
var current_weapon_slot: int
var current_shield_slot: int

# QUEST / BOAT
## Tickets held, dungeons cleared and the current objective, as written by
## QuestLog.to_dict().
var quest: Dictionary = {}
## Which dungeon the player was standing in when they saved.
var current_dungeon_id: String = ""

# OBJECT ON MAP
var map_object_names: Array = []      # [map][slot] String
var map_object_world_x: Array = []    # [map][slot] int
var map_object_world_y: Array = []    # [map][slot] int
var map_object_loot_names: Array = [] # [map][slot] String or null
var map_object_opened: Array = []     # [map][slot] bool
## [map][slot] int - a coin's worth. Everything else stores 0. Without this a
## 20 coin pile on the floor came back as loose change after a save.
var map_object_values: Array = []


func to_dict() -> Dictionary:
	return {
		"level": level,
		"max_life": max_life,
		"life": life,
		"max_mana": max_mana,
		"mana": mana,
		"strength": strength,
		"dexterity": dexterity,
		"exp": exp,
		"next_level_exp": next_level_exp,
		"coin": coin,
		"has_boots": has_boots,
		"item_names": item_names,
		"item_amounts": item_amounts,
		"current_weapon_slot": current_weapon_slot,
		"current_shield_slot": current_shield_slot,
		"map_object_names": map_object_names,
		"map_object_world_x": map_object_world_x,
		"map_object_world_y": map_object_world_y,
		"map_object_loot_names": map_object_loot_names,
		"map_object_opened": map_object_opened,
		"map_object_values": map_object_values,
		"quest": quest,
		"current_dungeon_id": current_dungeon_id,
	}


static func from_dict(d: Dictionary) -> DataStorage:
	var ds := DataStorage.new()
	ds.level = d.get("level", 1)
	ds.max_life = d.get("max_life", 6)
	ds.life = d.get("life", 6)
	ds.max_mana = d.get("max_mana", 4)
	ds.mana = d.get("mana", 4)
	ds.strength = d.get("strength", 1)
	ds.dexterity = d.get("dexterity", 1)
	ds.exp = d.get("exp", 0)
	ds.next_level_exp = d.get("next_level_exp", 5)
	ds.coin = d.get("coin", 0)
	ds.has_boots = d.get("has_boots", false)
	ds.item_names.assign(d.get("item_names", []))
	ds.item_amounts.assign(d.get("item_amounts", []))
	ds.current_weapon_slot = d.get("current_weapon_slot", 0)
	ds.current_shield_slot = d.get("current_shield_slot", 1)
	ds.map_object_names = d.get("map_object_names", [])
	ds.map_object_world_x = d.get("map_object_world_x", [])
	ds.map_object_world_y = d.get("map_object_world_y", [])
	ds.map_object_loot_names = d.get("map_object_loot_names", [])
	ds.map_object_opened = d.get("map_object_opened", [])
	ds.map_object_values = d.get("map_object_values", [])
	# Saves written before the boat existed simply have no quest data, and an
	# empty dictionary loads as a fresh quest log rather than failing.
	ds.quest = d.get("quest", {})
	ds.current_dungeon_id = str(d.get("current_dungeon_id", ""))
	return ds
