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
		
	
