extends RigidBody3D
@export var hit_points : int = 1
@export_category("Movement")
@export var wander_speed : float = 2
@export var change_direction_time : float = 2.0
@export var min_wander_distance : float = 1.0
@export var max_wander_distance : float = 2.0

var direction: Vector3 = Vector3.ZERO
var sound_played: bool = false
var change_direction_timer: Timer
var move_distance: float = 0.0
var is_moving : bool = false
var distance_moved: float = 0.0

func _ready() -> void:
	change_direction_time *= randf_range(1, 1.5)
	change_direction_timer = Timer.new()
	change_direction_timer.wait_time = change_direction_time
	change_direction_timer.connect("timeout", Callable(self, "_on_change_direction_timeout"))
	add_child(change_direction_timer)
	change_direction_timer.start()
	_change_direction()

func _on_change_direction_timeout() -> void:
	if is_moving:
		is_moving = false  # Stop moving
		distance_moved = 0.0  # Reset the distance moved
		await get_tree().create_timer(1).timeout  # Wait for stop time
	_change_direction()

func _change_direction() -> void:
	var new_x = randf_range(-2, 2)
	var new_y = randf_range(-2, 2)
	move_distance = randf_range(min_wander_distance, max_wander_distance)
	direction = Vector3(new_x, 0, new_y).normalized()
	is_moving = true

func _on_hit_box_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if body.is_attacking:
			hit_points -= body.attack_power

func _process(delta: float) -> void:
	if hit_points <= 0 and not sound_played:
		var player_sound = get_tree().get_first_node_in_group("Player").get_node("PoofSound")  # Adjust the path if necessary
		if not player_sound.playing:
			player_sound.play()
			sound_played = true
		
		set_collision_layer_value(1,false)
		set_collision_mask_value(1, false)
		$Model.visible=false
		$ModelCollision.visible=false
		$HitBox.visible=false
		$Poof.emitting = true # Doesn't show because the object is deleted
		await get_tree().create_timer(1).timeout
		queue_free()
	if is_moving:
		var movement = direction * wander_speed * delta
		distance_moved += movement.length()  # Track the distance moved
		move_and_collide(movement)
	else:
		distance_moved = 0
