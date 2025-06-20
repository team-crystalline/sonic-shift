extends Camera3D

func _process(delta: float) -> void:
	var character = $"../.."
	var body_should_not_cull = get_cull_mask_value(20)
	if character.is_in_a_cutscene:
		body_should_not_cull = true
	else:
		body_should_not_cull = false
