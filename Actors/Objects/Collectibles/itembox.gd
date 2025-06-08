extends StaticBody3D

enum Types { RINGS, LIVES, SPEED }
@export var type: Types
@export var loot_count : float = 1

@onready var bill = $itemscreen

func _ready():
	var new_img : Texture = null
	match type:
		Types.RINGS:
			print("Rings selected")
			new_img = load("res://Graphics/Textures/itemboxes/ring_billboard.png")
		Types.LIVES:
			print("Lives selected")
			new_img = load("res://Graphics/Textures/itemboxes/life_billboard.png")
		Types.SPEED:
			print("Speed selected")
			new_img = load("res://Graphics/Textures/itemboxes/speed_billboard.png")
	bill.texture = new_img
