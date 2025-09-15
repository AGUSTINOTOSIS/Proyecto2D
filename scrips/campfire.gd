extends Area2D

@onready var reduction_timer = $ReductionTimer

var player_in_bonfire: bool = false
var reduction_times = {
	"intensidad_1": 0.0,
	"intensidad_2": 3.0,
	"intensidad_3": 8.0,
	"intensidad_4": 15.0,
	"intensidad_5": 20.0
}
##var reduction_rate: float = 15.0  # reduce 5 "unidades" por segundo
var current_reduction_time: float = 0.0
var current_effect: String = ""

func _ready() -> void:
	reduction_timer.wait_time = 0.1
	reduction_timer.one_shot = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_bonfire = true
		body.add_to_group("in_bonfire")
		reduction_timer.start()
		start_reduction_process()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_bonfire = false
		body.remove_from_group("in_bonfire")
		reduction_timer.stop()
		current_reduction_time = 0.0
		current_effect = ""
		print("El Player salio de fogata - Deteniendo reduccion")
		
func _on_reduction_timer_timeout() -> void:
	if player_in_bonfire:
		process_reduction()
		#var player = get_tree().get_first_node_in_group("player")
		#if player:
			#reduce_effects_on_player(player)
		#reduce_global_effects()

func reduce_effects_on_player(player: Node2D):
	var current_color = player.modulate
	if current_color.r < 1.0:
		var new_r = min(current_color.r + 0.05, 1.0)
		player.modulate = Color(new_r, current_color.g, current_color.b, current_color.a)
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("reduce_shake_intensity"):
			camera.reduce_shake_intensity(0.3)
	
	
	
	#var current_color = player.modulate
	#if current_color.r < 1.0:
		#var new_r = min(current_color.r + 0.1, 1.0)
		#player.modulate = Color(new_r, current_color.g, current_color.b, current_color.a)
	#if player.has_node("Camera2D"):
		#var camera = player.get_node("Camera2D")
		#if camera.has_method("reduce_shake_intensity"):
			#camera.reduce_shake_intensity(0.5)
			
func reduce_global_effects():
	var music_area = get_tree().get_first_node_in_group("music_area")
	if music_area and music_area.has_method("reduce_music_volume"):
		music_area.reduce_music_volume(0.1)
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("reduce_intensity_effects"):
		ui.reduce_intensity_effects_reverse(0.15)
		
func start_reduction_process():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		for i in range(5, 0, -1):
			var effect_name = "intensidad_" + str(i)
			if ui.has_node(effect_name) and ui.get_node(effect_name).modulate.a > 0.1:
				current_effect = effect_name
				current_reduction_time = 0.0
				print("cOmienza reduccion para: ", current_effect)
				return
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("stop_music_immediately"):
			music_area.stop_music_immediately()

func process_reduction():
	current_reduction_time += 0.1
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui or current_effect == "":
		return
	
	var required_time = reduction_times[current_effect]
	if current_reduction_time >= required_time:
		remove_current_effect()
		move_to_next_effect()

func remove_current_effect():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_node(current_effect):
		var effect = ui.get_node(current_effect)
		var tween = create_tween()
		tween.tween_property(effect, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if effect and effect.visible:
				effect.visible = false
		)
		
func move_to_next_effect():
	var current_number = int(current_effect.replace("intensidad_", ""))
	if current_number > 1:
		current_effect = "intensidad_" + str(current_number - 1)
		current_reduction_time = 0.0
		print("pasando a reducir: ", current_effect)
	else:
		current_effect = ""
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("stop_music_immediately"):
			music_area.stop_music_immediately()
