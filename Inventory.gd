class_name Inventory
extends Node

# Signal emitted when inventory changes, UI can connect to this
signal inventory_changed

@export var weapon_node_path: NodePath #path to weapon node so we can load Weapons resource into it

@export var equipment_slots: Array[InventorySlot] #

# Main inventory properties
@export var inventory_size: int = 20  # Total number of slots
var slots: Array = []  # Will hold our inventory slots
var equipped_item: Item = null  # Currently equipped item

func _ready() -> void:
	# Initialize inventory slots when the node enters the scene tree
	initialize_inventory()

func initialize_inventory() -> void:
	# Create empty slots based on inventory_size
	slots.clear()
	for i in range(inventory_size):
		# Each "slot" is a dictionary containing item and quantity
		slots.append({"item": null, "quantity": 0})
	
	#create empty equipment slots (later on we dont want these to be cleared)
	for i in range(equipment_slots.size()):
		slots.append({"item": null, "quantity": 0})
	# Inform UI or other connected systems that inventory has changed
	emit_signal("inventory_changed")

func add_item(item: Item, quantity: int = 1) -> Dictionary:
	# This function adds an item to inventory and returns result info
	
	# Check if item is valid
	if not item:
		return {"success": false, "reason": "Invalid item"}
	
	var remaining_quantity = quantity
	var result = {"success": false, "reason": "", "remaining": quantity}
	
	# Step 1: Try equipment slots first if item is equipment
	if item.is_equipment:
		print("its equipment")
		var remaining = quantity
		
		for i in range(equipment_slots.size()):
			var slot = equipment_slots[i]
			
			if slot.item != null:
				continue
				
			slot.item = item.duplicate_item()
			remaining -= 1
		
	# If item is stackable, try to add to existing stacks first
	if item.stackable and quantity > 0:
		# First pass: Try to fill existing stacks
		for i in range(slots.size()):
			var slot = slots[i]
			
			# Skip empty slots or slots with different items
			if not slot["item"] or slot["item"].id != item.id:
				continue
				
			# Found a stack of the same item, add as much as possible
			var can_add = min(remaining_quantity, item.max_stack_size - slot["quantity"])
			
			if can_add > 0:
				slot["quantity"] += can_add
				remaining_quantity -= can_add
				
				if remaining_quantity <= 0:
					# We've added all items, we're done
					result["success"] = true
					result["remaining"] = 0
					emit_signal("inventory_changed")
					return result
	
	# Second pass: Look for empty slots for remaining items
	if remaining_quantity > 0:
		for i in range(slots.size()):
			var slot = slots[i]
			
			# If slot is empty, we can use it
			if not slot["item"]:
				# Add the item to this empty slot
				slot["item"] = item.duplicate_item()  # Make a copy to avoid reference issues
				
				if item.stackable:
					# Add as many as we can in this stack
					var can_add = min(remaining_quantity, item.max_stack_size)
					slot["quantity"] = can_add
					remaining_quantity -= can_add
				else:
					# Non-stackable item takes one slot per item
					slot["quantity"] = 1
					remaining_quantity -= 1
				
				if remaining_quantity <= 0:
					# We've added all items, we're done
					result["success"] = true
					result["remaining"] = 0
					emit_signal("inventory_changed")
					return result
	
	# If we get here, we've run out of slots but still have items
	if remaining_quantity < quantity:
		# We added some but not all items
		result["success"] = true
		result["remaining"] = remaining_quantity
		result["reason"] = "Inventory full, added " + str(quantity - remaining_quantity) + " items"
	else:
		# We couldn't add any items
		result["success"] = false
		result["reason"] = "Inventory full"
	
	emit_signal("inventory_changed")
	return result

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	# Function to remove items from a specific slot
	
	# Check if slot index is valid
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	
	# Check if there's an item in this slot
	if not slot["item"]:
		return false
	
	# Check if we're removing a valid quantity
	if quantity <= 0 or quantity > slot["quantity"]:
		return false
	
	# Remove the requested quantity
	slot["quantity"] -= quantity
	
	# If we removed all items, set the slot to empty
	if slot["quantity"] <= 0:
		slot["item"] = null
		slot["quantity"] = 0
	
	# Notify that inventory changed
	emit_signal("inventory_changed")
	return true

func get_item(slot_index: int) -> Item:
	# Returns the item in a specific slot (or null if empty)
	if slot_index < 0 or slot_index >= slots.size():
		return null
		
	return slots[slot_index]["item"]

func get_quantity(slot_index: int) -> int:
	# Returns the quantity in a specific slot
	if slot_index < 0 or slot_index >= slots.size():
		return 0
		
	return slots[slot_index]["quantity"]

func use_item(slot_index: int, player) -> bool:
	# Use an item from a specific slot
	
	# Check if slot index is valid
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	
	# Check if there's an item in this slot
	if not slot["item"]:
		return false
	
	# Try to use the item
	if slot["item"].use(player):
		# Item was used successfully, remove one from stack
		return remove_item(slot_index, 1)
	
	return false

func equip_item(slot_index: int) -> bool:
	# Equip an item from a specific slot
	
	# Check if slot index is valid
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	
	# Check if there's an item in this slot
	if not slot["item"]:
		return false
	
	# Set the equipped item (this is where you'd implement more complex equip logic)
	equipped_item = slot["item"]
	
	# Notify that inventory changed
	emit_signal("inventory_changed")
	return true

func get_equipped_item() -> Item:
	# Return the currently equipped item
	return equipped_item
