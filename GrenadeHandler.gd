# GrenadeHandler.gd
extends RigidBody3D

var throwable_resource: Throwable
var is_thrown: bool = false
var current_bounces: int = 0

@onready var explosion_area: Area3D = $Area3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	# Connect collision detection
	body_entered.connect(_on_body_entered)

func setup_grenade(throwable: Throwable):
	throwable_resource = throwable
	
	## Set up the mesh if available
	#if throwable.world_mesh and mesh_instance:
		#mesh_instance.mesh = throwable.world_mesh
	
	# Set up explosion area size
	if explosion_area:
		var explosion_collision = explosion_area.get_child(0) as CollisionShape3D
		if explosion_collision and explosion_collision.shape is SphereShape3D:
			explosion_collision.shape.radius = throwable.explosion_radius

func throw_grenade(direction: Vector3, force: float):
	if not throwable_resource:
		return
		
	is_thrown = true
	
	# Apply throwing force
	linear_velocity = direction * force
	
	# Start the fuse timer
	await get_tree().create_timer(throwable_resource.fuse_time).timeout
	explode()

func _on_body_entered(body):
	if not is_thrown:
		return
		
	# Count bounces
	current_bounces += 1
	
	# Explode if we've bounced enough times
	if current_bounces >= throwable_resource.bounce_count:
		explode()

func explode():
	print("BOOM! Explosion at position: ", global_position)
	
	# Find all bodies in explosion radius
	var bodies_in_range = explosion_area.get_overlapping_bodies()
	
	for body in bodies_in_range:
		# Check if it's something that can take damage
		if body.has_method("take_damage"):
			body.take_damage(throwable_resource.explosion_damage)
			print("Damaged: ", body.name)
	
	# Here you would spawn explosion effects, particles, etc.
	
	# Remove the grenade
	queue_free()
