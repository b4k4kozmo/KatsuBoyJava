class_name Rect
extends RefCounted
## Stand-in for java.awt.Rectangle.
##
## Godot's own Rect2i is a VALUE type, but the Java code relies on rectangles
## being mutable objects that can be aliased (e.g. Player.attack_area points at
## the current weapon's rectangle, and CollisionChecker temporarily shifts a
## solid_area and then restores it). So we keep a tiny reference-type class
## with exactly the fields java.awt.Rectangle had.

var x: int
var y: int
var width: int
var height: int


func _init(x: int = 0, y: int = 0, width: int = 0, height: int = 0) -> void:
	self.x = x
	self.y = y
	self.width = width
	self.height = height


## Same semantics as java.awt.Rectangle.intersects(): an empty rectangle
## (zero or negative width/height) never intersects anything.
func intersects(r: Rect) -> bool:
	if width <= 0 or height <= 0 or r.width <= 0 or r.height <= 0:
		return false
	return (r.x < x + width and r.x + r.width > x
			and r.y < y + height and r.y + r.height > y)
