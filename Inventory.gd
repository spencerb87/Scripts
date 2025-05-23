class_name Inventory
extends Node

signal item_changed(slot_index, item, quantity)

@onready var equipment_node: Control = $"../InventoryUI/Equipment"
var equipment_slots = []
var equipment_data = {}

# Drag and drop variables
var dragging = false
var drag_item = null
var drag_quantity = 0
var drag_origin_slot = -1
var drag_icon: TextureRect = null

func _ready() -> void:
	initialize_inventory()
	print(equipment_slots)
	# Create a TextureRect for dragging
	drag_icon = TextureRect.new()
	drag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_icon.visible = false
	drag_icon.expand = true
	drag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(drag_icon)
	
func initialize_inventory():
	equipment_slots = equipment_node.get_children()
	
	for i in range(equipment_slots.size()):
		var slot = equipment_slots[i]
		# Connect signals for the slots
		if not slot.gui_input.is_connected(_on_slot_gui_input.bind(i)):
			slot.gui_input.connect(_on_slot_gui_input.bind(i))
				
		equipment_data[i] = {"item": null, "quantity": 0}

func add_item(item: Item, quantity: int) -> Dictionary:
	# First, check if the item already exists in inventory to stack it
	for slot_index in equipment_data:
		var slot_data = equipment_data[slot_index]
		var slot = equipment_slots[slot_index]
		
		# If this slot has the same item, increase quantity
		if slot_data["item"] == item and item.stackable:
			slot_data["quantity"] += quantity
			emit_signal("item_changed", slot_index, item, slot_data["quantity"])
			return {"success": true, "remaining": 0}
	
	# If we couldn't stack, find the first empty slot
	for slot_index in equipment_data:
		var slot_data = equipment_data[slot_index]
		var slot = equipment_slots[slot_index]
		
		# If this slot is empty, add the item here
		if slot_data["item"] == null and is_slot_compatible(slot, item):
			slot_data["item"] = item
			slot_data["quantity"] = quantity
			emit_signal("item_changed", slot_index, item, quantity)
			return {"success": true, "remaining": 0}
	
	# If we get here, the inventory is full
	return {"success": false, "remaining": quantity}
	
func is_slot_compatible(slot: InventorySlot, item: Item) -> bool:
	match slot.slot_type:
		InventorySlot.SlotType.WEAPON:
			return item.is_weapon
		InventorySlot.SlotType.HELMET:
			return item.is_helmet
		InventorySlot.SlotType.ARMOR:
			return item.is_armor
		InventorySlot.SlotType.MELEE:
			return item.is_melee
		InventorySlot.SlotType.THROWABLE:
			return item.is_throwable
		InventorySlot.SlotType.GENERAL:
			return true
		_:
			return false

# New functions for drag and drop
func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	# Detect left mouse button actions
	if event is InputEventMouseButton:
		var slot_data = equipment_data[slot_index]
		
		# Start dragging on mouse button down
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Only start drag if there's an item in the slot
			if slot_data["item"] != null:
				begin_drag(slot_index)
		
		# Drop item on mouse button release
		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and dragging:
			end_drag(slot_index)

# Process is needed to update the drag icon position
func _process(delta: float) -> void:
	if dragging:
		drag_icon.global_position = get_viewport().get_mouse_position() - drag_icon.size / 2

func begin_drag(slot_index: int) -> void:
	var slot_data = equipment_data[slot_index]
	var slot = equipment_slots[slot_index]
	var original_icon_size = slot.item_icon.size
	# Store drag information
	drag_item = slot_data["item"]
	drag_quantity = slot_data["quantity"]
	drag_origin_slot = slot_index
	
	# Setup drag icon
	drag_icon.texture = drag_item.icon
	drag_icon.custom_minimum_size = original_icon_size
	drag_icon.size = original_icon_size
	drag_icon.self_modulate = Color(1.0, 1.0, 1.0, 0.4)
	drag_icon.visible = true
	
	# Set dragging flag
	dragging = true

func end_drag(target_slot_index: int) -> void:
	# Hide drag icon
	drag_icon.visible = false
	
	if drag_origin_slot != target_slot_index:
		# Get the slot data
		var origin_slot_data = equipment_data[drag_origin_slot]
		var target_slot_data = equipment_data[target_slot_index]
		var target_slot = equipment_slots[target_slot_index]
		
		# Check if target slot can accept this item
		if is_slot_compatible(target_slot, drag_item):
			# If target slot is empty, just move the item
			if target_slot_data["item"] == null:
				# Clear origin slot
				origin_slot_data["item"] = null
				origin_slot_data["quantity"] = 0
				emit_signal("item_changed", drag_origin_slot, null, 0)
				
				# Fill target slot
				target_slot_data["item"] = drag_item
				target_slot_data["quantity"] = drag_quantity
				emit_signal("item_changed", target_slot_index, drag_item, drag_quantity)
			
			# If target slot has the same item and it's stackable
			elif target_slot_data["item"] == drag_item and drag_item.stackable:
				# Add quantities
				target_slot_data["quantity"] += drag_quantity
				
				# Clear origin slot
				origin_slot_data["item"] = null
				origin_slot_data["quantity"] = 0
				
				# Emit signals for both slots
				emit_signal("item_changed", drag_origin_slot, null, 0)
				emit_signal("item_changed", target_slot_index, drag_item, target_slot_data["quantity"])
			
			# If target slot has a different item, swap them
			else:
				# Store target item info
				var target_item = target_slot_data["item"]
				var target_quantity = target_slot_data["quantity"]
				
				# If origin slot item can go in target slot, and target slot item can go in origin slot
				var origin_slot = equipment_slots[drag_origin_slot]
				if is_slot_compatible(target_slot, drag_item) and is_slot_compatible(origin_slot, target_item):
					# Swap items
					target_slot_data["item"] = drag_item
					target_slot_data["quantity"] = drag_quantity
					origin_slot_data["item"] = target_item
					origin_slot_data["quantity"] = target_quantity
					
					# Emit signals for both slots
					emit_signal("item_changed", drag_origin_slot, target_item, target_quantity)
					emit_signal("item_changed", target_slot_index, drag_item, drag_quantity)
	
	# Reset drag variables
	dragging = false
	drag_item = null
	drag_quantity = 0
	drag_origin_slot = -1
