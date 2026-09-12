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

var gp


func _init(gp) -> void:
	self.gp = gp


func get_object(item_name: String) -> Entity:

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
	if obj == null and item_name.ends_with("Ticket"):
		for d in gp.dungeons:
			if d is DungeonInfo and "%s Ticket" % d.display_name == item_name:
				var ticket := OBJ_BoatTicket.new(gp)
				ticket.configure(d)
				obj = ticket
				break

	return obj


func get_monster(monster_name: String) -> Entity:

	var monster: Entity = null

	match monster_name:
		"Slime": monster = MON_Slime.new(gp)
		"Snome": monster = MON_Snome.new(gp)
		"Kamijack": monster = MON_KamiJack.new(gp)
		"Shadow": monster = MON_ShadowKatsu.new(gp)
		"Boss": monster = MON_Boss.new(gp)

	return monster


func get_npc(npc_name: String) -> Entity:

	var npc: Entity = null

	match npc_name:
		"OldMan": npc = NPC_OldMan.new(gp)
		"NanaMan": npc = NPC_NanaMan.new(gp)
		"Merchant": npc = NPC_Merchant.new(gp)

	return npc


func get_interactive_tile(kind: String, col: int, row: int) -> InteractiveTile:

	var tile: InteractiveTile = null

	match kind:
		"DryTree": tile = IT_DryTree.new(gp, col, row)
		"Trunk": tile = IT_Trunk.new(gp, col, row)

	return tile
