extends StaticBody2D

@onready var collision_shape = $CollisionShape2D
@onready var player_detector = $PlayerDetector 

const TOTAL_PLANKS: int = 72
var all_planks_constructed: bool = false
var constructed_count: int = 0 # Variable para guardar el conteo

func _ready() -> void:
	check_planks_status()

func _process(_delta: float) -> void:
	if not all_planks_constructed:
		check_planks_status()

func check_planks_status():
	var all_planks = get_tree().get_nodes_in_group("wooden_planks")
	constructed_count = 0 # Reiniciar el conteo
	for plank in all_planks:
		if plank.is_constructed:
			constructed_count += 1
	
	if constructed_count >= TOTAL_PLANKS:
		enable_wall(false)
		all_planks_constructed = true
		print("¡Todos los tablones construidos! Muro desactivado")

func enable_wall(enable: bool):
	collision_shape.set_deferred("disabled", not enable)
	if player_detector:
		player_detector.set_deferred("monitoring", enable)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not all_planks_constructed:
			# Calcula cuantos tablones faltan
			var planks_needed = TOTAL_PLANKS - constructed_count
			# Notificar a la UI
			var ui = get_tree().get_first_node_in_group("ui")
			if ui and ui.has_method("show_wall_message"):
				ui.show_wall_message(planks_needed)
