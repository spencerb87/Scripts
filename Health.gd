extends Node3D

@export var max_health : int = 100
var current_health : int

var enemy

func _ready():
	current_health = max_health
	enemy = self #assumes parent is enemy
	
func take_damage(amount: int):
	current_health -= amount
	print(name, " took ", amount, " damage! Current health: ", current_health)
	
	if current_health <= 0:
		print("Health is zero, calling die()!")
		die()
		
func die():
	print(enemy.name, " has died!")
	if enemy:
		enemy.queue_free() #removes enemy?
