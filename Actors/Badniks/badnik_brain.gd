extends RigidBody3D
@export var hit_points : int = 1
@export_category("Movement")
@export var wander_speed : float = 2
@export var change_direction_time : float = 2.0
@export var min_wander_distance : float = 0.2
@export var max_wander_distance : float = 2.0
@export var type = GameDefaults.BadnikType.DOCILE_WANDERER

var direction: Vector3 = Vector3.ZERO
var change_direction_timer: Timer
var move_distance: float = 0.0
var sound_played = false
var sonic_enums : Array

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DEAD,
	WANDERING
}
@export var current_state: State = State.IDLE

func _ready() -> void:
	if type in [GameDefaults.BadnikType.DOCILE_WANDERER, GameDefaults.BadnikType.WANDERER]:
		current_state = State.WANDERING

func _on_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if body.current_state in [body.State.ATTACKING, body.State.BOOSTING] or body.current_status in [body.StatusState.SUPER, body.StatusState.INVINCIBLE]:
			hit_points -= body.attack_power
			if body.has_method("add_boost"):
				body.call("add_boost", 0.5)
			if body.current_state == body.State.ATTACKING:
				body.velocity.y = clamp(body.velocity.y + 5, 0, 15)
				body.call("set_state", body.State.IDLE)
		else:
			if body.has_method("take_damage"):
				body.call("take_damage")

func _process(delta: float) -> void:
	if hit_points <= 0 and not sound_played:
		$"../PoofSound".play()
		sound_played = true
		set_collision_layer_value(1,false)
		set_collision_mask_value(1, false)
		$Model.visible=false
		$"../Poof".emitting = true
		$"../Gear1".emitting = true
		$"../Gear2".emitting = true
		var player = get_tree().get_first_node_in_group("Player")
		await get_tree().create_timer(0.5).timeout
		if player.current_state == player.State.ATTACKING:
			player.current_state = player.State.IDLE
			if player.has_method("bounce"):
				player.call("bounce")
		queue_free()
	if current_state == State.MOVING:
		move_and_collide(direction * wander_speed * delta)
