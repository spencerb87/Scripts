extends Area3D


@export var main_menu : PackedScene
# Time needed to extract (in seconds)
@export var extraction_time: float = 6.0

# Current progress towards extraction
var extraction_progress: float = 0.0

# Flag to track if player is in zone
var player_in_zone: bool = false

# Reference to the UI progress bar
var progress_bar: ProgressBar = null

# Signal emitted when extraction is complete
signal extraction_complete

func _ready():
	# Connect signals for player entering and exiting the zone
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create and setup the UI progress bar
	setup_progress_bar()

func setup_progress_bar():
	# Create a CanvasLayer for the UI
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Create a ProgressBar
	progress_bar = ProgressBar.new()
	canvas_layer.add_child(progress_bar)
	
	# Position the progress bar at the bottom center of the screen
	progress_bar.anchor_left = 0.3
	progress_bar.anchor_right = 0.7
	progress_bar.anchor_top = 0.9
	progress_bar.anchor_bottom = 0.95
	
	# Set the range and initial value
	progress_bar.min_value = 0.0
	progress_bar.max_value = extraction_time
	progress_bar.value = 0.0
	
	# Hide the progress bar initially
	progress_bar.visible = false

func _process(delta):
	if player_in_zone:
		extraction_progress += delta
		
		# Update the progress bar
		if progress_bar:
			progress_bar.value = extraction_progress
		
		# Check if extraction is complete
		if extraction_progress >= extraction_time:
			emit_signal("extraction_complete")
			
			# Hide the progress bar
			if progress_bar:
				progress_bar.visible = false
				
			# Load the main menu scene
			get_tree().change_scene_to_packed(main_menu)
	else:
		# Reset progress if player leaves the zone
		extraction_progress = 0.0
		
		# Hide the progress bar if player is not in zone
		if progress_bar:
			progress_bar.visible = false

# Called when a body enters the extraction zone
func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player"):
		player_in_zone = true
		
		# Show the progress bar
		if progress_bar:
			progress_bar.visible = true
			progress_bar.value = 0.0

# Called when a body exits the extraction zone
func _on_body_exited(body):
	# Check if the body is the player
	if body.is_in_group("player"):
		player_in_zone = false
		
		# Hide and reset the progress bar
		if progress_bar:
			progress_bar.visible = false
			progress_bar.value = 0.0
