class_name EntityGenerator
extends RefCounted
## Java: main/EntityGenerator.java - builds an entity from its name.
##
## Used by inventory pickups, the save file loader, and AssetSetter when it
## reads the placement markers out of a map scene.
##
## ADDING A NEW ITEM / MONSTER / NPC: write its script in scripts/object/,
## scripts/monster/ or scripts/entity/, add one line to the matching function
## below, then add its name to the @export_enum list in the matching marker
## script in scripts/authoring/. After that it is placeable in the editor.
##
## MOST OF THAT IS NO LONGER NEEDED. A monster, an item and an NPC can each be
## a resource on its own - MonsterStats, ItemStats, NpcProfile - dropped into a
## marker set to "From Stats". Only something whose behaviour is a new rule
## rather than new numbers still wants a script here.

## Where item resources live. Everything in here is findable by name without
## being registered anywhere.
const ITEM_FOLDER := "res://assets/data/items/"

var gp


func _init(gp) -> void:
	self.gp = gp


## Build an item by name. `stats` short-circuits the lookup when a marker has
## a resource in hand; without it, a name that matches nothing hand-written is
## looked for in GamePanel's Items list, which is how a data item survives a
## save and comes back as itself.
func get_object(item_name: String, stats: ItemStats = null) -> Entity:

	if stats != null:
		return OBJ_Custom.new(gp, stats)

	var obj: Entity = null

	match item_name:
		OBJ_Candle.OBJ_NAME: obj = OBJ_Candle.new(gp)
		OBJ_Boots.OBJ_NAME: obj = OBJ_Boots.new(gp)
		OBJ_Carbo.OBJ_NAME: obj = OBJ_Carbo.new(gp)  # Java left this one out, which crashed on pickup
		OBJ_Kami_Shield.OBJ_NAME: obj = OBJ_Kami_Shield.new(gp)
		OBJ_Kamiaxe.OBJ_NAME: obj = OBJ_Kamiaxe.new(gp)
		OBJ_Kamibokken.OBJ_NAME: obj = OBJ_Kamibokken.new(gp)
		OBJ_Key.OBJ_NAME: obj = OBJ_Key.new(gp)
		OBJ_Door.OBJ_NAME: obj = OBJ_Door.new(gp)
		OBJ_Chest.OBJ_NAME: obj = OBJ_Chest.new(gp)
		OBJ_Potion_Green.OBJ_NAME: obj = OBJ_Potion_Green.new(gp)
		OBJ_Shield_Puffa.OBJ_NAME: obj = OBJ_Shield_Puffa.new(gp)
		OBJ_Sword_Normal.OBJ_NAME: obj = OBJ_Sword_Normal.new(gp)
		OBJ_Tent.OBJ_NAME: obj = OBJ_Tent.new(gp)
		OBJ_Coin.OBJ_NAME: obj = OBJ_Coin.new(gp)
		OBJ_Heart.OBJ_NAME: obj = OBJ_Heart.new(gp)
		OBJ_ManaCrystal.OBJ_NAME: obj = OBJ_ManaCrystal.new(gp)
		OBJ_Shuriken.OBJ_NAME: obj = OBJ_Shuriken.new(gp)
		OBJ_Snowball.OBJ_NAME: obj = OBJ_Snowball.new(gp)
		OBJ_BoatTicket.OBJ_NAME: obj = OBJ_BoatTicket.new(gp)

	# Tickets are named after their route ("Mushroom Cave Ticket"), so they are
	# matched against the dungeon list rather than listed above. Without this a
	# ticket in the bag would not survive a save and load.
	# Items that are nothing but a resource. Looked up by display name, which
	# is why that field is the stable key and must never be renamed.
	if obj == null:
		var sheet: ItemStats = find_item(item_name)
		if sheet != null:
			obj = OBJ_Custom.new(gp, sheet)

	if obj == null and item_name.ends_with("Ticket"):
		for d in gp.dungeons:
			if d is DungeonInfo and "%s Ticket" % d.display_name == item_name:
				var ticket := OBJ_BoatTicket.new(gp)
				ticket.configure(d)
				obj = ticket
				break

	return obj


## Build a monster by name. "From Stats" builds one out of the resource alone,
## which is how a monster gets added without any code: see MonsterStats.
## Find an ItemStats by its display name: GamePanel's Items list first, then
## every .tres in assets/data/items/.
##
## The folder sweep is the safety net. Registering an item in the Inspector is
## the documented step, and forgetting it used to mean the item worked on the
## map and then vanished from the bag after a save - a bug that only shows up
## ten minutes later. Now forgetting costs nothing.
func find_item(item_name: String) -> ItemStats:

	for sheet in gp.items:
		if sheet is ItemStats and sheet.display_name == item_name:
			return sheet

	for path in item_files():
		var sheet: Resource = load(path)
		if sheet is ItemStats and sheet.display_name == item_name:
			return sheet

	return null


## Every item resource shipped in assets/data/items/.
static func item_files() -> PackedStringArray:

	var out := PackedStringArray()
	var dir := DirAccess.open(ITEM_FOLDER)
	if dir == null:
		return out

	for file in dir.get_files():
		# Exported builds rename imported resources; the original name is the
		# path with .remap taken off.
		if file.ends_with(".remap"):
			file = file.trim_suffix(".remap")
		if file.ends_with(".tres"):
			out.append(ITEM_FOLDER + file)

	return out


func get_monster(monster_name: String, stats: MonsterStats = null) -> Entity:

	var monster: Entity = null

	match monster_name:
		"Slime": monster = MON_Slime.new(gp)
		"Snome": monster = MON_Snome.new(gp)
		"Kamijack": monster = MON_KamiJack.new(gp)
		"Shadow": monster = MON_ShadowKatsu.new(gp)
		"Boss": monster = MON_Boss.new(gp)
		"From Stats": monster = MON_Custom.new(gp, stats)

	return monster


## Build an NPC by name. "From Stats" builds one out of an NpcProfile alone,
## which is how a character gets added without any code.
func get_npc(npc_name: String, profile: NpcProfile = null) -> Entity:

	var npc: Entity = null

	match npc_name:
		"OldMan": npc = NPC_OldMan.new(gp)
		"NanaMan": npc = NPC_NanaMan.new(gp)
		"Merchant": npc = NPC_Merchant.new(gp)
		"TicketMan": npc = NPC_TicketMan.new(gp)
		"From Stats": npc = NPC_Custom.new(gp, profile)

	return npc


func get_interactive_tile(kind: String, col: int, row: int) -> InteractiveTile:

	var tile: InteractiveTile = null

	match kind:
		"DryTree": tile = IT_DryTree.new(gp, col, row)
		"Trunk": tile = IT_Trunk.new(gp, col, row)

	return tile
