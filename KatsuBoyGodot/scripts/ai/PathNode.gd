class_name PathNode
extends RefCounted
## Java: ai/Node.java
##
## Renamed to PathNode because "Node" is Godot's own base class name.

var parent: PathNode
var col: int
var row: int
var g_cost: int
var h_cost: int
var f_cost: int
var solid: bool
var open: bool
var checked: bool


func _init(col: int, row: int) -> void:
	self.col = col
	self.row = row
