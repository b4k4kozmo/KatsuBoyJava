extends SceneTree

func _init():
	for name in ["WorldMap", "MushroomHut", "TestMap"]:
		var ps := load("res://scenes/maps/%s.tscn" % name) as PackedScene
		var inst = ps.instantiate()
		var layer = inst.get_node_or_null("Tiles")
		if layer == null:
			for c in inst.get_children():
				if c is TileMapLayer:
					layer = c
					break
		if layer:
			var r: Rect2i = layer.get_used_rect()
			print("%-14s used_rect pos=%s size=%s  (screen is 20x12 tiles)" % [name, r.position, r.size])
		else:
			print("%-14s no TileMapLayer found; children: %s" % [name, inst.get_children()])
		# Player start marker, if any
		for c in inst.get_children():
			if c.get_class() == "Node2D" and "PlayerStart" in c.name:
				print("    player start node '%s' at %s" % [c.name, c.position])
		inst.free()
	quit()
