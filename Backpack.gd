class_name Backpack
extends Item

@export var inventory_size: int = 10
@export var inventory_data: Array[Dictionary] = []

func setup_inventory() -> void:
	
	print("Backpack init - inventory_size: ", inventory_size)
	if inventory_data.is_empty() and inventory_size > 0:
		for i in range(inventory_size):
			inventory_data.append({"item": null, "quantity": 0})
	print("Backpack inventory_data size: ", inventory_data.size())
			
func add_item_to_backpack(item: Item, quantity: int) -> Dictionary:
	for slot_data in inventory_data:
		if slot_data["item"] == item and item.stackable:
			var space_left = item.max_stack_size - slot_data["quantity"]
			if space_left > 0:
				var amount_to_add = min(quantity, space_left)
				slot_data["quantity"] += amount_to_add
				quantity -= amount_to_add
				
				if quantity <= 0:
					return {"success": true, "remaining": 0}
					
	for slot_data in inventory_data:
		if slot_data["item"] == null:
			slot_data["item"] = item
			slot_data["quantity"] = quantity
			return {"success": true, "remaining": 0}
			
	return {"success": false, "remaining": quantity}
	
func remove_item_from_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= inventory_data.size():
		return {"item": null, "quantity": 0}
		
	var slot_data = inventory_data[slot_index]
	var item = slot_data["item"]
	var quantity = slot_data["quantity"]
	
	slot_data["item"] = null
	slot_data["quantity"] = 0
	
	return {"item": item, "quantity": quantity}
