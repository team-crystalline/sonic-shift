extends StaticBody3D

enum Types { RINGS, SPEED }
@export var type: Types
@export var loot_count : float = 1

@onready var bill = $itemscreen

func _ready():
	var new_img : Texture = null
	match type:
		Types.RINGS:
			new_img = load("res://Graphics/Textures/itemboxes/ring_billboard.png")
		Types.SPEED:
			new_img = load("res://Graphics/Textures/itemboxes/speed_billboard.png")
	bill.texture = new_img


func _on_static_body_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		$CapsuleSound.play()
		match type:
			Types.RINGS:
				body.rings += loot_count
			Types.SPEED:
				body.DEFAULT_SPEED += 10
		$Poof.emitting = true
		$Model.visible= false
		$itemscreen.visible= false
		body.call("set_state", body.State.IDLE)
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		if body.has_method("cheer"):
			body.call("cheer")
		if body.has_method("bounce"):
				body.call("bounce")
		await get_tree().create_timer(0.5).timeout
		queue_free()
