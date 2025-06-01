extends Control
@onready var ring_label = $RingsLabel
@onready var lives_label = $LivesLabel
@onready var boost_label = $BoostLabel
@onready var coords_label = $CoordsLabel
@onready var player := get_tree().get_first_node_in_group("Player")

func _process(_delta: float) -> void:
	ring_label.text= "Rings: %d" % player.rings
	lives_label.text= "Lives: %d" % player.lives
	boost_label.text= "Boost: %s" % player.boost_gauge
	coords_label.text = "x: %.2f\ny: %.2f\nz: %.2f" % [player.position.x, player.position.y, player.position.z]
	if player.is_running == true:
		$Run.visible= true
		$Walk.visible= false
	else:
		$Run.visible= false
		$Walk.visible=true
