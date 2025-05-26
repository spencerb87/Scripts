class_name Item
extends Resource

# Export variables allow us to edit these in the inspector when creating item resources
@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = false
@export var is_equipment: bool = false
@export var is_weapon: bool = false
@export var is_helmet: bool = false
@export var is_armor: bool = false
@export var is_melee: bool = false
@export var is_throwable: bool = false
@export var is_backpack: bool = false
@export var is_key: bool = false
@export var max_stack_size: int = 1
@export var item_scene_path: String = ""  # For 3D representation when dropped in world
