class_name EnvironmentManager
extends RefCounted
## Java: environment/EnvironmentManager.java

var gp
var lighting: Lighting
var clock: GameClock


func _init(gp) -> void:
	self.gp = gp


func setup() -> void:
	clock = GameClock.new(gp)
	lighting = Lighting.new(gp)
	lighting.refresh()


func update() -> void:
	clock.update()
	lighting.update()


## Drawing is LightingOverlay's job now (a node in main.tscn).
