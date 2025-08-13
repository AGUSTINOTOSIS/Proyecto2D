extends CanvasLayer

@onready var click_sound: AudioStreamPlayer = $clickSound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_safe_connect($Panel/next, "pressed", _on_next_pressed)
	_safe_connect($Panel/try_again, "pressed", _on_try_again_pressed)
	_safe_connect($Panel/menu, "pressed", _on_menu_pressed)
	
# Deshabilitar botón "Siguiente" si no hay siguiente nivel
	$Panel/next.disabled = Global.current_level >= Global.max_levels

func _safe_connect(button: Button, signal_name: String, callable: Callable):
	if button.is_connected(signal_name, callable):
		button.disconnect(signal_name, callable)
	button.connect(signal_name, callable)

func _on_next_pressed() -> void:
	_cleanup()
	Global.current_level += 1 # Incrementa el nivel
	get_tree().change_scene_to_file(Global.get_level_path())


func _on_try_again_pressed() -> void:
	_cleanup()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	_cleanup()
	get_tree().change_scene_to_file("res://scenes/UIs/main.tscn")
	
func _cleanup():
	click_sound.play()
	await click_sound.finished
	# Desbloquear jugador antes de cambiar escena
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_block_player"):
		player.set_block_player(false)
	queue_free()
