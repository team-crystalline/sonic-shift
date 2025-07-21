extends Area3D

@onready var player := get_tree().get_first_node_in_group("Player")
@onready var spawn := get_tree().get_first_node_in_group("SpawnPoint")

func _on_body_entered(_body: Node3D) -> void:
	if spawn:
		player.global_position = spawn.global_position
		player.SPEED = player.DEFAULT_SPEED # <-- In case they boosted off the stage.
		player.boost_gauge = 0 # <-- No boost = punishment
		player.rings = 0
