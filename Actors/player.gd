extends CharacterBody3D
@export var mouse_sensitivity := 0.004
@export var attack_power : int = 1
@export_group("Movement Physics")
@export var JUMP_VELOCITY := 5.0  # The height in which the player jumps.
@export var SPEED := 20.0
@export var boost_gauge := 3.0
@onready var air_speed = SPEED * 0.5
@onready var air_direction_change_speed:= SPEED/10
@export var attack_sight := 10
#region Trampolines
@export var bounce_bonus_base := 2.0
@export var bounce_max := 20.0
@export var bounce_bonus : float
#endregion
@export_group("Collectibles")
@export var rings : int = 0
@export var lives : int = 3
@export_group("Animation")
@export var is_running := true
@export var head_movement_sensitivity := 0.1
@export var head_rotation_lerp_speed := 5.0
@export var patience_level := 3.0 # How patient is Sonic? (He's not)
@export_group("Unlocks")
@export var can_boost := false
@export var can_light_dash := false
@export var can_shift := false
@export var can_double_jump := false
@export var can_quint_jump := false
@export_category("Other Booleans")
@export_group("States")
@export var is_in_a_cutscene := false
@export var is_paused = false
@export var is_attacking = false

@onready var collision_area = $CollisionShape3D
@onready var attack_cooldown: Timer = $AttackCooldown
var physics_delta: float = 0.0

var current_speed = 0
var effect_amount = 1

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_boosting : bool = false
var target_head_rotation: Vector3 = Vector3.ZERO

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var skeleton = $Sonic/Armature/Skeleton3D
@onready var third_person := $ThirdPersonPivot
@onready var spawn := get_tree().get_first_node_in_group("SpawnPoint")

var DEFAULT_SPEED : float
var max_boost_gauge : float # Rings cannot make the boost go past this number.
var target_position = Vector3()

func set_bone_rot(bone, ang):
	var b = skeleton.find_bone(bone)
	var rest = skeleton.get_bone_rest(b)
	var newpose = rest.rotated(Vector3(1.0, 0.0, 0.0), ang.x)
	newpose = newpose.rotated(Vector3(0.0, 1.0, 0.0), ang.y)
	skeleton.set_bone_pose(b, newpose)

func is_moving():
	return abs(velocity.z) > 0 || abs(velocity.x) > 0

func _ready() -> void:
	# Set these to be the same.
	DEFAULT_SPEED= SPEED
	max_boost_gauge = boost_gauge
	#Input.set_mouse_mode(2)
	if spawn:
		global_position = spawn.global_position
		print("Spawned player at %s" % spawn.global_position)
	else:
		print("Can't find a spawn point. Was it added?")

func _physics_process(delta: float) -> void:
	if is_attacking:
		global_position = lerp(global_position, target_position, (SPEED * 3) * delta)
		if global_position.distance_to(target_position) < 0.1:
			is_attacking = false
	if is_in_a_cutscene:
		return
#region Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
#endregion
	
	#region Floor Normal Rotation
	if is_on_floor():
		var floor_norm = get_floor_normal()
		rotation.z = lerp(global_rotation.z, (-floor_norm.x * 0.5), delta * 2)
		rotation.x = lerp(global_rotation.x, (floor_norm.z * 0.5), delta * 2)
	#endregion

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var floor_norm = get_floor_normal()
		var jump_direction = Vector3(0, 1, 0)
		jump_direction = jump_direction.rotated(Vector3(1, 0, 0), floor_norm.x * PI / 2)
		jump_direction = jump_direction.rotated(Vector3(0, 0, 1), floor_norm.z * PI / 2)

		# Set the jump velocity
		velocity.y = JUMP_VELOCITY * jump_direction.y

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var camera_basis = camera.global_transform.basis
	# This moves the player based on camera rotation.
	var direction = (camera_basis.x * input_dir.x + camera_basis.z * input_dir.y).normalized()

	if direction:
		if is_attacking:
			return
		if not is_on_floor():
			# In the air. Reduced speed
			var target_velocity = Vector3(direction.x * air_speed, velocity.y, direction.z * air_speed)
			velocity.x = lerp(velocity.x, target_velocity.x, air_direction_change_speed * delta)
			velocity.z = lerp(velocity.z, target_velocity.z, air_direction_change_speed * delta)
			current_speed = air_speed
		elif is_running == true:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			current_speed = SPEED
		else:
			velocity.x = (direction.x * SPEED) / 5
			velocity.z = (direction.z * SPEED) / 5
			current_speed = SPEED / 5
	else:
		velocity.x = 0
		velocity.z = 0
		current_speed = 0
		$Sonic/AnimationPlayer.play("Standing")
			

	if is_moving():
		if is_running == true:
			$Sonic/AnimationPlayer.play("Run")
		else:
			$Sonic/AnimationPlayer.play("walk")
	move_and_slide()
	
	# Boost logic. Deplete Boost by delta
	
	if is_boosting:
		if not is_moving():
			return
		if boost_gauge < delta: 
			# Not enough boost
			is_boosting = false 
		boost_gauge -= delta
		SPEED = DEFAULT_SPEED * 2
		$Sonic/AnimationPlayer.speed_scale = 2
		$SpeedLines.visible = true
		effect_amount = move_toward(effect_amount, -0.3, 8 * delta)
		$SpeedParticles.emitting = true
	else:
		$Sonic/AnimationPlayer.speed_scale = 1
		$SpeedLines.visible= false
		effect_amount = move_toward(effect_amount, 1.0, 8 * delta)
		is_boosting = false
		SPEED = DEFAULT_SPEED
		$SpeedParticles.emitting = false
	$Control/Fisheye.material.set_shader_parameter("effect_amount", effect_amount)
	
	#region Colliding Checks
	var colliding_bodies = []
	for slide_count in range(get_slide_collision_count()):
		var collision = get_slide_collision(slide_count)
		var collider = collision.get_collider()
		colliding_bodies.append(collider)
	for body in colliding_bodies:
		# and not Input.is_action_pressed("jump")
		if (body.is_in_group("trampoline") and not Input.is_action_pressed("jump")) or not body.is_in_group("trampoline"):
			# Bounced on a trampoline, but did not hold the jump button. Reset bounce_bonus.
			bounce_bonus = bounce_bonus_base
	#endregion

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("boost") and not is_boosting and boost_gauge > 0.5 and is_running and can_boost:
		is_boosting = true
	
	if event.is_action_released("boost"):
		is_boosting = false
	
	if event.is_action_pressed("attack_primary") and not is_in_a_cutscene and not is_paused:
		if not attack_cooldown.is_stopped():
			is_attacking = false
			return
		var space_state = get_world_3d().direct_space_state
		var camera = $Neck/Camera  # Replace with your camera node
		var ray_origin = camera.global_transform.origin
		var ray_direction = -camera.global_transform.basis.z

		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = ray_origin
		ray_query.to = ray_origin + ray_direction * attack_sight
		ray_query.collision_mask = 1  # You can adjust this to only collide with certain layers

		var result = space_state.intersect_ray(ray_query)

		if result:
			if result.collider.is_in_group("attackable"):
				$SpeedLines.visible = true
				var col = result.collider.global_transform.origin
				target_position = Vector3(col.x, col.y + 1, col.z)
				# Don't let them spam! Make a cooldown.
				is_attacking = true
				attack_cooldown.start()

func _unhandled_input(event: InputEvent) -> void:
	if is_in_a_cutscene:
		return
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("walk_toggle"):
		is_running = !is_running
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			#region Pivot Camera
			neck.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))
			third_person.rotate_y(-event.relative.x * mouse_sensitivity)
			#endregion
			# Set the head's rotation to match the camera's rotation
			var min_head_down : float = 0
			var max_head_down : float = 0
			if is_moving() and is_running:
				# He's running, don't make his head go down any more.
				min_head_down = -10
				max_head_down = 60
			else:
				min_head_down = -60
				max_head_down = 80
			var new_head_rotation = Vector3(
				neck.rotation.y,
				#-camera.rotation.x,
				-(clamp(camera.rotation.x, deg_to_rad(min_head_down), deg_to_rad(max_head_down))),
				camera.rotation.z
			)
			$Sonic.rotation = Vector3(neck.rotation.x, neck.rotation.y + deg_to_rad(180), neck.rotation.z)
			set_bone_rot("Head", Vector3(0, new_head_rotation.y, 0))

func _on_attack_cooldown_timeout() -> void:
	is_attacking = false
	$SpeedLines.visible = false
