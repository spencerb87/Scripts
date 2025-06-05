class_name WeaponHandler
extends Node3D

# This script handles weapon behavior like shooting, reloading, and ammo management

# Reference to our weapon resource (drag a weapon resource here in the inspector)
@export var weapon_resource: Weapons

# Node references - these will be set up in the scene
@onready var weapon_mesh: MeshInstance3D = $WeaponMesh
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var inventory_ui: InventoryUI = $"../../../../InventoryUI"
@onready var inventory: Inventory = $"../../../../Inventory"
@onready var weapon_rig: Node3D = $".."
@onready var player: CharacterBody3D = $"../../../.."
@onready var grenadespawn: Marker3D = $"../grenadespawn"


# Internal variables to track weapon state
var current_ammo: int
var can_shoot: bool = true
var is_reloading: bool = false

func _ready():
	# This runs when the scene starts
	if weapon_resource:
		setup_weapon()

func setup_weapon():
	# Set up the weapon based on our weapon resource
	print("Setting up weapon: " + weapon_resource.item_name)
	
	# Apply the weapon's mesh if we have one
	if weapon_resource.mesh and weapon_mesh:
		weapon_mesh.mesh = weapon_resource.mesh
		print("Mesh applied successfully")
	else:
		print("Warning: No mesh found or MeshInstance3D not assigned")
	
	# Set the current ammo to match the weapon's starting ammo
	current_ammo = weapon_resource.ammo_count
	
	# Apply the weapon's mesh if we have one
	if weapon_resource.mesh and weapon_mesh:
		weapon_mesh.mesh = weapon_resource.mesh
	
	# Position the weapon using the resource's position settings
	position = weapon_resource.position
	rotation_degrees = weapon_resource.rotation
	scale = weapon_resource.scale

func _process(delta: float) -> void:
	#simple logic to shoot full auto is weapon marked is_automatic
	if Input.is_action_pressed("shoot") and weapon_resource.is_automatic and !inventory_ui.visible:  # You'll need to define "shoot" in Input Map
		shoot()

func _input(event):
	# Handle player input for shooting and reloading
	if not weapon_resource:
		return
	
	if event.is_action_pressed("hotbar1"):
		equip_from_slot(0)
	elif event.is_action_pressed("hotbar2"):
		equip_from_slot(1)
	
	if Input.is_action_just_pressed("throwable"):
		throw_grenade()
	
	
	# Stop shooting when left mouse button is released (for automatic weapons)
	if Input.is_action_just_pressed("shoot") and !weapon_resource.is_automatic and !inventory_ui.visible:  # You'll need to define "shoot" in Input Map
		shoot()
	
	# Reload when R key is pressed
	if Input.is_action_just_pressed("reload"):  # You'll need to define "reload" in Input Map
		reload()

func shoot():
	# Check if we can shoot
	if not can_shoot or is_reloading or current_ammo <= 0 :
		return
	
	print("Shooting! Ammo left: " + str(current_ammo - 1))
	
	# Reduce ammo count
	current_ammo -= 1
	
	# Play shooting sound
	if weapon_resource.fire_sound and audio_player:
		audio_player.stream = weapon_resource.fire_sound
		audio_player.play()
	
	# Prevent shooting too fast (fire rate control)
	can_shoot = false
	
	# Wait for fire rate delay, then allow shooting again
	await get_tree().create_timer(weapon_resource.fire_rate).timeout
	can_shoot = true
	
	# Here you would add your bullet spawning, muzzle flash, etc.
	# For now, we're just handling the basic shooting mechanics

func reload():
	# Check if we need to reload
	if is_reloading or current_ammo >= weapon_resource.max_ammo:
		return
	
	print("Reloading...")
	is_reloading = true
	
	# Play reload sound
	if weapon_resource.reload_sound and audio_player:
		audio_player.stream = weapon_resource.reload_sound
		audio_player.play()
	
	# Wait for reload time (using fire_rate as reload time for simplicity)
	await get_tree().create_timer(2.0).timeout  # 2 second reload time
	
	# Refill ammo
	current_ammo = weapon_resource.max_ammo
	is_reloading = false
	
	print("Reload complete! Ammo: " + str(current_ammo))

# Helper function to get current ammo (useful for UI)
func get_current_ammo() -> int:
	return current_ammo

# Helper function to get max ammo (useful for UI)
func get_max_ammo() -> int:
	if weapon_resource:
		return weapon_resource.max_ammo
	return 0

func equip_from_slot(slot_index: int):
	if inventory.equipment_data.has(slot_index):
		var slot_data = inventory.equipment_data[slot_index]
		
		if slot_data["item"] != null and slot_data["item"] is Weapons:
			weapon_resource = slot_data["item"]
			setup_weapon()
			print("yippeeee you changed your weapon")
		
	
func throw_grenade():
	var throwable_to_use = null
	var slot_to_use = -1
	
	#only array slots 5 and 6 allow throwables
	if inventory.equipment_data[5]["item"] != null:
		throwable_to_use = inventory.equipment_data[5]["item"]
		print("slot 5 has item")
		slot_to_use = 5
	elif inventory.equipment_data[6]["item"] != null:
		throwable_to_use = inventory.equipment_data[6]["item"]
		print("slot 6 has item")
		slot_to_use = 6
	else:
		return
		
	spawn_and_throw_grenade(throwable_to_use, slot_to_use)
		
		
func spawn_and_throw_grenade(throwable: Throwable, slot_index: int):
	var grenade_scene = load(throwable.item_scene_path)
	var grenade_instance = grenade_scene.instantiate()
	
	get_tree().current_scene.add_child(grenade_instance)
	
	var throw_pos = grenadespawn.global_position
	grenade_instance.global_position = throw_pos
	
	var throw_direction = grenadespawn.global_transform.basis.z * -1.0
	grenade_instance.linear_velocity = throw_direction * throwable.throw_force
	
	# adding a lil rando spin to the throwable
	var random_rotation = Vector3(
		randf_range(-10.0, 10.0),  # Random X rotation
		randf_range(-10.0, 10.0),  # Random Y rotation  
		randf_range(-10.0, 10.0)   # Random Z rotation
	)
	grenade_instance.angular_velocity = random_rotation
	
	start_grenade_timer(grenade_instance, throwable)
	remove_throwable_from_slot(slot_index)
	
func start_grenade_timer(grenade: RigidBody3D, throwable: Throwable):
	await get_tree().create_timer(throwable.fuse_time).timeout
	explode_grenade(grenade, throwable)
	
func explode_grenade(grenade: RigidBody3D, throwable: Throwable):
	print("BOOM!")
	# Add explosion logic here
	grenade.queue_free()

func remove_throwable_from_slot(slot_index: int):
	var slot_data = inventory.equipment_data[slot_index]
	slot_data["quantity"] -= 1
	if slot_data["quantity"] <= 0:
		slot_data["item"] = null
		slot_data["quantity"] = 0
	inventory.emit_signal("item_changed", slot_index, slot_data["item"], slot_data["quantity"])
