extends Node
class_name SaveManager

# Going to explicitly type this so it can't be messed with later.
var save_data : Dictionary = {
	#"rings": GameDefaults.rings, # Add back in when goal rings are made and we can add these in.
	"lives": GameDefaults.lives,
	"playing_as": GameDefaults.character,
	"name": GameDefaults.save_name,
	"game_id": GameDefaults.game_id
} 
func _ready() -> void:
	print("Save Manager loaded. Game ID: %s" % GameDefaults.game_id)

func save_game( name_of_save : String = "") -> void:
	# Grab the .save file they picked.
	var file_path = "user://" + str(GameDefaults.game_id) + ".save"
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file != null:
		var save_nodes = get_tree().get_nodes_in_group("Persist")
		var new_save_data = save_data.duplicate(true) 
		# If this isn't blank, this means this is a new save file.
		if name_of_save != "":
			new_save_data["name"] = name_of_save
			GameDefaults.save_name = name_of_save

		# if the node has a save method, grab its data here.
		for node in save_nodes:
			if node.has_method("save"):
				var node_data = node.call("save")
				new_save_data.merge(node_data)
			else:
				print("Can't save node %s, because it doesn't have a save() method. Give this node a save() method and try again." % node)
		var json_string = JSON.stringify(new_save_data)
		save_file.store_line(json_string)
		save_file.close()
		# File saved!
		print("File saved. File: %s" % save_file)
	else:
		# Something happened.
		print("Failed to open file for writing: ", file_path)


func load_all_saves():
	# Gonna list all files first.
	var dir = DirAccess.open("user://")  # Open the user directory
	var all_files = dir.get_files()
	
	# Now, get the SaveList.
	var loading_list = get_tree().get_first_node_in_group("SaveList")
	if loading_list == null or not loading_list is ItemList:
		# No savelist. Exit.
		print("There is no ItemList with the group SaveList. We cannot load saves.")
		return
	
	# Clear the ItemList
	loading_list.clear()
	loading_list.visible = true

	for file in all_files:
		if file.ends_with(".save"):
			var file_name = file.replace(".save", "")
			var file_path = "user://" + file
			var save_file = FileAccess.open(file_path, FileAccess.READ)
			
			if save_file != null:
				var save_data_name = save_file.get_as_text()
				save_file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(save_data_name)
				
				if parse_result == OK:
					var save_name = json.get_data().get("name", "Untitled")
					var playing_as = json.get_data().get("playing_as", "Unknown Character")
					var display_text : String
					if playing_as.ends_with("s"):
						display_text = save_name + " - " + playing_as + "' Story"
					else:
						display_text = save_name + " - " + playing_as + "'s Story"
					var item_index = loading_list.add_item(display_text)
					# Make it a row.
					loading_list.set_item_metadata(item_index, file_name)
				else:
					# This file is fucked apparently.
					print("Failed to parse JSON for file: ", file_name)
			else:
				print("Failed to open file: ", file_path)

func load_game(save_name : String) -> void:
	# Hated this function!!!
	var file_path = "user://" + save_name + ".save"
	var save_file = FileAccess.open(file_path, FileAccess.READ)
	if save_file != null:
		var save_data_name = save_file.get_as_text()
		save_file.close()
		
		# Process the save data as needed
		var json = JSON.new()
		var parse_result = json.parse(save_data_name)
		
		if parse_result == OK:
			var save_data = json.get_data()
			
			var load_nodes = get_tree().get_nodes_in_group("Persist")
			for node in load_nodes:
				# Load each node's loading function. The player's is a nightmare.
				if node.has_method("load_save"):
					node.call("load_save", save_data)
		else:
			print("Failed to parse JSON for file: ", save_name)
	else:
		print("Failed to open file: ", file_path)

# Is this used? I'm too scared to remove it.
func get_save_data() -> Dictionary:
	return save_data

func set_save_data(data: Dictionary) -> void:
	save_data = data
	save_game()

# Used when saving a game.
func fetch_save() -> Array:
	var dir = DirAccess.open("user://")  # Open the user directory
	var all_files = dir.get_files()
	var valid_files := []
	for f in all_files:
		if f.ends_with(".save") and f.begins_with(str(GameDefaults.game_id)):
			valid_files.append(f)
	return valid_files
