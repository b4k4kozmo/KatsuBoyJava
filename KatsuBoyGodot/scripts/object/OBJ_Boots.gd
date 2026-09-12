class_name OBJ_Boots
extends Entity
## Java: object/OBJ_Boots.java

const OBJ_NAME := "Boots"


func _init(gp) -> void:
	super(gp)

	# Picked up rather than carried: taking them permanently unlocks running.
	# (In the Java version this item existed but did nothing at all, so the Run
	#  key only ever worked if you picked the Ninja or Zilla class.)
	type = TYPE_PICKUP_ONLY
	name = OBJ_NAME
	down1 = setup("/objects/boots", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nGotta go fast!"
	price = 10


func use(_entity) -> bool:
	gp.play_se(SE.POWER_UP)
	gp.ui.add_message("Got the " + name + "! Hold "
			+ Action.key_name(Action.RUN) + " to run.")
	gp.player.has_boots = true
	return true
