extends Node3D

# Reference to the head bone
@onready var head_bone = $Sonic/GeneralSkeleton/Head

# Sensitivity for mouse movement
var sensitivity = 0.1

func _ready():
	# Hide the mouse cursor and capture it
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# Get the mouse motion
	var mouse_motion = Input.get_mouse_motion()
	
	# Rotate the head bone based on mouse movement
	head_bone.rotation_degrees.x -= mouse_motion.y * sensitivity
	head_bone.rotation_degrees.y -= mouse_motion.x * sensitivity

	# Optional: Clamp the rotation to prevent flipping
	head_bone.rotation_degrees.x = clamp(head_bone.rotation_degrees.x, -90, 90)
