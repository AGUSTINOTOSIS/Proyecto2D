extends CanvasLayer

@onready var start_button = $Control/start
@onready var options_button = $Control/options
@onready var quit_button = $Control/quit

func _ready() -> void:
	start_button.grab_focus()
 
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/words/word_1.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
