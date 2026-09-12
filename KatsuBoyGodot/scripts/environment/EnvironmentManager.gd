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


func draw(g2) -> void:
	lighting.draw(g2)
