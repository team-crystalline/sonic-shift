@tool
extends StaticBody3D

@export var size: Vector2 = Vector2(1, 1):
	set(value):
		size = value
		update_sizes()

func update_sizes():
	$bricks.scale = Vector3(size.x, size.y, 1)
	$capping.scale = Vector3(size.x, 1, 1)
	$CollisionShape3D.shape = BoxShape3D.new()
	$CollisionShape3D.shape.extents = Vector3(size.x / 2, size.y / 2, 0.5)
