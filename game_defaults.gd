extends Node

# To skip the title screen, make this true!
var skip_title = true
var lives = 3
var rings = 0 # <-- This is the global bank of rings in a save file!
var game_id = randi()
var character = "Sonic" # Sonic will be the fallback I guess.
var save_name = "Untitled"
