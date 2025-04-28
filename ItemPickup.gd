# ItemPickup.gd
extends Interactable

@export var item_resource: Resource
@export var quantity: int = 1
@onready var model_container: Node3D = $ModelContainer


# UI elements for floating name/info
@onready var label_3d = $Label3D

func _ready():
	# Set up the 3D label with item name
	if item_resource and label_3d:
		label_3d.text = item_resource.item_name
		
	if item_resource and item_resource.item_scene:
		var instance = item_resource.item_scene.instantiate()
		if instance:
			model_container.add_child(instance)
			
	# Connect area signals for mouse-based interaction (optional)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	
func _on_mouse_entered():
	highlight()
	
func _on_mouse_exited():
	unhighlight()

# Override the interact method from the base class
func interact(player):
	if player.has_method("pick_up_item"):
		if player.pick_up_item(item_resource, quantity):
			# Play pickup sound or effect
			var audio_player = AudioStreamPlayer.new()
			add_child(audio_player)
			# Add your pickup sound here
			# audio_player.stream = pickup_sound
			audio_player.play()
			
			# Give visual feedback
			# You could add a particle effect here
			
			# Wait for sound to finish then remove the item
			await audio_player.finished
			queue_free()
