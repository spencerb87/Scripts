class_name InventorySlot
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var highlight: ColorRect = $Highlight
@onready var quantity_label: Label = $QuantityLabel


func _ready() -> void:
	highlight.visible = false
	item_icon.visible = false
	quantity_label.visible = false

func _on_mouse_entered() -> void:
	highlight.visible = true

func _on_mouse_exited() -> void:
	highlight.visible = false

func display_item(item: Item, quantity: int) ->void:
	if item != null:
		item_icon.texture = item.icon
		item_icon.visible = true
		
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		item_icon.texture = null
		item_icon.visible = false
		quantity_label.visible = false
