extends Area3D

@export var teleport_to_path: String  # Use a string to hold the path to the scene

var teleport_to: PackedScene  # This will hold the loaded scene

func _ready() -> void:
	# Load the scene using the path provided in the editor
	teleport_to = load(teleport_to_path)
	print("Teleport to (in _ready): %s" % teleport_to)

func _on_body_entered(_body: Node3D) -> void:
	print("Teleport to (in _on_body_entered): %s" % teleport_to)
	if teleport_to:
		get_tree().change_scene_to_packed(teleport_to)
