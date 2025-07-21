class_name Player
extends CharacterBody3D

@export var mouse_sensitivity := 0.004
@export var attack_power : int = 1
@export_group("Movement Physics")
@export var JUMP_VELOCITY := 5.0  # The height in which the player jumps.
@export var SPEED := 55.0
@export var boost_gauge := 16.0
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
@export var is_paused = false
#@export var is_attacking = false

@onready var collision_area = $CollisionShape3D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var save_data : Dictionary = {}
var physics_delta: float = 0.0

var current_speed = 0
var effect_amount = 1

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var target_head_rotation: Vector3 = Vector3.ZERO

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var skeleton = $Sonic/Armature/Skeleton3D
@onready var third_person := $ThirdPersonPivot
@onready var spawn := get_tree().get_first_node_in_group("SpawnPoint")

var DEFAULT_SPEED : float
var max_boost_gauge : float # Rings cannot make the boost go past this number.
var target_position = Vector3()

#region Audio stuff ---------
func fade_out(audio_node: AudioStreamPlayer, duration: float) -> void:
	var initial_volume = audio_node.volume_db
	var fade_steps = 20
	var fade_time = duration / fade_steps
	for i in range(fade_steps):
		audio_node.volume_db = lerp(initial_volume, -80.0, float(i) / fade_steps)
		await get_tree().create_timer(fade_time).timeout
	audio_node.stop()
	await get_tree().create_timer(0.5).timeout
	audio_node.volume_db = 1.0  # Set volume back to full (0 dB)
#endregion ------------------

#region Enums ---------------
enum State {
	IDLE, # <-- The default state when the player is not doing anything.
	IMPATIENT, # <-- To make Sonic tap his foot, because you're not moving.
	RUNNING, # <-- For running animations.
	WALKING, # <-- Players have the option to walk in the hub world to feel more immersive.
	JUMPING, # <-- For jumping animations.
	LAUNCHED, # <-- Different than a jump: something threw the player.
	FALLING, # <-- Not sure how I will differentiate from jumping but I'll need to find out to make the animations work.
	ATTACKING, # <-- For detecting badniks and other enemies.
	TAUNTING, # <-- For air tricks, to fire an event that gives the player a score boost.
	CUTSCENE, # <-- Will be needed for us to disable player controls during cutscenes.
	TALKING, # <-- Will be needed for us to disable player controls during conversations.
	SWIMMING, # <-- Will need to adjust player speed and gravity when swimming.
	DROWNING, # <-- Will be needed for the timer to count down until the player dies.
	DEAD, # <-- To trigger the respawn system (or game over)
	HURT, # <-- To trigger the hurt animation and invincibility frames.
	WALL_RUN,
	WALL_JUMP,
	BOOSTING,
}

enum StatusState {
	INVINCIBLE,
	SHIELDED,
	SPEED_UP,
	SPEED_DOWN,
	SUPER,
	NONE,
	INVINCIBLEDAMAGE, # Invincibility frames.
}
@export var current_state: State = State.IDLE
@export var current_status: StatusState = StatusState.NONE
#endregion ------------------

#region DEFINING SIGNALS ----
signal rings_changed(new_rings)
signal lives_changed(new_lives)
signal boost_changed(new_boost)
#endregion ------------------

func set_bone_rot(bone, ang):
	var b = skeleton.find_bone(bone)
	var rest = skeleton.get_bone_rest(b)
	var newpose = rest.rotated(Vector3(1.0, 0.0, 0.0), ang.x)
	newpose = newpose.rotated(Vector3(0.0, 1.0, 0.0), ang.y)
	skeleton.set_bone_pose(b, newpose)

func is_moving():
	return abs(velocity.z) > 0 || abs(velocity.x) > 0

func _ready() -> void:
	set_state(State.IDLE)
	# Set these to be the same.
	DEFAULT_SPEED= SPEED
	max_boost_gauge = boost_gauge
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if spawn:
		global_position = spawn.global_position
		print("Spawned player at %s" % spawn.global_position)
	else:
		print("Can't find a spawn point. Was it added?")

func _physics_process(delta: float) -> void:
	print("Current SPEED: ", SPEED)

	if velocity.y < 0:
		set_state(State.FALLING)
	
	if current_state == State.HURT:
		print("Velocity before push: ", velocity) 
		var backward_direction = -transform.basis.z.normalized()
		velocity = -velocity.normalized() * randf_range(8.0,12.0)
		velocity.y += randf_range(2.0,5.0)
		print("Velocity after push: ", velocity) 
		set_state(State.IDLE)
		move_and_slide()
		return


	if current_state == State.ATTACKING:
		global_position = lerp(global_position, target_position, (SPEED * 2) * delta)
		if global_position.distance_to(target_position) < 0.1:
			#is_attacking = false
			set_state(State.IDLE)
	if current_state == State.CUTSCENE:
		return
#region Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
#endregion
	
	#region Floor Normal Rotation
	if is_on_floor():
		if current_state == State.FALLING:
			set_state(State.IDLE)
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
		set_state(State.JUMPING)

		# Set the jump velocity
		velocity.y = JUMP_VELOCITY * jump_direction.y

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var camera_basis = camera.global_transform.basis
	# Direction based on camera
	var forward_direction = camera_basis.z.normalized()  # Forward direction
	var right_direction = camera_basis.x.normalized()      # Right direction
	# This is for looking up and down.
	forward_direction.y = 0
	forward_direction = forward_direction.normalized()

	# Calculate the movement direction
	var direction = (right_direction * input_dir.x + forward_direction * input_dir.y).normalized()
	if direction:
		if current_state == State.ATTACKING:
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
			print(SPEED)
			current_speed = SPEED
			if not current_state in [State.JUMPING, State.FALLING, State.LAUNCHED, State.BOOSTING]:
				set_state(State.RUNNING)
		else:
			velocity.x = (direction.x * SPEED) / 5
			velocity.z = (direction.z * SPEED) / 5
			current_speed = SPEED / 5
			set_state(State.WALKING)
	else:
		if not current_state in [State.JUMPING, State.LAUNCHED, State.FALLING]:
				set_state(State.IDLE)
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
	
	if current_state == State.BOOSTING:
		if not is_moving():
			return
		if boost_gauge < delta: 
			# Not enough boost
			set_state(State.RUNNING)
		boost_gauge = clamp(boost_gauge-delta, 0, max_boost_gauge)
		SPEED = DEFAULT_SPEED * 4
		$Sonic/AnimationPlayer.speed_scale = 2
		$SpeedLines.visible = true
		effect_amount = move_toward(effect_amount, -0.3, 8 * delta)
		$SpeedParticles.emitting = true
	else:
		$Sonic/AnimationPlayer.speed_scale = 1
		$SpeedLines.visible= false
		effect_amount = move_toward(effect_amount, 1.0, 8 * delta)
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
	if event.is_action_pressed("boost") and not current_state == State.BOOSTING and current_state == State.RUNNING and can_boost:
		set_state(State.BOOSTING)
		if has_node("Voice"):
			var audio_files = [
				"res://Audio/Voices/" + GameDefaults.character +"/Boost1.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/Boost2.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/Boost3.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/Boost4.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/jump-att1.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/jump-att2.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/jump-att3.ogg",
				"res://Audio/Voices/" + GameDefaults.character +"/jump-att4.ogg",
			]
			random_vocal(audio_files)
			$BoostBoom.play()
			$BoomSustain.play()
		
	if event.is_action_released("boost"):
		set_state(State.RUNNING)
		#$BoomSustain.stop()
		fade_out($BoomSustain, 0.2)
	
	if event.is_action_pressed("attack_primary") and not current_state == State.CUTSCENE and not is_paused:
		if not attack_cooldown.is_stopped():
			#is_attacking = false
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
				set_state(State.ATTACKING)
				attack_cooldown.start()

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.CUTSCENE:
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
	#is_attacking = false
	$SpeedLines.visible = false

func save():
	save_data = {
		"player": {
			"boost_gauge": boost_gauge,
			"max_boost_gauge": max_boost_gauge,
			"can_boost": can_boost,
			"can_light_dash": can_light_dash,
			"can_shift": can_shift,
			"can_double_jump": can_double_jump,
			"can_quint_jump": can_quint_jump,
			"current_level": get_tree().get_first_node_in_group("level").get_meta("name_ref")
		},
		"rings": rings, # Remove this later.
	}
	return save_data

func load_save(save_data: Dictionary):
	var player_data = save_data["player"]
	var level_path = "res://Levels/" + player_data["current_level"] + ".tscn"
	
	# Restore player properties first
	lives = save_data.get("lives", lives)
	emit_signal("lives_changed", lives)
	rings = save_data.get("rings", rings)
	emit_signal("rings_changed", rings)
	
	# Other stuff to add.
	boost_gauge = player_data.get("boost_gauge", boost_gauge)
	max_boost_gauge = player_data.get("max_boost_gauge", max_boost_gauge)
	can_boost = player_data.get("can_boost", can_boost)
	can_double_jump = player_data.get("can_double_jump", can_double_jump)
	can_light_dash = player_data.get("can_light_dash", can_light_dash)
	can_shift = player_data.get("can_shift", can_shift)
	GameDefaults.game_id = save_data["game_id"]
	
	# this is tricky, right. Load the new level...
	var new_level = load(level_path).instantiate()
	# ... Then delete the current scene
	var current_scene = get_tree().current_scene
	current_scene.queue_free()
	
	# Then add the new level to the scene tree
	get_tree().root.add_child(new_level)
	get_tree().current_scene = new_level
	
	# Now remove the player and HUD from the current_scene, and move to new_level.
	var player = get_tree().get_first_node_in_group("Player")
	var hud = get_tree().get_first_node_in_group("HUD")
	if player:
		player.get_parent().remove_child(player)
		new_level.add_child(player)
	if hud:
		hud.get_parent().remove_child(hud)
		new_level.add_child(hud)

func set_state(new_state: State) -> void:
	if new_state == current_state:
		return  # They're already in this state.
	match current_state:
		State.DEAD:
			return # Can't change state if you're dead
		State.CUTSCENE:
			if new_state != State.TALKING:
				return # Limit state changes during cutscenes
	#print("Changing state from %s to %s" % [State.keys()[current_state], State.keys()[new_state]])
	current_state = new_state
func add_boost(boost_num : float):
	if boost_gauge + boost_num < max_boost_gauge:
		boost_gauge += boost_num
	else:
		boost_gauge = max_boost_gauge

func take_damage():
	set_state(State.HURT)
	var damage_sounds = [
		"res://Audio/Voices/" + GameDefaults.character +"/damage1.ogg",
		"res://Audio/Voices/" + GameDefaults.character +"/damage2.ogg",
		"res://Audio/Voices/" + GameDefaults.character +"/no.ogg",
	]
	random_vocal(damage_sounds)

func random_vocal(bank : Array):
	var random_index = randi() % bank.size()
	var selected_audio = load(bank[random_index])  # Load a random voice
	$Voice.stream = selected_audio	
	$Voice.play()
