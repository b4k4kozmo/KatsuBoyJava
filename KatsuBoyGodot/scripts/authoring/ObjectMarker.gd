@icon("res://assets/objects/chest.png")
@tool
class_name ObjectMarker
extends PlacementMarker
## An item, chest, door or other pickup on the map.
## Java equivalent: one entry in AssetSetter.setObject().

## Must match the OBJ_NAME constants in scripts/object/*.gd.
@export_enum(
	"Kami Coin", "Key", "Door", "Chest", "Candle", "Tent", "Green Potion",
	"Heart", "Mana Crystal", "Boots", "Kami Axe", "Kami no Bokken",
	"Kami Shield", "Puffa Shield", "Normal Sword", "Carbuncle"
) var item: String = "Kami Coin":
	set(value):
		item = value
		refresh()

## Only used when item is "Chest" - what you find inside.
@export_enum("Key", "Kami Coin", "Green Potion", "Candle", "Tent",
	"Kami Axe", "Kami no Bokken", "Kami Shield", "Boots"
) var chest_loot: String = "Key":
	set(value):
		chest_loot = value
		refresh()

const PREVIEWS := {
	"Kami Coin": "coin", "Key": "key", "Door": "door", "Chest": "chest",
	"Candle": "candle", "Tent": "tent", "Green Potion": "potion",
	"Heart": "sando_full", "Mana Crystal": "gem", "Boots": "boots",
	"Kami Axe": "axe", "Kami no Bokken": "kamibokken",
	"Kami Shield": "kamishield", "Puffa Shield": "puffa",
	"Normal Sword": "sword", "Carbuncle": "carbuncle_green_1",
}


func preview_texture() -> Texture2D:
	if PREVIEWS.has(item):
		return load("res://assets/objects/%s.png" % PREVIEWS[item])
	return null


func marker_color() -> Color:
	return Color(1, 0.85, 0.3)


func marker_label() -> String:
	if item == "Chest":
		return "Chest (%s)" % chest_loot
	return item
