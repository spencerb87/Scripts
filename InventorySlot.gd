class_name InventorySlot
extends Panel

# Reference to the inventory this slot belongs to
var inventory: Inventory = null
var slot_index: int = -1

# UI elements
@onready var icon_rect: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel

# Signal when slot is clicked
signal slot_clicked(index)

func _ready() -> void:
	# Connect to mouse input
	gui_input.connect(_on_gui_input)
	
	# Hide quantity label by default
	quantity_label.visible = false

func initialize(p_inventory: Inventory, p_slot_index: int) -> void:
	# Set up the slot with reference to inventory and its index
	inventory = p_inventory
	slot_index = p_slot_index
	
	# Connect to inventory changed signal
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	update_display()

func update_display() -> void:
	# Update the visual representation of this slot
	
	if not inventory:
		return
	
	var item = inventory.get_item(slot_index)
	var quantity = inventory.get_quantity(slot_index)
	
	if item:
		# Slot has an item, show it
		icon_rect.texture = item.icon
		icon_rect.visible = true
		
		# Show quantity for stackable items
		if item.stackable and quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		# Slot is empty
		icon_rect.texture = null
		icon_rect.visible = false
		quantity_label.visible = false

func _on_inventory_changed() -> void:
	# Update the slot when inventory changes
	update_display()

func _on_gui_input(event: InputEvent) -> void:
	# Handle mouse input on this slot
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Left click - emits signal that could be used for selecting or using
			emit_signal("slot_clicked", slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click - example: directly use the item
			if inventory:
				# Placeholder for player reference - you would pass the actual player
				var player = get_tree().get_first_node_in_group("player") 
				inventory.use_item(slot_index, player)
