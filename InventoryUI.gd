class_name InventoryUI
extends Control

@onready var inventory: Inventory = $"../Inventory"
@onready var inventory_ui: InventoryUI = $"."
@onready var equipment: Control = $Equipment
var equipmentslots = null

func _ready() -> void:
	inventory_ui.visible = false
	equipmentslots = equipment.get_children()
	inventory.item_changed.connect(_on_item_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interface"):
		toggle_inventory()
		print(equipmentslots)

func toggle_inventory():
	inventory_ui.visible = !inventory_ui.visible
	if inventory_ui.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_item_changed(slot_index, item, quantity) -> void:
	var equipmentslots = equipment.get_children()
	
	if slot_index >= 0 and slot_index < equipmentslots.size():
		var slot = equipmentslots[slot_index]
		if slot is InventorySlot:
			slot.display_item(item, quantity)
