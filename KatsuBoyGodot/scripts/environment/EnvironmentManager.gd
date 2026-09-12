class_name EnvironmentManager
extends RefCounted
## Java: environment/EnvironmentManager.java

var gp
var lighting: Lighting


func _init(gp) -> void:
	self.gp = gp


func setup() -> void:
	lighting = Lighting.new(gp)


func update() -> void:
	lighting.update()


## Drawing is LightingOverlay's job now (a node in main.tscn).
