extends Node

@export var player_scene: PackedScene

func _ready():
	spawn_player()

func spawn_player():
	# Get all spawn points
	var spawn_points = get_tree().get_nodes_in_group("playerspawn")
	
	if spawn_points.size() > 0:
		# Choose a spawn point (randomly or based on some logic)
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		
		# Instantiate the player
		var player_instance = player_scene.instantiate()
		add_child(player_instance)
		
		# Set player position and rotation to match the spawn point
		player_instance.global_position = spawn_point.global_position
		player_instance.global_rotation = spawn_point.global_rotation
	else:
		push_error("No spawn points found in 'playerspawn' group!")
