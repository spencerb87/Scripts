#@tool

extends Node3D

@export var WEAPON_TYPE : Weapons

var can_shoot : bool = true
var last_shot_time : float = 0.0
var current_ammo : int


@export var sway_noise : NoiseTexture2D
@export var sway_speed : float = 1.2
@export var reset : bool = false:
	set(value):
		reset = value
		if Engine.is_editor_hint():
			load_weapon()

@onready var weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var weapon_shadow : MeshInstance3D = %ShadowMesh
@onready var hs_sound: AudioStreamPlayer = $"../../../../Sound effects/AudioStreamPlayer"
@onready var player_camera: Camera3D = %PlayerCamera
@onready var crosshair: TextureRect = $"../../../../Crosshair"

var fire_audio_player: AudioStreamPlayer3D
var reload_audio_player: AudioStreamPlayer3D
var mouse_movement : Vector2
var random_sway_x
var random_sway_y
var random_sway_amount : float
var time : float = 0.0
var idle_sway_adjustment
var idle_sway_rotation_strength

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_weapon()
	current_ammo = WEAPON_TYPE.ammo_count
	fire_audio_player = AudioStreamPlayer3D.new()
	reload_audio_player = AudioStreamPlayer3D.new()
	
	add_child(fire_audio_player)
	add_child(reload_audio_player)
	
func _input(event):
	if event is InputEventMouseMotion:
		mouse_movement = event.relative

func load_weapon():
	weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	weapon_shadow.visible = WEAPON_TYPE.shadow
	weapon_mesh.scale = WEAPON_TYPE.scale
	idle_sway_adjustment = WEAPON_TYPE.idle_sway_adjustment
	idle_sway_rotation_strength = WEAPON_TYPE.idle_sway_rotation_strength
	random_sway_amount = WEAPON_TYPE.random_sway_amount
	
func _process(delta):
	if Input.is_action_just_pressed("shoot") and can_shoot and !WEAPON_TYPE.is_automatic:
		attempt_shoot()
	if Input.is_action_pressed("shoot") and can_shoot and WEAPON_TYPE.is_automatic:
		attempt_shoot()
	if Input.is_action_just_pressed("reload"):
		reload()
		
	
func attempt_shoot():
	if current_ammo > 0 and can_shoot:
		shoot()
		current_ammo -= 1
		can_shoot = false
		await get_tree().create_timer(WEAPON_TYPE.fire_rate).timeout
		can_shoot = true
		


func shoot():
	print("Firing Weapon! Damage:", WEAPON_TYPE.damage)
	
	if WEAPON_TYPE.fire_sound:
		fire_audio_player.stream = WEAPON_TYPE.fire_sound
		fire_audio_player.play()
	
	#get camera
	var camera : Camera3D = %PlayerCamera
	
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	
	var start_position = camera.global_position #weapons position
	var direction = -camera.global_transform.basis.z #supposedly forward direction
	var max_distance = 10000 #max ray cast distance
	var end_position = ray_origin + ray_direction * max_distance
	
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED
	material.vertex_color_use_as_albedo = true
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	get_tree().get_root().add_child(mesh_instance)
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(ray_origin)
	immediate_mesh.surface_add_vertex(end_position)
	immediate_mesh.surface_end()
	
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, end_position)

	query.collide_with_areas = true 
	query.collide_with_bodies = true
	query.collision_mask = 0b00000010  # Only hit hurtboxes (Layer 2)
	
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_position = result.position
		var hit_normal = result.normal
		var hit_collider = result.collider
		
		print("Hit:", hit_collider.name, " at", hit_position)
		
		#apply damage if they have health script
		if hit_collider.has_method("apply_damage"):
			hit_collider.apply_damage(WEAPON_TYPE.damage)
			
			if hit_collider.name == "Head":
				hs_sound.play()
			
			
		spawn_bullet_impact(hit_position, hit_normal)
		
func spawn_bullet_impact(hit_position: Vector3, hit_normal: Vector3):
	#placeholder until i make bullet effect
	print("Spawn impact effect at:", hit_position)
	
func reload():
	current_ammo = WEAPON_TYPE.max_ammo
	print("Reloaded")
	if WEAPON_TYPE.reload_sound:
		reload_audio_player.stream = WEAPON_TYPE.reload_sound
		reload_audio_player.play()

func sway_weapon(delta):
	#get random sway value from 2d noise
	#var sway_random : float = get_sway_noise()
	var sway_random = sin(4)
	var sway_random_adjusted : float = sway_random * idle_sway_adjustment
	
	#create time with delta and set two sine values for x and y sway movement
	time += delta * (sway_speed + sway_random)
	random_sway_x = sin(time * 1.5 + sway_random_adjusted) / random_sway_amount
	random_sway_y = sin(time - sway_random_adjusted) / random_sway_amount
	
	#clamp mouse movement
	mouse_movement = mouse_movement.clamp(WEAPON_TYPE.sway_min, WEAPON_TYPE.sway_max)
	#lerp weapon position based on mouse movement
	position.x = lerp(position.x, WEAPON_TYPE.position.x - (mouse_movement.x * WEAPON_TYPE.sway_amount_position + random_sway_x) * delta, WEAPON_TYPE.sway_speed_position)
	position.y = lerp(position.y, WEAPON_TYPE.position.y - (mouse_movement.y * WEAPON_TYPE.sway_amount_position + random_sway_y) * delta, WEAPON_TYPE.sway_speed_position)
	#lerp rotation based on mouse movement
	rotation_degrees.x = lerp(rotation_degrees.x, WEAPON_TYPE.rotation.x + (mouse_movement.x * WEAPON_TYPE.sway_amount_rotation + (random_sway_y * idle_sway_rotation_strength)) * delta, WEAPON_TYPE.sway_speed_rotation)
	rotation_degrees.y = lerp(rotation_degrees.y, WEAPON_TYPE.rotation.y + (mouse_movement.y * WEAPON_TYPE.sway_amount_rotation + (random_sway_x * idle_sway_rotation_strength)) * delta, WEAPON_TYPE.sway_speed_rotation)
	
#func get_sway_noise() -> float:
	#var player_position : Vector3 = Vector3(0,0,0)
	#only access global variable when in game to avoid constant errors
	#if not Engine.is_editor_hint():
		#player_position = global_position
		
	#var noise_location : float = sway_noise.noise.get_noise_2d(player_position.x, player_position.y)
	#return noise_location
	
	
	
func _physics_process(delta: float) -> void:
	sway_weapon(delta)
