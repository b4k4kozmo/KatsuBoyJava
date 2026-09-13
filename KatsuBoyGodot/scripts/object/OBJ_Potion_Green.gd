class_name OBJ_Potion_Green
extends Entity
## Java: object/OBJ_Potion_Green.java
##
## The cheap healing item, and the only one you can buy. Java described it as
## healing life and then restored mana instead, which is why it never seemed to
## do anything: it heals life now, as it always said it did. Mana comes back
## from the crystals slimes drop.
##
## It heals a share of your maximum rather than a flat number, so it is still
## worth ten coins at level 15.

const OBJ_NAME := "Green Potion"

## Half of max life, and never less than this.
const MIN_HEAL := 4


func _init(gp) -> void:
	super(gp)

	type = TYPE_CONSUMABLE
	name = OBJ_NAME
	value = heal_amount()
	down1 = setup("/objects/potion", gp.tile_size, gp.tile_size)
	description = "[" + name + "]\nHeals half your life,\nat least " + str(MIN_HEAL) + " HP."
	price = 10
	stackable = true


func heal_amount() -> int:
	@warning_ignore("integer_division")
	return maxi(gp.player.max_life / 2, MIN_HEAL)


func set_dialogue() -> void:
	dialogues[0][0] = "You down the " + name + "\nand feel better."


func use(entity) -> bool:
	value = heal_amount()
	sound_number = 20
	set_sound()
	set_dialogue()
	start_dialogue(self, 0)

	var healed: int = DayEffect.apply(value, gp.today().healing_multiplier)
	entity.life = mini(entity.life + healed, entity.max_life)
	gp.play_se(SE.POWER_UP)
	return true
