@icon("res://assets/npc/oldman_down_01.png")
@tool
class_name NpcProfile
extends Resource
## A character, as a file rather than a script.
##
## Everything the four hand-written NPCs have in common - a name, eight walk
## frames, a hitbox, whether they wander, and what they say - is in here, so a
## villager with three conversations and a gift is a .tres and no code.
##
## Make one: copy a file from assets/data/npcs/, change it, then drop it into
## an NpcMarker with Npc set to "From Stats".
##
## What still wants a script: a character whose talking *does* something the
## engine does not already know how to do. The merchant opens a shop, the
## collector takes tickets, the old man walks you to the boat. Those are rules,
## not lines, and they live in scripts/entity/.
##
## This is a @tool script because the markers that reference it are: an
## ObjectMarker asking an ItemStats what it is, to draw its own label and
## warning, has to be able to call into it while the editor is running.

## What the dialogue box calls them.
@export var display_name: String = "New Character"

@export_group("Looks")
## Two frames per direction, walk cycle. Leave Up, Left and Right empty and
## they face every way with their Down frames.
@export var frames_down: Array[Texture2D] = []
@export var frames_up: Array[Texture2D] = []
@export var frames_left: Array[Texture2D] = []
@export var frames_right: Array[Texture2D] = []
## 1 draws them one tile across, 2 draws them two. It also decides how far
## off-screen they can be before the game stops drawing them, and how they sort
## against what they walk in front of.
@export_range(1, 4) var sprite_scale: int = 1

@export_group("Body")
## The collision box inside the 48x48 tile. The stock NPCs use (12, 20, 24, 26),
## which is small enough for the player to squeeze past in a doorway.
@export var solid_area: Rect2i = Rect2i(12, 20, 24, 26)
## 0 for someone who has stood in the same spot for thirty years. 2 is a slow
## amble; the player walks at 4.
@export_range(0, 8) var walk_speed: int = 1
## Frames between changes of direction while wandering. Lower is more restless.
@export_range(20, 300) var restlessness: int = 120

@export_group("Talking")
## The conversations, in order. Talking again moves to the next one; the last
## one repeats forever. One conversation is a character who says the same thing
## every time, which is fine for a signpost.
@export var conversations: Array[NpcDialogue] = []
## Sound effect number from the sound bank, played when they start speaking.
@export_range(0, 40) var voice: int = 17

@export_group("Gift")
## An item they hand over the first time you talk to them. Leave empty for
## someone who only talks. The gift is given once per run.
@export var gift: ItemStats
## What the message box says when they hand it over. Leave empty for the
## default, "Got a <item>!".
@export var gift_message: String = ""


func has_art() -> bool:
	return frames_down.size() > 0


## Fill in an entity's eight walk frames. Anything left empty falls back to the
## Down pair, so a one-sided sprite still animates in all four directions.
func build_images(entity: Entity, tile_size: int) -> void:

	if not has_art():
		return

	var size: int = tile_size * sprite_scale
	var down: Array[Texture2D] = _pair(frames_down, size)
	var up: Array[Texture2D] = _pair(frames_up, size) if frames_up.size() > 0 else down
	var left: Array[Texture2D] = _pair(frames_left, size) if frames_left.size() > 0 else down
	var right: Array[Texture2D] = _pair(frames_right, size) if frames_right.size() > 0 else down

	entity.down1 = down[0]; entity.down2 = down[1]
	entity.up1 = up[0]; entity.up2 = up[1]
	entity.left1 = left[0]; entity.left2 = left[1]
	entity.right1 = right[0]; entity.right2 = right[1]


func _pair(list: Array[Texture2D], size: int) -> Array[Texture2D]:
	var tool_ := UtilityTool.new()
	var first: Texture2D = list[0]
	var second: Texture2D = list[1] if list.size() > 1 else first
	return [tool_.scale_image(first, size, size), tool_.scale_image(second, size, size)]


## Copy the conversations onto an entity's dialogue table, one per set.
func build_dialogue(entity: Entity) -> void:
	for set_num in range(mini(conversations.size(), 20)):
		var convo: NpcDialogue = conversations[set_num]
		if convo == null:
			continue
		for i in range(mini(convo.lines.size(), 20)):
			entity.dialogues[set_num][i] = convo.lines[i]


## How many conversations actually have lines in them.
func spoken_sets() -> int:
	var n := 0
	for c in conversations:
		if c is NpcDialogue and not c.is_empty():
			n += 1
	return n
