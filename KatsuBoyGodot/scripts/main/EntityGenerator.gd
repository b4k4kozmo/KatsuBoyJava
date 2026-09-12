class_name EntityGenerator
extends RefCounted
## Java: main/EntityGenerator.java - builds an item from its name, used by
## inventory pickups and by the save file loader.

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

	return obj
