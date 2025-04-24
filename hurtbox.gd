extends Area3D

@export var damage_multiplier: float = 1.0
@onready var enemy = get_parent().get_parent()  # Assumes hurtboxes are children of the enemy

func apply_damage(base_damage: float):
	print("Hurtbox hit! Applying damage:", base_damage * damage_multiplier)
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(base_damage * damage_multiplier)
		
