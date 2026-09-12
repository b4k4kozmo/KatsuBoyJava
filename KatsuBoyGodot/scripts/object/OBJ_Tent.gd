class_name OBJ_Tent
extends Entity
## Java: object/OBJ_Tent.java

const OBJ_NAME := "Tent"


func _init(gp) -> void:
	super(gp)

	type = TYPE_CONSUMABLE
	name = OBJ_NAME
	down1 = setup("/objects/tent", gp.tile_size, gp.tile_size)
	description = "[" + name + "] \n You can rest until\n the sunrise."
	price = 50
	stackable = true


func use(_entity) -> bool:
	gp.game_state = gp.SLEEP_STATE
	gp.play_se(SE.SLEEP)
	gp.player.life = gp.player.max_life
	gp.player.mana = gp.player.max_mana
	gp.player.is_cursed = false
	gp.player.get_sleeping_image(down1)
	return true
