extends Control

@onready var sound_player = $MarginContainer/VBoxContainer/Start/AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_down() -> void:
	sound_player.play()
	pass # Replace with function body.

#func _on_start_pressed() -> void:
	#get_tree().change_scene_to_file("res://level_test.tscn")
	

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_audio_stream_player_finished() -> void:
	get_tree().change_scene_to_file("res://level_test.tscn")
	pass # Replace with function body.
