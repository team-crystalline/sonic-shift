extends Node

# To skip the title screen, make this true!
var skip_title = true
var lives = 3
var rings = 0 # <-- This is the global bank of rings in a save file!
var game_id = randi()
var save_name = "Untitled"

#region Ranks -----
# Rank enums
enum Rank {
	E = 0, # Worst
	D = 1,
	C = 2,
	B = 3,
	A = 4,
	S = 5,
	SPlusPlus = 6 # Best
}
# Usage: if GameDefaults.is_better_rank(GameDefaults.Rank.C, GameDefaults.Rank.A)
# (This would be false. C is not better than A.)
func is_better_rank(current_rank : Rank, old_rank: Rank):
	return old_rank < current_rank
#endregion --------
enum Characters {
	SONIC,
	TAILS,
	KNUCKLES,
	AMY,
	SHADOW,
	ROUGE
}
var character = "Sonic" # Sonic will be the fallback I guess.

enum BadnikType {
	DOCILE_WANDERER, # This badnik just moves around; it won't attack if you're near.
	WANDERER,
	CHASER
}

func get_enum_keys(enum_type) -> Array:
	var keys = []
	
	# Use reflection to get the enum values
	for key in enum_type:
		keys.append(key)
	
	return keys
