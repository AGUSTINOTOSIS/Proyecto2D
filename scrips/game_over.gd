extends CanvasLayer


func _on_restart_pressed() -> void:
	# carga la ultima escena jugada
	if Global.last_level_path != "":
		get_tree().change_scene_to_file(Global.last_level_path)
	else:
		# Fallback: carga el meenu si no hay ultima escena
		get_tree().change_scene_to_file("res://scenes/UIs/main.tscn")

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UIs/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
