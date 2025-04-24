# Interactable.gd
class_name Interactable
extends Area3D

# Visual indicator when player looks at the item
@export var highlight_material: Material
var original_materials = []
var is_highlighted = false

# Function to highlight the object when looked at
func highlight():
	if is_highlighted:
		return
		
	is_highlighted = true
	
	# Store original materials and apply highlight
	for child in get_children():
		if child is MeshInstance3D:
			original_materials.append(child.get_surface_override_material(0))
			child.set_surface_override_material(0, highlight_material)
			
func unhighlight():
	if not is_highlighted:
		return
		
	is_highlighted = false
	
	# Restore original materials
	var material_index = 0
	for child in get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, original_materials[material_index])
			material_index += 1
			
# Called when player interacts with this object
func interact(player):
	# Override in child classes
	pass
