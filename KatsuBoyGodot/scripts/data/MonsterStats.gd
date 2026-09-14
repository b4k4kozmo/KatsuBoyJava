@tool
class_name MonsterStats
extends Resource
## The numbers that define a monster, so balancing is Inspector work instead of
## code edits. Open assets/data/monsters/*.tres and change what you like.
##
## It also carries the monster's art, its behaviour and its drop table, which
## means a brand new monster can be a .tres plus a few PNGs and no code at all:
## fill in Looks, pick a Behaviour, add some Drops, then drag the resource into
## a MonsterMarker's "Stats" slot. See AUTHORING.md.
##
## The five monsters that came over from Java still have their own scripts in
## scripts/monster/, because their behaviour was written before this existed.
## Those scripts draw and act for themselves and ignore the Looks and Behaviour
## groups below; they read only the numbers. Nothing needs porting - both kinds
## work side by side.
##
## This is a @tool script because the markers that reference it are: an
## ObjectMarker asking an ItemStats what it is, to draw its own label and
## warning, has to be able to call into it while the editor is running.

@export var display_name: String = ""

@export_group("Stats")
@export var max_life: int = 1
@export var attack: int = 1
@export var defense: int = 0
## Exp the player gets for killing it.
@export var exp_reward: int = 1
@export var speed: int = 1
## How hard its hits shove the player. 0 = no knockback.
@export var knock_back_power: int = 0

@export_group("Hitbox")
## Offset and size of the collision box inside the 48x48 tile.
@export var solid_area: Rect2i = Rect2i(0, 0, 48, 48)

@export_group("Looks")
## Two frames per direction, walk cycle. Drop the PNGs straight in from
## assets/monster/. Leave Up, Left and Right empty and the monster faces every
## way with its Down frames, which is what the Slime does.
##
## Only read for a monster built from this resource alone. A monster with its
## own script draws itself.
@export var frames_down: Array[Texture2D] = []
@export var frames_up: Array[Texture2D] = []
@export var frames_left: Array[Texture2D] = []
@export var frames_right: Array[Texture2D] = []
## 1 draws it one tile across, 2 draws it two - a Kamijack is a 2.
##
## This is not only how big it looks. It is how far off-screen it can be before
## the game stops drawing it, how wide its health bar is, how it sorts against
## the things it walks in front of, and how much floor a marker needs to have
## under it. Set it to match the art.
@export_range(1, 4) var sprite_scale: int = 1

@export_group("Behaviour")
## What it does when it can see you.
##   Wander        - drifts, hurts on contact. A Slime.
##   Chaser        - takes the shortest path to you once you are close.
##   Fighter       - chases and swings when it gets in reach.
##   Shooter       - chases, swings, and throws things at range. A Shadow.
@export_enum("Wander", "Chaser", "Fighter", "Shooter")
var behaviour: String = "Wander"
## How close you have to get, in tiles, before a chaser notices you.
@export_range(1, 30) var notice_distance: int = 5
## How far you have to get, in tiles, before it gives up.
@export_range(2, 40) var give_up_distance: int = 15
## Frames between throws, for a Shooter. Lower is meaner.
@export_range(10, 300) var shot_interval: int = 30
## What a Shooter throws.
@export_enum("Shuriken", "Snow-ball") var projectile: String = "Shuriken"
## Frames it waits between swings, for a Fighter or Shooter.
@export_range(10, 200) var swing_interval: int = 30

@export_group("Drops")
## What falls when it dies, as weighted rows. Empty means it drops nothing,
## which is fine for a monster that guards something instead of paying.
@export var drops: Array[MonsterDrop] = []

@export_group("Melee attack")
## Reach of a swing. Leave at zero for monsters that only touch or shoot.
@export var attack_area: Rect2i = Rect2i(0, 0, 0, 0)
## Frames of wind-up, then frames until the swing ends.
@export var motion1_duration: int = 0
@export var motion2_duration: int = 0


## Copy these numbers onto a freshly built monster.
func apply_to(entity: Entity) -> void:

	entity.type = Entity.TYPE_MONSTER
	entity.name = display_name
	entity.size_in_tiles = sprite_scale
	entity.max_life = max_life
	entity.life = max_life
	entity.attack = attack
	entity.defense = defense
	entity.exp = exp_reward
	# Java set speed but left default_speed at 0 on some monsters, so they froze
	# permanently the first time they were knocked back. Always set both.
	entity.default_speed = speed
	entity.speed = speed
	entity.knock_back_power = knock_back_power

	entity.solid_area.x = solid_area.position.x
	entity.solid_area.y = solid_area.position.y
	entity.solid_area.width = solid_area.size.x
	entity.solid_area.height = solid_area.size.y
	entity.solid_area_default_x = entity.solid_area.x
	entity.solid_area_default_y = entity.solid_area.y

	entity.attack_area.x = attack_area.position.x
	entity.attack_area.y = attack_area.position.y
	entity.attack_area.width = attack_area.size.x
	entity.attack_area.height = attack_area.size.y
	entity.motion1_duration = motion1_duration
	entity.motion2_duration = motion2_duration


## Does this resource carry enough art to build a monster on its own?
func has_art() -> bool:
	return frames_down.size() > 0


## Fill in an entity's eight walk frames from the Looks group. Anything left
## empty falls back to the Down pair, so a one-sided sprite still animates in
## all four directions instead of drawing nothing.
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


## Two scaled frames from however many were dropped in: one frame is a still
## monster rather than a broken one.
func _pair(list: Array[Texture2D], size: int) -> Array[Texture2D]:
	var tool_ := UtilityTool.new()
	var first: Texture2D = list[0]
	var second: Texture2D = list[1] if list.size() > 1 else first
	return [tool_.scale_image(first, size, size), tool_.scale_image(second, size, size)]


## Roll the drop table once. Returns null when nothing falls - either because
## the table is empty or because a "Nothing" row came up.
func roll_drop(gp) -> Entity:

	var total := 0
	for d in drops:
		if d is MonsterDrop:
			total += d.weight
	if total <= 0:
		return null

	var roll: int = randi() % total
	for d in drops:
		if not (d is MonsterDrop):
			continue
		roll -= d.weight
		if roll < 0:
			return d.make(gp)
	return null
