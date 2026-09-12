class_name PlayerStats
extends Resource
## Katsu Boy's starting numbers and movement speeds.
## Edit assets/data/player.tres in the Inspector - no code needed.

@export_group("Starting stats")
@export var level: int = 1
@export var max_life: int = 6
@export var max_mana: int = 4
@export var ammo: int = 10
## More strength = more damage dealt.
@export var strength: int = 1
## More dexterity = less damage taken.
@export var dexterity: int = 1
@export var coin: int = 999
## Exp needed for level 2. Each level after that costs 3x the last.
@export var next_level_exp: int = 5

@export_group("Movement")
## Walking speed, in pixels per frame.
@export var walk_speed: int = 4
## Walking speed once the player has the Boots.
@export var boots_walk_speed: int = 6
## Speed while holding the Run key.
@export var run_speed: int = 10
## When on, the player can only run after picking up the Boots. Turn this off
## to let them sprint from the start.
@export var requires_boots_to_run: bool = true

@export_group("Starting gear")
@export_enum("Normal Sword", "Kami no Bokken", "Kami Axe")
var starting_weapon: String = "Normal Sword"
@export_enum("Puffa Shield", "Kami Shield")
var starting_shield: String = "Puffa Shield"
## The thing the Shoot key throws. Shuriken costs mana, Snow-ball costs ammo.
@export_enum("Shuriken", "Snow-ball")
var starting_projectile: String = "Shuriken"
