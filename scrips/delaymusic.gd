extends Area2D

@onready var timer = $Timer
@onready var audio_stream_player = $AudioStreamPlayer
@onready var effect_timer = $EffectTimer

@export var music: AudioStream

var reduction_rate: float = 5.0
var music_volume: float = 1.0
var effect_intensity: float = 0.0
var bonfire_counter: float = 0.0  # contador de reduccion por fogata
var accumulated_intensity: float = 0.0

var time_in_area: float = 0.0
var player_in_area: bool = false
var effects_started: bool = false

var effect_times = {
	"intensidad_1": 0.0,    # Inmediato al empezar música
	"intensidad_2": 20.0,   # 20 segundos después
	"intensidad_3": 46.0,   # 20 + 26 = 46 segundos
	"intensidad_4": 78.0,   # 46 + 32 = 78 segundos
	"intensidad_5": 132.0   # 78 + 54 = 132 segundos
}

func _ready() -> void:
	timer.wait_time = 60.0
	timer.one_shot = true
	effect_timer.one_shot = false
	effect_timer.wait_time = 0.1
	
	if music:
		audio_stream_player.stream = music
		
func _process(delta: float) -> void:
	if player_in_area:
		time_in_area += delta
		update_effects_based_on_bonfire()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		time_in_area = 0.0
		timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		timer.stop()
		effect_timer.stop()
		effects_started = false
		
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_method("hide_all_intensity_effects"):
			ui.hide_all_intensity_effects()
		reset_player_effects(body)
		print("Player salio- Cancelando musica y efectos")
		
func reset_player_effects(player: Node2D):
	var tween = create_tween()
	tween.tween_property(player, "modulate", Color(1, 1, 1, 1), 1.5)
	
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("stop_shake"):
			camera.stop_shake()
	print("Color del player restaurado y cámara estabilizada")

func _on_timer_timeout() -> void:
	audio_stream_player.play()
	effects_started = true
	effect_timer.start()

func _on_effect_timer_timeout() -> void:
	if not effects_started:
		return
		
	# calcular intensidad considerando fogata
	var effective_time = time_in_area - (bonfire_counter * reduction_rate)
	# tiempo desde que empezo la musica
	var music_time = effective_time - 60.0
	#mostrar efectos segun el tiempo
	if music_time >= effect_times["intensidad_1"] and not is_effect_visible("intensidad_1"):
		show_effect("intensidad_1")
	if music_time >= effect_times["intensidad_2"] and not is_effect_visible("intensidad_2"):
		show_effect("intensidad_2")
	if music_time >= effect_times["intensidad_3"] and not is_effect_visible("intensidad_3"):
		show_effect("intensidad_3")
	if music_time >= effect_times["intensidad_4"] and not is_effect_visible("intensidad_4"):
		show_effect("intensidad_4")
	if music_time >= effect_times["intensidad_5"] and not is_effect_visible("intensidad_5"):
		show_effect("intensidad_5")
		effect_timer.stop()
		apply_final_effects_immediately()
		
func apply_final_effects_immediately():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Color actual del player: ", player.modulate)
		var current_color = player.modulate
		var target_color = Color(0, current_color.g, current_color.b, current_color.a)
		print("Color objetivo: ", target_color)
		var tween_player = create_tween()
		tween_player.tween_property(player, "modulate", target_color, 2.0)
			
		if player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			if camera.has_method("shake_screen"):
				camera.shake_screen(3.0, 60.0, false)
		print("Efectos finales aplicados: R=0 y cámara temblando")
				
	
func is_effect_visible(effect_name: String) -> bool:
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_node(effect_name):
		return ui.get_node(effect_name).modulate.a > 0
	return false

func show_effect(effect_name: String):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_node(effect_name):
		var effect = ui.get_node(effect_name)
		print("Mostrando efecto: ", effect_name)
		var tween = create_tween()
		tween.tween_property(effect, "modulate:a", 1.0, 2.0)
		effect.visible = true
		
func reduce_music_volume(amount: float):
	music_volume = max(0.0, music_volume - amount)
	audio_stream_player.volume_db = linear_to_db(music_volume)
	
	if music_volume <= 0.1 and audio_stream_player.playing:
		audio_stream_player.stop()
		effects_started = false
		print("Musica detenida por fogata")
		
func increase_music_volume(amount: float):
	music_volume = min(1.0, music_volume + amount)
	audio_stream_player.volume_db = linear_to_db(music_volume)
	
	if music_volume > 0.1 and not audio_stream_player.playing and player_in_area:
		audio_stream_player.play()
		print("Musica reiniciada")

func update_effects_based_on_bonfire():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_in_group("in_bonfire"):
		bonfire_counter += 0.1
		if bonfire_counter >= 1.0:
			time_in_area = max(0.0, time_in_area - reduction_rate)
			bonfire_counter = 0.0
	else:
		pass
		
func stop_music_immediately():
	audio_stream_player.stop()
	effects_started = false
	time_in_area = 0.0
	bonfire_counter = 0.0
	print("msica detenida por fogata")
