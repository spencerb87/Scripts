class_name TakeCoverState
extends State

var move_speed: float = 6.0  # Slightly faster than normal to get to cover quickly
var cover_position: Vector3 = Vector3.ZERO
var cover_found: bool = false
var hide_duration: float = 5.0
var hide_timer: float = 0.0
var time_in_cover: float = 0.0
var minimum_cover_time: float = 5.0  # Minimum time before transitioning out
var navigation: NavigationAgent3D = null
var debug_mode: bool = true  # Set to true to see debug messages
var max_cover_search_distance: float = 20.0  # Maximum distance to search for cover
var current_cover_point = null  # Reference to the current cover point
var los_check_height: float = 1.5  # Height above ground for line of sight checks

func enter() -> void:
	if debug_mode:
		print("Entering Take Cover State")
	
	navigation = owner_node.get_node("NavigationAgent3D")
	cover_found = false
	hide_timer = 0.0
	time_in_cover = 0.0
	current_cover_point = null
	
	# Find cover immediately
	find_cover()

func physics_update(delta: float) -> void:
	time_in_cover += delta
	var state_machine = self.state_machine as EnemyStateMachine
	
	if not cover_found:
		# If we haven't found cover yet, try again
		find_cover()
		return
	
	# If we're at cover location, stay there for the hide duration
	if navigation.is_navigation_finished():
		# We're in cover, count the timer
		hide_timer += delta
		
		# Make enemy face away from the player while in cover
		if state_machine.player:
			var direction = owner_node.global_transform.origin - state_machine.player.global_transform.origin
			direction.y = 0  # Keep upright
			
			# Only look if direction is valid
			if direction.length_squared() > 0.001:
				owner_node.look_at(owner_node.global_transform.origin + direction, Vector3.UP)
	else:
		# Navigate to cover
		var next_location = navigation.get_next_path_position()
		var direction = (next_location - owner_node.global_transform.origin)
		
		# Only move if direction is valid
		if direction.length_squared() > 0.001:
			direction = direction.normalized()
			
			# Move toward cover
			if owner_node is CharacterBody3D:
				owner_node.velocity = direction * move_speed
				owner_node.move_and_slide()
			
			# Rotate toward movement direction
			var look_direction = direction
			look_direction.y = 0.0
			if look_direction.length_squared() > 0.001:
				owner_node.look_at(owner_node.global_transform.origin + look_direction, Vector3.UP)
		else:
			# If direction is too small, stop moving
			if owner_node is CharacterBody3D:
				owner_node.velocity = Vector3.ZERO

# Find a suitable cover point from the "cover" group
func find_cover() -> void:
	var state_machine = self.state_machine as EnemyStateMachine
	var player = state_machine.player
	
	if not player:
		return
		
	if debug_mode:
		print("TakeCoverState: Searching for cover...")
	
	# Get all nodes in the "cover" group
	var cover_points = owner_node.get_tree().get_nodes_in_group("cover")
	
	if cover_points.is_empty():
		if debug_mode:
			print("TakeCoverState: No cover points found in 'cover' group!")
		strategic_retreat()
		return
	
	# Filter and score cover points based on distance and position
	var valid_cover_points = []
	
	for point in cover_points:
		var point_pos = point.global_transform.origin
		
		# Check if the cover point is within acceptable distance
		var distance_to_cover = owner_node.global_transform.origin.distance_to(point_pos)
		if distance_to_cover > max_cover_search_distance:
			continue
		
		# Is the cover point reachable?
		navigation.target_position = point_pos
		await owner_node.get_tree().process_frame  # Wait for navigation to update
		
		if navigation.is_target_reachable():
			# Check if player can see this cover point
			var is_visible_to_player = player_can_see_point(point_pos, player)
			
			# Calculate a score for this cover point
			var score = evaluate_cover_point(point, player, is_visible_to_player)
			
			valid_cover_points.append({
				"node": point,
				"position": point_pos,
				"score": score,
				"visible_to_player": is_visible_to_player
			})
	
	if valid_cover_points.is_empty():
		if debug_mode:
			print("TakeCoverState: No valid cover points found. Retreating.")
		strategic_retreat()
		return
	
	# Sort by score (highest first)
	valid_cover_points.sort_custom(Callable(self, "sort_by_score"))
	
	# Choose the best cover point
	var best_cover = valid_cover_points[0]
	cover_position = best_cover.position
	current_cover_point = best_cover.node
	
	if debug_mode:
		print("TakeCoverState: Moving to cover at ", cover_position, 
			  " with score ", best_cover.score, 
			  " (visible to player: ", best_cover.visible_to_player, ")")
	
	navigation.target_position = cover_position
	cover_found = true

# Check if the player has direct line of sight to a point
func player_can_see_point(point_pos: Vector3, player) -> bool:
	var space_state = owner_node.get_world_3d().direct_space_state
	var player_pos = player.global_transform.origin
	
	# Adjust heights for better line of sight check
	var from_pos = player_pos + Vector3(0, los_check_height, 0)  # Eye level
	var to_pos = point_pos + Vector3(0, los_check_height, 0)
	
	# Create ray cast query
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [player, owner_node]  # Exclude player and self
	
	# Perform ray cast
	var result = space_state.intersect_ray(query)
	
	# If result is empty, there's nothing blocking the view
	# If the first hit is the cover point itself, it's visible
	return result.is_empty()

# Evaluate how good a cover point is (higher score is better)
func evaluate_cover_point(cover_point, player, visible_to_player: bool) -> float:
	var score = 0.0
	var state_machine = self.state_machine as EnemyStateMachine
	var cover_pos = cover_point.global_transform.origin
	var player_pos = player.global_transform.origin
	var enemy_pos = owner_node.global_transform.origin
	
	# Base score for all covers
	score += 1.0
	
	# MAJOR BONUS: If point is not visible to player, this is ideal cover
	if not visible_to_player:
		score += 5.0  # Heavy bonus for not being visible
	else:
		# If visible, check if it will provide cover once reached
		var will_provide_cover = check_if_provides_cover(cover_point, player)
		if will_provide_cover:
			score += 2.0  # Still good if it will provide cover once reached
	
	# Distance from current position (closer is better for quick access)
	var dist_to_enemy = enemy_pos.distance_to(cover_pos)
	var dist_score = 1.0 - clamp(dist_to_enemy / max_cover_search_distance, 0, 1)
	score += dist_score * 1.5
	
	# Distance from player (good cover shouldn't be too close to player)
	var dist_to_player = player_pos.distance_to(cover_pos)
	var optimal_dist = state_machine.detection_radius * 0.6
	
	# Penalize cover that's too close to the player
	if dist_to_player < optimal_dist * 0.5:
		score -= 2.0
	
	# Prefer cover that's at a medium distance
	var dist_factor = 1.0 - clamp(abs(dist_to_player - optimal_dist) / optimal_dist, 0, 1)
	score += dist_factor * 1.0
	
	# Direction check - is cover point facing toward player?
	# This assumes your cover points are oriented so the -Z axis faces the direction of cover
	var cover_forward = -cover_point.global_transform.basis.z.normalized()
	var direction_to_player = (player_pos - cover_pos).normalized()
	var dot = cover_forward.dot(direction_to_player)
	
	# Higher dot product means cover is facing toward player (good)
	score += dot * 1.0
	
	return max(0.0, score)  # Ensure score is not negative

# Check if a cover point will actually provide cover once reached
func check_if_provides_cover(cover_point, player) -> bool:
	var space_state = owner_node.get_world_3d().direct_space_state
	var cover_pos = cover_point.global_transform.origin
	var player_pos = player.global_transform.origin
	
	# Get cover direction (assuming -Z of marker points toward cover direction)
	var cover_direction = -cover_point.global_transform.basis.z.normalized()
	
	# Position slightly behind the cover point in the cover direction
	var cover_position = cover_pos + cover_direction * 1.0
	
	# Check if there's something blocking line of sight from this position
	var query = PhysicsRayQueryParameters3D.create(
		cover_position + Vector3(0, los_check_height, 0),
		player_pos + Vector3(0, los_check_height, 0)
	)
	query.exclude = [player, owner_node]
	
	var result = space_state.intersect_ray(query)
	
	# If something is blocking the ray, this position provides cover
	return not result.is_empty()

# Fall back to strategic retreat when no cover found
func strategic_retreat() -> void:
	var state_machine = self.state_machine as EnemyStateMachine
	var player = state_machine.player
	
	if not player:
		return
	
	# Get direction from player to enemy and move that way
	var retreat_dir = (owner_node.global_transform.origin - player.global_transform.origin)
	
	# Check if direction is valid
	if retreat_dir.length_squared() < 0.001:
		retreat_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	
	retreat_dir = retreat_dir.normalized()
	var retreat_distance = 15.0
	
	# Find a point at some distance that's on the navigation mesh
	var target_pos = owner_node.global_transform.origin + retreat_dir * retreat_distance
	
	var navigation_server = NavigationServer3D
	var map = navigation.get_navigation_map()
	var adjusted_pos = navigation_server.map_get_closest_point(map, target_pos)
	
	cover_position = adjusted_pos
	
	if debug_mode:
		print("TakeCoverState: Strategic retreat to ", cover_position)
	
	navigation.target_position = cover_position
	cover_found = true

# Helper to sort cover points by score (descending)
func sort_by_score(a, b):
	return a.score > b.score

func check_transitions() -> String:
	var state_machine = self.state_machine as EnemyStateMachine
		
	# If player is out of detection range, go back to wandering
		
	if state_machine.distance_to_player() <= state_machine.detection_radius and state_machine.can_see_player():
		if debug_mode:
			print("TakeCoverState: Player approaching too close, forced to attack")
		return "Attack"
	# Don't allow transitions until minimum time has passed
	if time_in_cover < minimum_cover_time:
		return ""
	# If we've been hiding long enough, switch to attack
	if hide_timer >= hide_duration:
		if debug_mode:
			hide_timer = 0
			print("TakeCoverState: Hide duration complete, returning to Attack")
		return "Attack"
	if state_machine.distance_to_player() > state_machine.detection_radius:
		if debug_mode:
			print("TakeCoverState: Player out of range, returning to Wander")
		return "Wander"
	
	return ""

func exit() -> void:
	if debug_mode:
		print("Exiting Take Cover State")
	
	# Reset cover status
	cover_found = false
	current_cover_point = null
	
	# Stop any movement
	if owner_node is CharacterBody3D:
		owner_node.velocity = Vector3.ZERO
