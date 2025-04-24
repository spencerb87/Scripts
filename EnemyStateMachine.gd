# Enemy State Machine
class_name EnemyStateMachine
extends StateMachine

# Configuration properties that can be set in the Inspector
@export var detection_radius: float = 30.0
@export var attack_range: float = 30.0
@export var health_threshold_for_cover: float = 40.0  # Take cover when health below this percentage

# Reference to the player
var player: Node = null

func _ready() -> void:
	# Call parent _ready which will register states
	super._ready()
	
	#wait for time before checking for players
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	
	# Find player in the scene
	player = get_tree().get_nodes_in_group("player")[0]

func _register_states() -> void:
	# Create and register all states
	var wander_state = WanderState.new()
	wander_state.name = "Wander"
	add_state(wander_state)
	
	var attack_state = AttackState.new()
	attack_state.name = "Attack"
	add_state(attack_state)
	
	var take_cover_state = TakeCoverState.new()
	take_cover_state.name = "TakeCover"
	add_state(take_cover_state)

func _physics_process(delta: float) -> void:
	# Handle normal state update
	super._physics_process(delta)
	
	# Check for state transitions if we have a current state
	if current_state:
		var new_state = current_state.check_transitions()
		if new_state and new_state != current_state.name:
			change_state(new_state)

# Get distance to player
func distance_to_player() -> float:
	if player:
		return owner_node.global_transform.origin.distance_to(player.global_transform.origin)
	return 9999.0 # Return a large value if player not found

# Check if player is in sight
func can_see_player() -> bool:
	if not player:
		return false
		
	# Direction to player
	var space_state = owner_node.get_world_3d().direct_space_state
	var direction = player.global_transform.origin - owner_node.global_transform.origin
	
	# Origin slightly above the ground to avoid terrain collision
	var ray_origin = owner_node.global_transform.origin + Vector3(0, 1, 0)
	
	# Cast ray to player position (head level)
	var ray_end = player.global_transform.origin + Vector3(0, 1.5, 0)
	
	# Create physics ray query params
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [owner_node] # Exclude self from collision
	query.collision_mask = 1 # Collision mask for world objects
	
	var ray_result = space_state.intersect_ray(query)
	
	# If we hit nothing or hit the player, then we can see the player
	return ray_result.is_empty() or ray_result.collider == player
	
# Check if health is low (for cover decisions)
func is_health_low() -> bool:
	# Get the health from the parent enemy
	if owner_node.has_method("get_health_percentage"):
		return owner_node.get_health_percentage() < health_threshold_for_cover
	elif owner_node.has_variable("health") and owner_node.has_variable("max_health"):
		return float(owner_node.health) / owner_node.max_health < (health_threshold_for_cover / 100.0)
	return false
