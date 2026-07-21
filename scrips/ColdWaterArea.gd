extends Area2D

@export var cold_multiplier: float = 2.0  # Multiplicador del efecto de frío
@export var walk_speed_reduction: float = 0.5  # Reducción de velocidad de caminata (50%)
@export var jump_speed_reduction: float = 0.5  # Reducción de velocidad de salto (50%)

var player_in_area: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Verificar si el cuerpo es el jugador
		if body.has_method("apply_speed_reduction"):
			body.apply_speed_reduction(walk_speed_reduction)
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("apply_cold_multiplier"):
			music_area.apply_cold_multiplier(self, cold_multiplier)
		
	elif body.is_in_group("enemies"):
		if body.has_method("die"):
			body.die()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):  # Verificar si el cuerpo es el jugador
		player_in_area = false
		
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("reset_cold_multiplier"):
			music_area.reset_cold_multiplier(self)
		if music_area and music_area.cold_multiplier == 1.0:
			if body.has_method("reset_speed"):
				body.reset_speed()
