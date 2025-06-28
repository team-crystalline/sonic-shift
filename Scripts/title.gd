extends Control
@export var next_scene : PackedScene = preload("res://Levels/BetaRoom.tscn")

func _ready():
	if GameDefaults.skip_title:
		get_tree().change_scene_to_packed(next_scene)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(next_scene)
