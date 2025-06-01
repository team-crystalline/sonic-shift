extends CharacterBody3D

@export_group("Movement Physics")
@export var JUMP_VELOCITY : float = 5  # The height in which the player jumps.
@export var SPEED : float = 15
@export var boost_gauge : float = 30
@export_group("Collectibles")
@export var rings : int = 0
@export var lives : int = 3
@export_group("Animation")
@export var head_movement_sensitivity = 0.1
@export var head_rotation_lerp_speed = 5.0
@export var patience_level : float = 3 # How patient is Sonic? (He's not)

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
var is_running : bool = true

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("boost") and not is_boosting and boost_gauge > 0.5 and is_running:
		is_boosting = true
	
	if event.is_action_released("boost"):
		is_boosting = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("walk_toggle"):
		is_running = !is_running
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			#region Pivot Camera
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
			third_person.rotate_y(-event.relative.x * 0.01)
			#endregion
			# Set the head's rotation to match the camera's rotation
			var new_head_rotation = Vector3(
				neck.rotation.y,
				-camera.rotation.x,
				camera.rotation.z
			)
			set_bone_rot("Reference", Vector3(0, new_head_rotation.x, 0))
			set_bone_rot("Head", Vector3(0, new_head_rotation.y, 0))

func _process(_delta: float) -> void:
	# Non-physics processing
	if rings % 100 == 0 and rings > 0:
		lives += 1

func _physics_process(delta: float) -> void:
#region Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
#endregion
	
#region Floor Normal Rotation
	if is_on_floor():
		var floor_norm = get_floor_normal()
		rotation.z = lerp(global_rotation.z, -floor_norm.x, delta * 2)
		rotation.x = lerp(global_rotation.x, floor_norm.z, delta * 2)
#endregion
		
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var camera_basis = camera.global_transform.basis
	# This moves the player based on camera rotation.
	var direction = (camera_basis.x * input_dir.x + camera_basis.z * input_dir.y).normalized()
	if direction:
		if is_running == true:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = (direction.x * SPEED)/5
			velocity.z = (direction.z * SPEED)/5
	else:
		velocity.x = 0
		velocity.z = 0
		$Sonic/AnimationPlayer.play("Standing")
			

	if is_moving():
		#var look_direction = Vector2(velocity.z, velocity.y)
		$Sonic.rotation.y = lerp_angle($Sonic.rotation.y, 3, delta * 8)
		if is_running == true:
			$Sonic/AnimationPlayer.play("Run")
		else:
			$Sonic/AnimationPlayer.play("walk")
	move_and_slide()
	
	# Boost logic. Deplete Boost by delta
	if is_boosting:
		if boost_gauge < delta: 
			# Not enough boost
			is_boosting = false 
		boost_gauge -= delta
		SPEED = DEFAULT_SPEED * 3
	else:
		is_boosting = false
		SPEED = DEFAULT_SPEED
