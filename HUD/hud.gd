extends Control
@onready var ring_label = $PrimaryPanel/RingsLabel
@onready var lives_label = $PrimaryPanel/LivesLabel
@onready var boost_label = $PrimaryPanel/BoostLabel
@onready var loc_label = $LocationLabel
@onready var player := get_tree().get_first_node_in_group("Player")
@onready var level := get_tree().get_first_node_in_group("level")
@onready var pause_screen = %PauseScreen

@onready var state_label = $Panel/StateLabel

var state_array = [
		'IDLE', # <-- The default state when the player is not doing anything.
		'IMPATIENT', # <-- To make Sonic tap his foot, because you're not moving.
		'RUNNING', # <-- For running animations.
		'WALKING', # <-- Players have the option to walk in the hub world to feel more immersive.
		'JUMPING', # <-- For jumping animations.
		'LAUNCHED',
		'FALLING', # <-- Not sure how I will differentiate from jumping but I'll need to find out to make the animations work.
		'ATTACKING', # <-- For detecting badniks and other enemies.
		'TAUNTING', # <-- For air tricks, to fire an event that gives the player a score boost.
		'CUTSCENE', # <-- Will be needed for us to disable player controls during cutscenes.
		'TALKING', # <-- Will be needed for us to disable player controls during conversations.
		'SWIMMING', # <-- Will need to adjust player speed and gravity when swimming.
		'DROWNING', # <-- Will be needed for the timer to count down until the player dies.
		'DEAD', # <-- To trigger the respawn system (or game over)
		'HURT', # <-- To trigger the hurt animation and invincibility frames.
		'WALL_RUN',
		'WALL_JUMP',
		'BOOSTING'
]

func _ready() -> void:
	loc_label.text = level.get_meta("level_name")
	if player.can_boost:
		boost_label.visible=true
	player.connect("rings_changed", Callable(self, "_on_rings_changed")) # We use Callable in Godot 4.4+
	player.connect("lives_changed", Callable(self, "_on_lives_changed"))
	player.connect("boost_changed", Callable(self, "_on_boost_changed"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		pause_screen.visible = false
		player.is_paused = false
		get_tree().paused = false
	else:
		$"../PauseSound".play()
		pause_screen.visible = true
		player.is_paused = true
		get_tree().paused = true


	# Find all sounds playing in Master and BGM buses, lower volume when paused.
	var master_bus_index = AudioServer.get_bus_index("Master")
	var bgm_bus_index = AudioServer.get_bus_index("BGM")
	
	# Adjust volume for Master bus
	if get_tree().paused:
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
	boost_label.text= "Boost: %.2f" % player.boost_gauge
	state_label.text = state_array[player.current_state]

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
