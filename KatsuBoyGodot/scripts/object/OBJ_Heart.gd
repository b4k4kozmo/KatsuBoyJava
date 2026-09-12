class_name OBJ_Heart
extends Entity
## Java: object/OBJ_Heart.java

const OBJ_NAME := "Heart"


func _init(gp) -> void:
	super(gp)

	type = TYPE_PICKUP_ONLY
	name = OBJ_NAME
	value = 2
	down1 = setup("/objects/sando_full", gp.tile_size, gp.tile_size)
	image = setup("/objects/sando_full", gp.tile_size, gp.tile_size)
	image2 = setup("/objects/sando_half", gp.tile_size, gp.tile_size)
	image3 = setup("/objects/sando_empty", gp.tile_size, gp.tile_size)


func use(entity) -> bool:
	sound_number = 20
	set_sound()
	gp.play_se(SE.POWER_UP)
	# Some days food does you more good - see assets/data/days/
	var healed: int = DayEffect.apply(value, gp.today().healing_multiplier)
	gp.ui.add_message("Life +" + str(healed))
	entity.life += healed
	return true
