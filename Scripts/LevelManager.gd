extends Node3D
class_name LevelManager

@onready var player_scene: PackedScene = preload("res://Actors/player.tscn")
@onready var hud_scene : PackedScene = preload("res://HUD/HUD.tscn")

func _ready() -> void:
	print("Level Manager loaded.")
	var player_check = get_tree().get_first_node_in_group("Player")
	if not player_check:
		spawn_player()
	else:
		var spawn_point = $SpawnPoint
		if spawn_point:
			player_check.global_transform.origin = spawn_point.global_transform.origin

func spawn_player() -> void:
	var player_instance = player_scene.instantiate()
	add_child(player_instance)
	spawn_hud()
	
func spawn_hud() -> void:
	var hud_check = get_tree().get_first_node_in_group("HUD")
	if not hud_check:
		var hud_instance = hud_scene.instantiate()
		add_child(hud_instance)
