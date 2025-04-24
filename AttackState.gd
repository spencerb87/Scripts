# Attack State
class_name AttackState
extends State

var WEAPON_TYPE : Weapons
var enemy_sounds: EnemySounds
var attack_speed: float = 5.0
var attack_cooldown: float = 10
var time_since_last_attack: float = 0.0
var navigation: NavigationAgent3D = null
var animation_player: AnimationPlayer = null
var audio_player: AudioStreamPlayer3D = null
var consecutive_hits_taken: int = 0  # Track hits to decide when to take cover

func enter() -> void:
	print("Entering Attack State")
	navigation = owner_node.get_node("NavigationAgent3D")
	animation_player = owner_node.get_node_or_null("AnimationPlayer")
	audio_player = owner_node.get_node_or_null("AudioStreamPlayer3D")
	enemy_sounds = owner_node.get("enemy_sounds")
	WEAPON_TYPE = owner_node.get("WEAPON_TYPE")
	attack_cooldown = WEAPON_TYPE.fire_rate
	time_since_last_attack = attack_cooldown # Allow immediate attack

func physics_update(delta: float) -> void:
	var state_machine = self.state_machine as EnemyStateMachine
	var player = state_machine.player
	
	if not player:
		return
	
	# Update attack cooldown
	time_since_last_attack += delta
	
	# Set the player position as the navigation target
	if navigation:
		navigation.target_position = player.global_transform.origin
		
		# Get next point in path
		var next_location = navigation.get_next_path_position()
		
		# Calculate direction
		var direction = (next_location - owner_node.global_transform.origin).normalized()
		
		# Check if in attack range
		var distance_to_player = state_machine.distance_to_player()
		
		if distance_to_player <= state_machine.attack_range:
			# In attack range, stop moving and perform attack
			if owner_node is CharacterBody3D:
				owner_node.velocity = Vector3.ZERO
			
			# Face the player
			owner_node.look_at(player.global_transform.origin, Vector3.UP)
			
			# Attack if cooldown has elapsed
			if time_since_last_attack >= attack_cooldown:
				perform_attack()
				time_since_last_attack = 0.0
		else:
			# Not in attack range, move toward player
			if owner_node is CharacterBody3D:
				owner_node.velocity = direction * attack_speed
				owner_node.move_and_slide()
			
			# Rotate towards movement direction
			if direction != Vector3.ZERO:
				var look_direction = direction
				look_direction.y = 0.0
				if look_direction != Vector3.ZERO:
					owner_node.look_at(owner_node.global_transform.origin + look_direction, Vector3.UP)

func perform_attack() -> void:
	print("Enemy attacking!")
	if WEAPON_TYPE != null and WEAPON_TYPE.fire_sound != null and audio_player != null:
		audio_player.stream = WEAPON_TYPE.fire_sound
		audio_player.play()
		print("it played correctly")
	elif audio_player != null:
		audio_player.play()
	else:
		print("No sound system")
		
	# Play attack animation if available
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Implement damage logic here
	# For example, cast a ray forward to check for player hit
	var state_machine = self.state_machine as EnemyStateMachine
	var player = state_machine.player
	
	# Simple distance-based hit check
	if state_machine.distance_to_player() <= state_machine.attack_range:
		# Apply damage to player
		if player.has_method("take_damage"):
			player.take_damage(10) # 10 damage points

# Called when enemy takes damage - can be connected to enemy's take_damage signal
func on_take_damage(amount: int) -> void:
	consecutive_hits_taken += 1
	
	# If we've taken multiple hits, consider taking cover
	if consecutive_hits_taken >= 2:
		# This will be checked in check_transitions
		pass

func check_transitions() -> String:
	var state_machine = self.state_machine as EnemyStateMachine
	
	if state_machine.distance_to_player() <= state_machine.detection_radius and state_machine.can_see_player():
		return ""
	
	# Check if player is out of detection range or not visible
	if state_machine.distance_to_player() > state_machine.detection_radius or not state_machine.can_see_player():
		consecutive_hits_taken = 0  # Reset counter
		return "Wander"
	
	# Take cover if health is low or we've taken multiple consecutive hits
	if state_machine.is_health_low() or consecutive_hits_taken >= 2:
		consecutive_hits_taken = 0  # Reset counter
		return "TakeCover"
	
	return ""
