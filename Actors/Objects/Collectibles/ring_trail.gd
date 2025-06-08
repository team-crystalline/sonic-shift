#extends Node3D
#@onready var ring = preload("res://Actors/Objects/Collectibles/ring.tscn")
#@export var path_points: Array[Vector3] = []
#@export var num_rings_per_segment: int = 3
#
#func _ready() -> void:
	#print("Path points: ", path_points)
	#for i in range(path_points.size() - 1):
		#var start_point = path_points[i]
		#var end_point = path_points[i + 1]
		#for j in range(1, num_rings_per_segment + 1):
			#var t = j / float(num_rings_per_segment + 1)
			#var point = start_point + (end_point - start_point) * t
			#var new_ring = ring.instantiate()
			#if is_inside_tree():
				#new_ring.global_position = point
				#add_child(new_ring)

extends Node3D
@onready var ring = preload("res://Actors/Objects/Collectibles/ring.tscn")
@export var path_points: Array[Vector3] = []
@export var num_rings_per_segment: int = 3

func _ready() -> void:
	call_deferred("_create_rings")

func _create_rings() -> void:
	for i in range(path_points.size() - 1):
		var start_point = path_points[i]
		var end_point = path_points[i + 1]
		for j in range(1, num_rings_per_segment + 1):
			var t = j / float(num_rings_per_segment + 1)
			var point = start_point + (end_point - start_point) * t
			var new_ring = ring.instantiate()
			add_child(new_ring)
			new_ring.global_position = global_position + point
