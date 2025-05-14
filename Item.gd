class_name Item
extends Resource

# Export variables allow us to edit these in the inspector when creating item resources
@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = false
@export var is_equipment: bool = false
@export var max_stack_size: int = 1
@export var item_scene: PackedScene = null  # For 3D representation when dropped in world


# Constructor to easily create items in code
func _init(p_id: String = "", p_name: String = "", p_desc: String = "", p_icon: Texture2D = null, 
		p_stackable: bool = false, p_max_stack: int = 1, p_scene: PackedScene = null, p_is_equipment: bool = false) -> void:
	# Initialize item with provided values
	id = p_id
	item_name = p_name
	description = p_desc
	icon = p_icon
	stackable = p_stackable
	max_stack_size = p_max_stack
	item_scene = p_scene
	is_equipment = p_is_equipment

# Method to create a copy of this item
func duplicate_item() -> Item:
	# Creates a new instance with the same properties
	var new_item = Item.new(id, item_name, description, icon, stackable, max_stack_size, item_scene, is_equipment)
	return new_item
