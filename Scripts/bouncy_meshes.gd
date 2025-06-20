extends Area3D

@export var bounce_height := 10.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bouncy_objects"):
		var total_bounce = bounce_height + body.bounce_bonus
		# Can we go higher?
		if total_bounce > body.bounce_max:
			total_bounce = body.bounce_max # Yeah dude!
		
		body.velocity.y += total_bounce
		# If you're pressing jump, you can bounce even higher.
		if Input.is_action_pressed("jump"):
			# Go higher! But not higher than the max bounce.
			body.bounce_bonus = clamp(body.bounce_bonus + 4, body.bounce_bonus_base, body.bounce_max)
		else:
			# Oop. Didn't hold jump. Reset the bonus.
			body.bounce_bonus = body.bounce_bonus_base

# Connect the signal in the editor
func _ready() -> void:
	# Connect the body entered signal
	$CollisionShape3D.connect("body_entered", Callable(self, "_on_body_entered"))
