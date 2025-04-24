# Wander State
class_name WanderState
extends State

var wander_timer: float = 0.0
var wander_interval: float = 3.0
var move_speed: float = 7.0
var target_position: Vector3 = Vector3.ZERO
var wander_radius: float = 30.0
var initial_position: Vector3 = Vector3.ZERO
var navigation: NavigationAgent3D = null
var consecutive_hits_taken: int = 0  # Track hits to decide when to take cover

func enter() -> void:
	print("Entering Wander State")
	navigation = owner_node.get_node("NavigationAgent3D")
	initial_position = owner_node.global_transform.origin
	
	# Choose initial wander position
	choose_random_position()

func physics_update(delta: float) -> void:
	wander_timer += delta
	
	# Choose a new position every few seconds
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		choose_random_position()
	
	# Navigate to the chosen position
	if navigation:
		if navigation.is_navigation_finished():
			# If we reached our destination, wait for the next interval
			return
			
		# Get next point in path
		var next_location = navigation.get_next_path_position()
		
		# Calculate direction and move
		var direction = (next_location - owner_node.global_transform.origin).normalized()
		
		# Apply movement (assuming owner_node has a CharacterBody3D component)
		if owner_node is CharacterBody3D:
			owner_node.velocity = direction * move_speed
			owner_node.move_and_slide()
		
		# Rotate towards movement direction
		if direction != Vector3.ZERO:
			var look_direction = direction
			look_direction.y = 0.0
			if look_direction != Vector3.ZERO:
				owner_node.look_at(owner_node.global_transform.origin + look_direction, Vector3.UP)

func choose_random_position() -> void:
	# Generate a random position within the wander radius
	var random_angle = randf() * 2.0 * PI
	var random_radius = randf() * wander_radius
	
	var random_point = Vector3(
		initial_position.x + cos(random_angle) * random_radius,
		initial_position.y,
		initial_position.z + sin(random_angle) * random_radius
	)
	
	# Set the target for navigation
	if navigation:
		navigation.target_position = random_point
		target_position = random_point

func on_take_damage(amount: int) -> void:
	consecutive_hits_taken += 1
	
	# If we've taken multiple hits, consider taking cover
	if consecutive_hits_taken >= 2:
		# This will be checked in check_transitions
		pass


func check_transitions() -> String:
	var state_machine = self.state_machine as EnemyStateMachine
	
	# Check if player is in detection range and visible
	if state_machine.distance_to_player() < state_machine.detection_radius and state_machine.can_see_player():
		return "Attack"
	
	if consecutive_hits_taken >= 1:
		consecutive_hits_taken = 0
		return "TakeCover"
	
	#if state_machine.is_health_low():
		#consecutive_hits_taken = 0  # Reset counter
		#return "TakeCover"
	
	return ""
