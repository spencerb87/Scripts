class_name Inventory
extends Node

signal item_changed(slot_index, item, quantity)

@onready var equipment_node: Control = $"../InventoryUI/Equipment"
var equipment_slots = []
var equipment_data = {}

func _ready() -> void:
	initialize_inventory()
	print(equipment_slots)
	
func initialize_inventory():
	equipment_slots = equipment_node.get_children()
	
	for i in range(equipment_slots.size()):
		var slot = equipment_slots[i]
				
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
