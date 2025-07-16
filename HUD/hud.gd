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
	player.connect("rings_changed", Callable(self, "_on_rings_changed")) # We use Callable in Godot 4.4+
	player.connect("lives_changed", Callable(self, "_on_lives_changed"))
	player.connect("boost_changed", Callable(self, "_on_boost_changed"))

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
		AudioServer.set_bus_volume_db(master_bus_index, -10)
		AudioServer.set_bus_volume_db(bgm_bus_index, -10)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		AudioServer.set_bus_volume_db(master_bus_index, 0)
		AudioServer.set_bus_volume_db(bgm_bus_index, 0)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	ring_label.text= "Rings: %d" % player.rings
	lives_label.text= "Lives: %d" % player.lives
	boost_label.text= "Boost: %s" % player.boost_gauge

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

func _on_save_button_pressed() -> void:
	$PauseScreen/LoadFilePanel.visible = false
	var fetched_save : Array = GameSaves.fetch_save()
	if len(fetched_save) == 0:
		# Can we get a name?
		var save_name_panel = get_tree().get_first_node_in_group("SaveNameInput")
		save_name_panel.visible = true
	else:
		GameSaves.save_game()

func _on_load_button_pressed() -> void:
	$PauseScreen/SaveFilePanel.visible = false
	$PauseScreen/LoadFilePanel.visible=true
	GameSaves.load_all_saves()

func _on_save_name_button_pressed() -> void:
	if len($PauseScreen/SaveFilePanel/NameInput.text) == 0:
		print("Hey, put a name in.")
		return
	else:
		GameSaves.save_game($PauseScreen/SaveFilePanel/NameInput.text)

func _on_load_file_button_pressed() -> void:
	var selected_indices = $PauseScreen/LoadFilePanel/SavesList.get_selected_items()
	if len(selected_indices) == 0:
		print("Nothing selected.")
		return
	
	var selected_ind = selected_indices[0]
	var selected_save_name = $PauseScreen/LoadFilePanel/SavesList.get_item_text(selected_ind) 
	var selected_save_id = $PauseScreen/LoadFilePanel/SavesList.get_item_metadata(selected_ind)
	GameSaves.load_game(selected_save_id) 


func _on_rings_changed(new_rings):
	ring_label.text = "Rings: %d" % new_rings

func _on_lives_changed(new_lives):
	lives_label.text = "Lives: %d" % new_lives

func _on_boost_changed(new_boost):
	boost_label.text = "Boost: %s" % new_boost
