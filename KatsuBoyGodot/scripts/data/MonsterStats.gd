class_name MonsterStats
extends Resource
## The numbers that define a monster, so balancing is Inspector work instead of
## code edits. Open assets/data/monsters/*.tres and change what you like.
##
## What is NOT in here: behaviour (does it chase? shoot? swing?) and which
## sprites it uses. Those live in the monster's own script in scripts/monster/,
## because they differ too much between monsters to describe as data.

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
