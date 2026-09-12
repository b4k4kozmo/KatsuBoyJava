class_name OBJ_Potion_Green
extends Entity
## Java: object/OBJ_Potion_Green.java

const OBJ_NAME := "Green Potion"


func _init(gp) -> void:
	super(gp)

	type = TYPE_CONSUMABLE
	name = OBJ_NAME
	value = gp.player.max_mana
	down1 = setup("/objects/potion", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nHeals your life\n" + str(value) + " HP."
	price = 10
	stackable = true


func set_dialogue() -> void:
	dialogues[0][0] = "You down the " + name + " and recover " + str(gp.player.max_mana) + " MP."


func use(entity) -> bool:
	sound_number = 20
	set_sound()
	set_dialogue()
	start_dialogue(self, 0)
	entity.mana += entity.max_mana
	gp.play_se(SE.POWER_UP)
	return true
