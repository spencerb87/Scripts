extends CharacterBody3D

var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3
var wishdir : Vector3 = Vector3.ZERO
var move_dir : Vector3 = Vector3.ZERO

@onready var inventory: Inventory = $Inventory
@onready var interactor: RayCast3D = $CameraController/PlayerCamera/Interactor

@export var MOUSE_SENSITIVITY : float = 0.25
@export var TILT_LOWER_LIMIT := deg_to_rad(-90)
@export var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER : Camera3D
@export var ACCELERATION = 10
@export var DECELERATION = 10
@export var g_speed = 10.0
@export var air_speed = 10.0
@export var MAX_SPEED = 10
@export var jump_strength = 7
@export var gravity : float = 30
@export var air_acceleration = 3  # Air acceleration factor
@export var air_friction = 0.1  # Subtle air friction, adjustable in editor


func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
		
	#if Input.is_action_just_pressed("throwable"):
		#throw_selected_item()
		
func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		
func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	# Reset transformations
	transform.basis = Basis()
	CAMERA_CONTROLLER.transform.basis = Basis()
	
	# Apply rotations in the correct order
	rotate_object_local(Vector3(0, 1, 0), _mouse_rotation.y)  # Y rotation (looking left/right)
	CAMERA_CONTROLLER.rotate_object_local(Vector3(1, 0, 0), _mouse_rotation.x)  # X rotation (looking up/down)
	
	# Apply clamping to pitch
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	
	#_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	#_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)
	
	#CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	#CAMERA_CONTROLLER.rotation.z = 0.0
	
	#global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
	
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interactor.enabled = true
	
	if inventory:
		inventory.initialize_inventory()

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_strength
	
	#handle interaction
	if Input.is_action_just_pressed("interact"):
		interact()

	# Get input direction
	var input_dir := Input.get_vector("left", "right", "up", "down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Calculate move_dir (actual movement direction based on horizontal velocity)
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	var forward = global_transform.basis.z
	var right = global_transform.basis.x
	var wishdir = (forward * input_dir.y + right * input_dir.x).normalized()
	#var add_speed = 0
	#var current_speed = velocity.dot(wishdir)
	#print("current speed: ", current_speed)
	#var add_speed = (MAX_SPEED - current_speed) * delta
	
	
	
	#if horizontal_velocity.length() > 0.01:  # Small threshold to avoid jitter when nearly stopped
		#move_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		#add_speed = clamp(MAX_SPEED - current_speed, 0, 1)
		#add_speed = MAX_SPEED - current_speed * delta
		#print("add speed: ", add_speed)
	#else:
		#move_dir = Vector3.ZERO
		#add_speed = 0.1
	#print("velocity: ", horizontal_velocity.length())
		
	if is_on_floor():
		if wishdir.length() > 0:
			velocity.x = lerp(velocity.x, wishdir.x * g_speed, ACCELERATION * delta)
			velocity.z = lerp(velocity.z, wishdir.z * g_speed, ACCELERATION * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
			velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
	else:
			
		if wishdir.length() > 0:
			var current_velocity = Vector3(velocity.x, 0, velocity.z)
			var current_speed = current_velocity.length()
			# Apply air acceleration to current velocity
			#velocity.x += lerp(velocity.x, wishdir.x * air_speed * add_speed, add_speed)
			#velocity.z += lerp(velocity.z, wishdir.z * air_speed * add_speed, add_speed)
			#velocity.x += add_speed * wishdir.x * 0.25
			#velocity.z += add_speed * wishdir.z * 0.25
			#velocity.x += lerp(wishdir.x * add_speed, 0.01, delta)
			#velocity.z += lerp(wishdir.z * add_speed, 0.01, delta)
			
			# Only adjust direction if we have some speed
			if current_speed > 0.1:
				# Get normalized current velocity direction
				var current_dir = current_velocity.normalized()
				print("Current direction (normalized): ", current_dir)
				
				# Calculate dot product between current direction and wishdir
				var dot_product = current_dir.dot(wishdir)
				print("Dot product (current_dir · wishdir): ", dot_product)
				
				# Apply acceleration if moving perpendicular to current velocity
				# Maximum acceleration when dot product is 0 (perpendicular)
				# No acceleration when dot product is 1 (same direction)
				var min_control = 0.25 # Adjust this value (0.0 to 1.0) to set minimum control
				var acceleration_scale = min_control + (1.0 - min_control) * (1.0 - abs(dot_product))
				print("Acceleration scale (1.0 - abs(dot)): ", acceleration_scale)
				
				# Apply air acceleration - stronger when perpendicular to velocity
				var acceleration_factor = air_acceleration * delta * acceleration_scale
				print("Acceleration factor: ", acceleration_scale)
				
				# Add acceleration in the wished direction
				velocity.x += wishdir.x * acceleration_factor * air_speed
				velocity.z += wishdir.z * acceleration_factor * air_speed
			else:
				# Allow initial acceleration from standstill
				velocity.x += wishdir.x * air_acceleration * delta * air_speed
				velocity.z += wishdir.z * air_acceleration * delta * air_speed
			
			velocity.x *= (1.0 - (air_friction * delta))
			velocity.z *= (1.0 - (air_friction * delta))
		#else:
			#velocity.x = lerp(velocity.x, 0.0, air_acceleration * delta * 0.1)
			#velocity.z = lerp(velocity.z, 0.0, air_acceleration * delta * 0.1)
			
	# Limit horizontal speed (X and Z only)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	#print ("horizontal_speed: ", horizontal_speed)
	if horizontal_speed > MAX_SPEED and is_on_floor():
		var speed_scale = MAX_SPEED / horizontal_speed
		velocity.x *= speed_scale
		velocity.z *= speed_scale
	
	
	move_and_slide()

func interact():
	if interactor.is_colliding():
		var collider = interactor.get_collider()
		
		# Check if we're looking at an interactable object
		if collider.has_method("interact"):
			print("collider has method")
			collider.interact(self)
		else:
			print("no interact method")
			
func pick_up_item(item: Item, quantity: int = 1) -> bool:
	if not inventory:
		push_error("No inventory found on player!")
		return false
		
	var result = inventory.add_item(item, quantity)
	if result.success:
		return true
	else:
		return false
		
#func throw_selected_item():
	#var throwable_to_use = null
	#var slot_to_use = -1
	#
	#if inventory.equipment_data[5]["item"] != null:
		#throwable_to_use = inventory.equipment_data[5]["item"]
		#slot_to_use = 5
		#
	#elif inventory.equipment_data[6]["item"] != null:
		#throwable_to_use = inventory.equipment_data[6]["item"]
		#slot_to_use = 6
		#
	#if throwable_to_use == null:
		#return
		#
	#var grenade_scene = load(throwable_to_use.item_scene_path)
	#var grenade_instance = grenade_scene.instantiate()
	#
	#get_tree().current_scene.add_child(grenade_instance)
	#
	#var throw_position = global_position + global_transform.basis.z * -1.0
	#throw_position.y += 1.5
	#grenade_instance.global_position = throw_position
	#
	#grenade_instance.setup_grenade(throwable_to_use)
	#var throw_direction = global_transform.basis.z * -1.0
	#grenade_instance.throw_grenade(throw_direction, throwable_to_use.throw_force)
	#
	#var slot_data = inventory.equipment_data[slot_to_use]
	#slot_data["quantity"] -= 1
	#if slot_data["quantity"] <= 0:
		#slot_data["item"] = null
		#slot_data["quantity"] = 0
	#
	#inventory.emit_signal("item_changed", slot_to_use, slot_data["item"], slot_data["quantity"])
