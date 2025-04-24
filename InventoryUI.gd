class_name InventoryUI
extends Control

# Reference to the inventory this UI displays
@export var player_inventory: Inventory = null

# Container for slot UI elements
#@onready var grid_container: GridContainer = $GridContainer
@onready var grid_container: GridContainer = $Panel/GridContainer

# Whether inventory is currently visible
var is_visible: bool = false

# Preload the slot scene
@export var slot_scene: PackedScene

# Selected slot index (-1 means nothing selected)
var selected_slot: int = -1

func _ready() -> void:
	# Hide inventory at startup
	visible = false
	is_visible = false
	
	# Connect to inventory if available
	if player_inventory:
		player_inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Create the inventory slots
	create_inventory_slots()

func _input(event: InputEvent) -> void:
	# Toggle inventory visibility with the "I" key
	if event.is_action_pressed("toggle_inventory"):  # Define this input action in project settings
		toggle_inventory()

func toggle_inventory() -> void:
	# Show/hide the inventory
	is_visible = !is_visible
	visible = is_visible
	
	# Pause the game when inventory is open (optional)
	if is_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Show mouse cursor
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hide cursor for FPS control

func create_inventory_slots() -> void:
	# Create UI slots based on inventory size
	
	if not player_inventory or not slot_scene:
		print("shit aint workin")
		return
	
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create new slots
	for i in range(player_inventory.inventory_size):
		var slot_instance = slot_scene.instantiate()
		grid_container.add_child(slot_instance)
		
		# Initialize the slot
		slot_instance.initialize(player_inventory, i)
		
		# Connect to slot clicked signal
		slot_instance.slot_clicked.connect(_on_slot_clicked)

func _on_inventory_changed() -> void:
	# Update the inventory display when inventory changes
	# Most updates happen automatically in each slot, but you can add global UI updates here
	update_selection_display()

func _on_slot_clicked(index: int) -> void:
	# Handle slot clicked
	if selected_slot == index:
		# Clicked the same slot twice, use/equip the item
		use_selected_item()
	else:
		# First click selects the slot
		selected_slot = index
		update_selection_display()

func update_selection_display() -> void:
	# Update visual indication of selected slot
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		
		# You would add custom highlighting here
		if i == selected_slot:
			slot.modulate = Color(1.2, 1.2, 0.8)  # Highlight selected slot
		else:
			slot.modulate = Color(1, 1, 1)  # Normal color

func use_selected_item() -> void:
	# Use or equip the selected item
	if selected_slot < 0 or not player_inventory:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Try to use the item
	if not player_inventory.use_item(selected_slot, player):
		# If can't use, try to equip instead
		player_inventory.equip_item(selected_slot)
	
	# Reset selection after using
	selected_slot = -1
	update_selection_display()
