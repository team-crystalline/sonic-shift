extends Area3D

@export var teleport_to_path: String 

var teleport_to: PackedScene  # This will hold the loaded scene

func _ready() -> void:
	teleport_to = load(teleport_to_path)

func _on_body_entered(_body: Node3D) -> void:
	if teleport_to:
		get_tree().change_scene_to_packed(teleport_to)
