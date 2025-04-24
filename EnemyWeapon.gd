extends Node3D

#@export var WEAPON_TYPE : Weapons
var WEAPON_TYPE : Weapons
var owner_node = null
var can_shoot : bool = true
var last_shot_time : float = 0.0
var current_ammo : int


@onready var weapon_mesh: MeshInstance3D = $WeaponMesh
@onready var weapon_shadow: MeshInstance3D = $ShadowMesh

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
	owner_node = get_parent().get_parent()
	WEAPON_TYPE = owner_node.get("WEAPON_TYPE")
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
	
	
	
func _physics_process(delta: float) -> void:
	pass
