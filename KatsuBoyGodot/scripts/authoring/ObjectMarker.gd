@icon("res://assets/objects/chest.png")
@tool
class_name ObjectMarker
extends PlacementMarker
## An item, chest, door or other pickup on the map.
## Java equivalent: one entry in AssetSetter.setObject().
##
## Two ways to fill one in:
##
##   * Pick a named item. Those are the nineteen that came over from Java, each
##     with its own script in scripts/object/.
##   * Pick "From Stats" and drag an ItemStats resource in. That resource IS
##     the item - name, sprite, price, what it does. No code at all.

## Must match the OBJ_NAME constants in scripts/object/*.gd.
@export_enum(
	"Kami Coin", "Key", "Door", "Chest", "Candle", "Tent", "Green Potion",
	"Heart", "Mana Crystal", "Boots", "Kami Axe", "Kami no Bokken",
	"Kami Shield", "Puffa Shield", "Normal Sword", "Carbuncle", "Cave Ticket",
	"From Stats"
) var item: String = "Kami Coin":
	set(value):
		item = value
		refresh()

## The item itself, when Item is "From Stats". Drag one in from
## assets/data/items/, and add the same resource to GamePanel's "Items" list so
## a save file can find it again by name.
@export var item_stats: ItemStats:
	set(value):
		item_stats = value
		refresh()

## Only used when item is "Chest" - what you find inside.
@export_enum("Key", "Kami Coin", "Green Potion", "Candle", "Tent",
	"Kami Axe", "Kami no Bokken", "Kami Shield", "Boots", "Cave Ticket",
	"From Stats"
) var chest_loot: String = "Key":
	set(value):
		chest_loot = value
		refresh()

## What is in the chest, when Chest Loot is "From Stats".
@export var chest_loot_stats: ItemStats:
	set(value):
		chest_loot_stats = value
		refresh()

## Only used when the item (or a chest's loot) is a Kami Coin: how many coins
## it is worth. 1 is loose change; 5 is a purse; 20 is a find. Scattered coins
## are meant to be rarer and smaller than what monsters drop - see ROADMAP.md.
@export_range(1, 200) var coin_value: int = 1:
	set(value):
		coin_value = value
		refresh()

const PREVIEWS := {
	"Kami Coin": "coin", "Key": "key", "Door": "door", "Chest": "chest",
	"Candle": "candle", "Tent": "tent", "Green Potion": "potion",
	"Heart": "sando_full", "Mana Crystal": "gem", "Boots": "boots",
	"Kami Axe": "axe", "Kami no Bokken": "kamibokken",
	"Kami Shield": "kamishield", "Puffa Shield": "puffa",
	"Normal Sword": "sword", "Carbuncle": "carbuncle_green_1",
	"Cave Ticket": "key",
}


func preview_texture() -> Texture2D:
	if item == "From Stats":
		return item_stats.sprite if item_stats != null else null
	if PREVIEWS.has(item):
		return load("res://assets/objects/%s.png" % PREVIEWS[item])
	return null


func marker_color() -> Color:
	return Color(1, 0.85, 0.3)


func marker_label() -> String:
	if item == "Chest":
		return "Chest (%s)" % _loot_name()
	if item == "Kami Coin" and coin_value > 1:
		return "%s x%d" % [item, coin_value]
	if item == "From Stats":
		if item_stats == null:
			return "From Stats (empty!)"
		return "%s - %s" % [item_stats.display_name, item_stats.summary()]
	return item


func _loot_name() -> String:
	if chest_loot != "From Stats":
		return chest_loot
	return chest_loot_stats.display_name if chest_loot_stats != null else "empty!"


func _get_configuration_warnings() -> PackedStringArray:

	var warnings := _placement_warnings()

	# A locked door with no key anywhere on the map is a dead end that looks
	# like content. Chests are the same story one step along.
	if item == "Door":
		var map: DungeonMap = map_root()
		if map != null and not map.has_object("Key") and not map.has_chest_loot("Key"):
			warnings.append("A locked door, and no Key anywhere on this map - "
					+ "not in the open and not in a chest.")

	if item == "Chest" and chest_loot == "Chest":
		warnings.append("A chest containing a chest. Pick something else.")

	if item == "From Stats" and item_stats == null:
		warnings.append("Item is 'From Stats' but the Item Stats slot is empty. "
				+ "Drag an ItemStats resource in, or pick a named item.")

	if item == "Chest" and chest_loot == "From Stats" and chest_loot_stats == null:
		warnings.append("Chest Loot is 'From Stats' with nothing in the slot, so "
				+ "this chest is empty.")

	if item_stats != null and item_stats.sprite == null:
		warnings.append("%s has no sprite, so it would be invisible on the ground."
				% item_stats.display_name)

	return warnings
