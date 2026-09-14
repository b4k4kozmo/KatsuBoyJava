class_name OBJ_Custom
extends Entity
## An item built entirely from an ItemStats resource - no script of its own.
##
## This is what "adding an item without touching code" means: fill in a .tres,
## add it to GamePanel's Items list, and drop it on a map with an ObjectMarker
## set to "From Stats". The nineteen hand-written items in scripts/object/ still
## work exactly as they did; this is the path for the twentieth.
##
## use() below is the whole vocabulary a data item has: heal, restore mana,
## cure the curse, rest until sunrise, unlock running. Anything outside that -
## an item that changes how a fight works, or opens a screen of its own - is
## still a script, and should be.

var stats: ItemStats


func _init(gp, item_stats: ItemStats) -> void:
	super(gp)

	stats = item_stats
	if stats == null:
		# A marker with an empty slot. A visible placeholder beats a crash.
		name = "Unnamed Item"
		type = TYPE_CONSUMABLE
		return

	name = stats.display_name
	type = stats.entity_type()
	description = stats.description
	price = stats.price
	stackable = stats.stackable
	sound_number = stats.use_sound

	attack_value = stats.attack_value
	defense_value = stats.defense_value
	knock_back_power = stats.knock_back_power
	light_radius = stats.light_radius

	attack_area.width = stats.attack_area.x
	attack_area.height = stats.attack_area.y
	motion1_duration = stats.motion1_duration
	motion2_duration = stats.motion2_duration

	if stats.sprite != null:
		var tool_ := UtilityTool.new()
		down1 = tool_.scale_image(stats.sprite, gp.tile_size, gp.tile_size)
		image = down1


func set_dialogue() -> void:
	if stats != null and not stats.use_message.is_empty():
		dialogues[0][0] = stats.use_message


## Everything a data item can do, applied in the order a player would expect:
## the healing first, then the curse, then sleeping it off.
func use(entity) -> bool:

	if stats == null:
		return false

	set_sound()
	gp.play_se(SE.POWER_UP)

	if not stats.use_message.is_empty():
		set_dialogue()
		start_dialogue(self, 0)

	# Some days food does you more good - see assets/data/days/
	var life: int = stats.life_restored(entity.max_life)
	if life > 0:
		var healed: int = DayEffect.apply(life, gp.today().healing_multiplier)
		entity.life = mini(entity.life + healed, entity.max_life)
		if stats.use_message.is_empty():
			gp.ui.add_message("Life +%d" % healed)

	var mana: int = stats.mana_restored(entity.max_mana)
	if mana > 0:
		entity.mana = mini(entity.mana + mana, entity.max_mana)
		if stats.use_message.is_empty():
			gp.ui.add_message("Mana +%d" % mana)

	if stats.does(ItemStats.CURE_CURSE):
		gp.player.is_cursed = false

	if stats.does(ItemStats.UNLOCK_RUNNING) and not gp.player.has_boots:
		gp.player.has_boots = true
		gp.ui.add_message("Hold %s to run." % Action.key_name(Action.RUN))

	if stats.does(ItemStats.REST):
		gp.game_state = gp.SLEEP_STATE
		gp.play_se(SE.SLEEP)
		gp.player.life = gp.player.max_life
		gp.player.mana = gp.player.max_mana
		gp.player.get_sleeping_image(down1)

	return true
