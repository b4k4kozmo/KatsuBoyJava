class_name OBJ_ManaCrystal
extends Entity
## Java: object/OBJ_ManaCrystal.java

const OBJ_NAME := "Mana Crystal"


func _init(gp) -> void:
	super(gp)

	type = TYPE_PICKUP_ONLY
	name = OBJ_NAME
	value = 1
	down1 = setup("/objects/gem", gp.tile_size, gp.tile_size)
	image = setup("/objects/gem", gp.tile_size, gp.tile_size)
	image2 = setup("/objects/gem_empty", gp.tile_size, gp.tile_size)


func use(_entity) -> bool:
	sound_number = 20
	set_sound()
	gp.play_se(SE.POWER_UP)
	var restored: int = DayEffect.apply(value, gp.today().healing_multiplier)
	gp.ui.add_message("Mana +" + str(restored))
	gp.player.mana += restored
	return true
