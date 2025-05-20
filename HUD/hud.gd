extends Control
@onready var ring_label = $RingsLabel
@onready var lives_label = $LivesLabel
@onready var boost_label = $BoostLabel
@onready var player := get_tree().get_first_node_in_group("Player")
@onready var animation_player = $AnimationPlayer

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#animation_player.play("float")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	ring_label.text= "Rings: %d" % player.rings
	lives_label.text= "Lives: %d" % player.lives
	boost_label.text= "Boost: %s" % player.boost_gauge
