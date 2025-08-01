extends Control

@export var next_scene : PackedScene = preload("res://Levels/BetaRoom.tscn")


func _ready():
	if GameDefaults.skip_title:
		get_tree().change_scene_to_packed(next_scene)

func _input(event: InputEvent) -> void:
	var can_continue = get_meta("can_continue") # Call on input, since an animationplayer is modifying this.
	if event.is_action_pressed("ui_accept") and can_continue:
		$"../AnimationPlayer".play("FadeOut")
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://Screens/Title.tscn")
