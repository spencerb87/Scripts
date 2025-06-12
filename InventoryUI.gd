class_name InventoryUI
extends Control

@onready var inventory: Inventory = $"../Inventory"
@onready var inventory_ui: InventoryUI = $"."
@onready var equipment: Control = $Equipment
@onready var backpack_inventory_ui: Control = $BackpackInventoryUI
@onready var backpack_grid: GridContainer = $BackpackInventoryUI/BackpackGrid
var equipmentslots = null
var backpack_slots = []

func _ready() -> void:
	inventory_ui.visible = false
	backpack_inventory_ui.visible = false
	equipmentslots = equipment.get_children()
	backpack_slots = backpack_grid.get_children()
	inventory.item_changed.connect(_on_item_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interface"):
		toggle_inventory()
		print(equipmentslots)

func toggle_inventory():
	inventory_ui.visible = !inventory_ui.visible
	
	var equipped_backpack = inventory.get_equipped_backpack()
	if equipped_backpack and inventory_ui.visible:
		backpack_inventory_ui.visible = true
		update_backpack_display(equipped_backpack)
	else:
		backpack_inventory_ui.visible = false
	
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

func update_backpack_display(backpack: Backpack):
	# Loop through all backpack slots
	for i in range(backpack_slots.size()):
		var slot = backpack_slots[i]
		# Only show slots that this backpack actually has
		if i < backpack.inventory_size:
			slot.visible = true
			# Get the item data for this slot
			var slot_data = backpack.inventory_data[i]
			# Display the item in the slot
			slot.display_item(slot_data["item"], slot_data["quantity"])
		else:
			# Hide slots that this backpack doesn't need
			slot.visible = false
