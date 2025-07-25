extends Area3D

@export var teleport_to_path: String 

var teleport_to: PackedScene  # This will hold the loaded scene

func _ready() -> void:
	teleport_to = load(teleport_to_path)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return # Otherwise badniks will make you teleport.
	if teleport_to:
		get_tree().change_scene_to_packed(teleport_to)


func _on_danger_zone_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	$CanvasLayer/Glitch.visible = true
	AudioServer.set_bus_effect_enabled(1, 0, true)

func _on_danger_zone_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	$CanvasLayer/Glitch.visible = false
	AudioServer.set_bus_effect_enabled(1, 0, false)
