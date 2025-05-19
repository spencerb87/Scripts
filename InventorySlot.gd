class_name InventorySlot
extends Panel

enum SlotType {WEAPON, HELMET, ARMOR, THROWABLE, MELEE, GENERAL}
@export var slot_type: SlotType = SlotType.GENERAL
@onready var item_icon: TextureRect = $ItemIcon
@onready var highlight: ColorRect = $Highlight
@onready var quantity_label: Label = $QuantityLabel
@onready var mouse_over: Panel = $MouseOver
@onready var item_description: Label = $MouseOver/ItemDescription
@onready var item_name_label: Label = $MouseOver/ItemNameLabel

var item = null
var hovercolor = Color(0.0, 1.0, 0.0, 0.196)
var clickcolor = Color(1.0, 1.0, 0.0, 0.196)

func _ready() -> void:
	highlight.color = hovercolor
	highlight.visible = false
	item_icon.visible = false
	quantity_label.visible = false
	mouse_over.visible = false

func _on_mouse_entered() -> void:
	highlight.visible = true
	if item != null:
		mouse_over.visible = true
	else:
		mouse_over.visible = false

func _on_mouse_exited() -> void:
	highlight.visible = false
	mouse_over.visible = false

func display_item(new_item: Item, quantity: int) ->void:
	item = new_item
	
	if item != null:
		item_icon.texture = item.icon
		item_icon.visible = true
		item_name_label.text = item.item_name
		item_description.text = item.description
		
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		item_icon.texture = null
		item_icon.visible = false
		quantity_label.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		highlight.color = clickcolor
	else:
		highlight.color = hovercolor
