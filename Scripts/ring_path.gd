extends Path3D

# Preload the ring scene
var RingScene = preload("res://Actors/ring.tscn")

func _ready() -> void:
	var world_position = self.global_position
	if self.curve:
		# Go through all points in the path.
		for i in range(self.curve.get_point_count()):
			var point = self.curve.get_point_position(i)
			var new_pos = point + world_position  # Combine the point with the world position
			
			var new_ring = RingScene.instantiate()
			new_ring.position = new_pos
			
			# Add the ring to the current node or a specific parent node
			add_child(new_ring)  # or use a specific parent node
			
			# Debugging output
			print("Ring instantiated at position: ", new_ring.position)
	else:
		print("No curve found in Path3D.")
