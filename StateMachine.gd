# State Machine Base Class
class_name StateMachine
extends Node3D

signal state_changed(previous_state, new_state)

# Current active state
var current_state: State = null
# Dictionary to store all states
var states: Dictionary = {}

# The owner of this state machine (usually the parent node)
var owner_node: Node = null

func _ready() -> void:
	owner_node = get_parent()
	_register_states()
	
	# Initialize with the first state if states exist
	if not states.is_empty():
		var initial_state = states.values()[0]
		change_state(initial_state.name)

# Override this in child classes to register all states
func _register_states() -> void:
	pass

# Add a state to the state machine
func add_state(state: State) -> void:
	state.state_machine = self
	state.owner_node = owner_node
	states[state.name] = state

# Change to a different state
func change_state(state_name: String) -> void:
	if current_state and state_name == current_state.name:
		return
		
	if not states.has(state_name):
		push_error("State '" + state_name + "' does not exist in the state machine.")
		return
	
	var previous_state = current_state
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_name]
	current_state.enter()
	
	emit_signal("state_changed", previous_state, current_state)

# Process the current state
func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
