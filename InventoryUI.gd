class_name InventoryUI
extends Control

@onready var inventory_ui: InventoryUI = $"."
var equipmentslots = null

func _ready() -> void:
	inventory_ui.visible = false
	equipmentslots = inventory_ui.get_children()

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
