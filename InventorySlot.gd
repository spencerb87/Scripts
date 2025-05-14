class_name InventorySlot
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var highlight: ColorRect = $Highlight


func _ready() -> void:
	highlight.visible = false


func _on_mouse_entered() -> void:
	highlight.visible = true


func _on_mouse_exited() -> void:
	highlight.visible = false
