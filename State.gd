# Base State Class
class_name State
extends Resource

# Name of the state
var name: String = ""
# Reference to the state machine
var state_machine: StateMachine = null
# Reference to the owner node
var owner_node: Node = null

# Called when entering this state
func enter() -> void:
	pass

# Called when exiting this state
func exit() -> void:
	pass

# Called during _physics_process
func physics_update(delta: float) -> void:
	pass

# Called during _process
func update(delta: float) -> void:
	pass

# Called during _input
func handle_input(event: InputEvent) -> void:
	pass

# Check conditions for state transitions
func check_transitions() -> String:
	return ""
