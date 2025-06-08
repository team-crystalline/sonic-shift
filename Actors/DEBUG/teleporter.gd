extends Area3D

@export var teleport_to: PackedScene = preload("res://Levels/BetaRoom.tscn")

func _on_body_entered(_body: Node3D) -> void:
	if teleport_to:
		get_tree().change_scene_to_packed(teleport_to)
