extends Control
@onready var ring_label = $RingsLabel
@onready var lives_label = $LivesLabel
@onready var boost_label = $BoostLabel
@onready var speed_label = $SpeedLabel
@onready var loc_label = $LocationLabel
@onready var player := get_tree().get_first_node_in_group("Player")
@onready var level := get_tree().get_first_node_in_group("level")
@onready var pause_screen = %PauseScreen

func _ready() -> void:
	loc_label.text = level.get_meta("level_name")
	if player.can_boost:
		boost_label.visible=true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	if pause_screen.visible:
		pause_screen.visible = false
		set_pause_state(false)
		player.is_paused = false
	else:
		$"../PauseSound".play()
		pause_screen.visible = true
		set_pause_state(true)
		player.is_paused = true

func set_pause_state(paused: bool) -> void:
	# Looking for any nodes we've labelled as "can_pause", and pausing all of them.
	for node in get_tree().get_nodes_in_group("can_pause"):
		node.set_process(!paused)
		node.set_physics_process(!paused)
		#var animation_player = node.get_node("AnimationPlayer")
		#if animation_player:
			## Pause any animations
			#if paused:
				#animation_player.stop()
			#else:
				#animation_player.play()

	# Find all sounds playing in Master and BGM buses, lower volume when paused.
	var master_bus_index = AudioServer.get_bus_index("Master")
	var bgm_bus_index = AudioServer.get_bus_index("BGM")
	
	# Adjust volume for Master bus
	if paused:
		AudioServer.set_bus_volume_db(master_bus_index, -10)  # Mute or lower volume significantly
		AudioServer.set_bus_volume_db(bgm_bus_index, -10)     # Mute or lower volume significantly
	else:
		AudioServer.set_bus_volume_db(master_bus_index, 0)    # Reset to original volume
		AudioServer.set_bus_volume_db(bgm_bus_index, 0)       # Reset to original volume


func _process(_delta: float) -> void:
	ring_label.text= "Rings: %d" % player.rings
	lives_label.text= "Lives: %d" % player.lives
	boost_label.text= "Boost: %s" % player.boost_gauge
	#speed_label.text = "%d" % (player.current_speed * 4)

	
	if player.is_running == true:
		$Run.visible= true
		$Walk.visible= false
	else:
		$Run.visible= false
		$Walk.visible=true


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_resume_button_pressed() -> void:
	toggle_pause()
