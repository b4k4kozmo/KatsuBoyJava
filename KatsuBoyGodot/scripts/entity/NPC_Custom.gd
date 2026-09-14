class_name NPC_Custom
extends Entity
## A character built entirely from an NpcProfile resource - no script.
##
## Talking cycles through the profile's conversations and stops on the last
## one, which is how the old man works and what makes a character read as
## written rather than recorded. If the profile carries a gift, it is handed
## over the first time you speak and never again.
##
## For anything beyond that - a shop, a ticket collector, someone who leads you
## somewhere - write a script in this folder. Those are rules, not lines.

var profile: NpcProfile
var gift_given: bool = false


func _init(gp, npc_profile: NpcProfile) -> void:
	super(gp)

	profile = npc_profile
	type = TYPE_NPC

	if profile == null:
		name = "Unnamed"
		speed = 0
		return

	name = profile.display_name
	direction = "down"
	speed = profile.walk_speed
	default_speed = profile.walk_speed
	sound_number = profile.voice

	solid_area = Rect.new()
	solid_area.x = profile.solid_area.position.x
	solid_area.y = profile.solid_area.position.y
	solid_area.width = profile.solid_area.size.x
	solid_area.height = profile.solid_area.size.y
	solid_area_default_x = solid_area.x
	solid_area_default_y = solid_area.y

	# Starts at -1 so the first speak() lands on conversation 0.
	dialogue_set = -1

	profile.build_images(self, gp.tile_size)
	set_dialogue()


func set_dialogue() -> void:
	if profile != null:
		profile.build_dialogue(self)


## Wander, or stand still if the profile gave them no speed.
func set_action() -> void:

	if profile == null or profile.walk_speed == 0:
		action_lock_counter = 0
		return

	action_lock_counter += 1
	if action_lock_counter >= profile.restlessness:
		get_random_direction()
		action_lock_counter = 0


func speak() -> void:

	set_sound()
	face_player()

	# Move to the next conversation, then stay on the last one forever.
	var last: int = maxi(profile.conversations.size() - 1, 0) if profile != null else 0
	dialogue_set = mini(dialogue_set + 1, last)
	start_dialogue(self, dialogue_set)

	if profile != null and profile.gift != null and not gift_given:
		_hand_over()


func _hand_over() -> void:

	var item: Entity = OBJ_Custom.new(gp, profile.gift)

	if item.type == TYPE_PICKUP_ONLY:
		# Boots and the like are used on the spot, not carried.
		item.use(gp.player)
	elif not gp.player.can_obtain_item(item):
		gp.ui.add_message("Your inventory is full!")
		return

	gift_given = true
	gp.play_se(SE.COIN)
	if profile.gift_message.is_empty():
		gp.ui.add_message("Got a %s!" % profile.gift.display_name)
	else:
		gp.ui.add_message(profile.gift_message)
