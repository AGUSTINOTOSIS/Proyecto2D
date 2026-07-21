extends Area2D

@onready var timer = $Timer
@onready var audio_stream_player = $AudioStreamPlayer
@onready var effect_timer = $EffectTimer
@onready var health_loss_timer = $HealthLossTimer
@onready var cold_burst_timer = $ColdBurstTimer
@export var music: AudioStream

var reduction_rate: float = 5.0
var music_volume: float = 1.0
var effect_intensity: float = 0.0
var bonfire_counter: float = 0.0  # contador de reduccion por fogata
var accumulated_intensity: float = 0.0

var time_in_area: float = 0.0
var player_in_area: bool = false
var effects_started: bool = false
var bonfire_active: bool = false
var final_effects_applied: bool = false
var current_effect_level: int = 0
var bonus_time_accumulated: float = 0.0
var base_cooldown: float = 60.0
var time_in_bonfire: float = 0.0
var bonfire_ready: bool = false
var bonus_accumulation_mode: String = "NONE"  # NONE, WARMING, ACTIVE
var max_bonus_time: float = 60.0
var initial_immunity_time: float = 60.0  # 60 segundos iniciales de inmunidad
var initial_immunity_used: bool = false  # Si ya se usó la inmunidad inicial
var cold_multiplier: float = 1.0  # Multiplicador inicial del efecto de frío
var should_lose_health: bool = false
var cold_acceleration_factor: float = 1.0
var active_cold_water_areas: Dictionary = {}
var damage_delay_timer: Timer = null # Timer para el tiempo extra de tensión
var base_damage_interval: float = 1.5 # Tiempo base para perder vida (el valor de _ready)
var is_game_over: bool = false

var effect_times = {
	"intensidad_1": 0.0,    # Inmediato al empezar música
	"intensidad_2": 20.0,   # 20 segundos después
	"intensidad_3": 46.0,   # 20 + 26 = 46 segundos
	"intensidad_4": 78.0,   # 46 + 32 = 78 segundos
	"intensidad_5": 132.0   # 78 + 54 = 132 segundos
}

func _ready() -> void:
	health_loss_timer.wait_time = base_damage_interval
	health_loss_timer.one_shot = false
	
	timer.wait_time = base_cooldown
	timer.one_shot = true
	effect_timer.one_shot = false
	effect_timer.wait_time = 0.1
	
	if music:
		audio_stream_player.stream = music
	add_to_group("music_area")
	bonus_time_accumulated = initial_immunity_time
		
func _process(delta: float) -> void:
	if is_game_over:
		return
	if player_in_area and (not bonfire_active or bonus_time_accumulated < initial_immunity_time):
		time_in_area += delta * cold_acceleration_factor
		update_effects()
	if bonfire_active:
		update_bonfire_time(delta)
		
	if not bonfire_active and bonus_time_accumulated > 0 and bonus_time_accumulated < initial_immunity_time:
		bonus_time_accumulated = max(0, bonus_time_accumulated - delta)
		if bonus_time_accumulated <= 0:
			print("Tiempo bonus agotado")
	check_music_loop()
	update_camera_shake()
	update_health_loss_state()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		time_in_area = 0.0
		timer.start()
		
		# Activar efectos de frío si el jugador está en un área fría
		if not bonfire_active:
			effects_started = true
			effect_timer.start()
			print("Player entró en área fría - Efectos de frío activados")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		timer.stop()
		effect_timer.stop()
		effects_started = false
		final_effects_applied = false
		
		# Resetear estado de fogata
		bonus_accumulation_mode = "NONE"
		time_in_bonfire = 0.0
		bonfire_ready = false
		
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_method("hide_all_intensity_effects"):
			ui.hide_all_intensity_effects()
		reset_player_effects(body)
		
		# Permitir que los efectos de frío se reactiven
		if not audio_stream_player.playing:
			time_in_area = 0.0  # Reiniciar el tiempo en el área fría
			bonus_time_accumulated = 0.0
			print("Player salió de la fogata - Efectos de frío pueden reactivarse")
		
func reset_player_effects(player: Node2D):
	var tween = create_tween()
	tween.tween_property(player, "modulate", Color(1, 1, 1, 1), 1.5)
	
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("stop_shake"):
			camera.stop_shake()
	if not health_loss_timer.is_stopped():
		health_loss_timer.stop()
	
	_stop_health_loss()
	should_lose_health = false

func _on_timer_timeout() -> void:
	audio_stream_player.play()
	effects_started = true
	effect_timer.start()

func _on_effect_timer_timeout() -> void:
	if not effects_started:
		return
	check_and_apply_effects()

func check_and_apply_effects():
	# Calcular el tiempo efectivo considerando el tiempo bonus
	var effective_time = time_in_area - bonus_time_accumulated
	var music_time = effective_time - base_cooldown  # Tiempo desde que empezó la música
	
	# Mostrar efectos según el tiempo
	if music_time >= effect_times["intensidad_1"] and not is_effect_visible("intensidad_1"):
		show_effect("intensidad_1")
		if not audio_stream_player.playing:
			audio_stream_player.play()  # Iniciar la música junto con el primer efecto
			print("Música de frío iniciada con el primer efecto")
	if music_time >= effect_times["intensidad_2"] and not is_effect_visible("intensidad_2"):
		show_effect("intensidad_2")
	if music_time >= effect_times["intensidad_3"] and not is_effect_visible("intensidad_3"):
		show_effect("intensidad_3")
	if music_time >= effect_times["intensidad_4"] and not is_effect_visible("intensidad_4"):
		show_effect("intensidad_4")
	if music_time >= effect_times["intensidad_5"] and not is_effect_visible("intensidad_5"):
		show_effect("intensidad_5")
		apply_final_effects_immediately()
		
func apply_final_effects_immediately():
	if final_effects_applied:
		return
	final_effects_applied = true
	
	# Configurar la musica para iniciar en el minuto 2:12
	if audio_stream_player:
		audio_stream_player.seek(132.0)  # 2:12 en segundos
		if not audio_stream_player.playing:
			audio_stream_player.play()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var current_color = player.modulate
		var target_color = Color(0, current_color.g, current_color.b, current_color.a)
		var tween_player = create_tween()
		tween_player.tween_property(player, "modulate", target_color, 2.0)
			
		if player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			if camera.has_method("shake_screen"):
				camera.shake_screen(3.0, 0.0, true)
		
		update_health_loss_state()
		
		# Iniciar pérdida de vida después de un tiempo aleatorio
		var random_delay = randf_range(15.0, 20.0)  # Tiempo aleatorio entre 15 y 20 segundos
		var delay_timer = get_tree().create_timer(random_delay)
		delay_timer.timeout.connect(_start_health_loss)
	
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
		
		if effect_name == "intensidad_1" and not audio_stream_player.playing:
			audio_stream_player.play()
		
func set_bonfire_state(active: bool):
	bonfire_active = active
	
	if active:
		# Iniciar proceso de calentamiento (3 segundos)
		bonus_accumulation_mode = "WARMING"
		time_in_bonfire = 0.0
		bonfire_ready = false
		effect_timer.stop()
		update_health_loss_state()
	else:
		if bonus_accumulation_mode == "ACTIVE":
			reset_effects_and_music()
		else:
			if current_effect_level >= 5:
				should_lose_health = true
				_start_health_loss()
			else:
				if current_effect_level >= 1 and not audio_stream_player.playing:
					audio_stream_player.play()
		bonus_accumulation_mode = "NONE"
		time_in_bonfire = 0.0
		bonfire_ready = false
		
		if bonus_time_accumulated < initial_immunity_time:
			effect_timer.start()
		
		update_health_loss_state()
		
func update_effects():
	if bonus_time_accumulated >= initial_immunity_time and bonfire_active:
		return

	var effective_time = time_in_area
	if bonus_time_accumulated > 0:
		effective_time = max(0, time_in_area - (initial_immunity_time - bonus_time_accumulated))
	if not effects_started and effective_time >= base_cooldown:
		start_effects()
	if effects_started:
		var music_time = (effective_time - base_cooldown) * cold_multiplier  # Aplicar el multiplicador
		if not effects_started and effective_time >= base_cooldown:
			start_effects()
		if effects_started:
		# Actualizar nivel de efecto basado en el tiempo de música
			if music_time >= effect_times["intensidad_5"] and current_effect_level < 5:
				current_effect_level = 5
				apply_final_effects_immediately()
			elif music_time >= effect_times["intensidad_4"] and current_effect_level < 4:
				current_effect_level = 4
			elif music_time >= effect_times["intensidad_3"] and current_effect_level < 3:
				current_effect_level = 3
			elif music_time >= effect_times["intensidad_2"] and current_effect_level < 2:
				current_effect_level = 2
			elif music_time >= effect_times["intensidad_1"] and current_effect_level < 1:
				current_effect_level = 1
		
			apply_effects_based_on_level()
			update_health_loss_state()
		
			# Iniciar música cuando aparece el primer efecto
			if current_effect_level >= 1 and not audio_stream_player.playing:
				audio_stream_player.play()
				audio_stream_player.seek(0)  # Reinicia la música desde el principio
		
		
func start_effects():
	effects_started = true
	#audio_stream_player.play()
	effect_timer.start()

func check_and_show_effect(effect_name: String, current_time: float, required_time: float):
	if current_time >= required_time and not is_effect_visible(effect_name):
		show_effect(effect_name)
		
func reduce_effects_in_reverse_order():
	var player = get_tree().get_first_node_in_group("player")
	if current_effect_level <= 0:
		# Si no hay efectos visibles, reduce el volumen de la música gradualmente
		if audio_stream_player.playing:
			audio_stream_player.stop()
			
		if player and player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			if camera.has_method("stop_shake"):
				camera.stop_shake()  # Detener el temblor de la cámara
		return
		
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var current_effect = "intensidad_" + str(current_effect_level)
		if ui.has_node(current_effect):
			var effect = ui.get_node(current_effect)
			var new_alpha = max(0.0, effect.modulate.a - 0.02)
			effect.modulate.a = new_alpha
			
			if new_alpha <= 0.1:
				effect.visible = false
				current_effect_level -= 1
				print("Efecto nivel ", current_effect_level + 1, " eliminado")
				
				if current_effect_level < 5 and player and player.has_node("Camera2D"):
					var camera = player.get_node("Camera2D")
					if camera.has_method("stop_shake"):
						camera.stop_shake()
	
	# Reducir gradualmente el color del jugador
	if player and player.modulate.r < 1.0:
		player.modulate.r = min(player.modulate.r + 0.02, 1.0)
	
func reset_music_system():
	audio_stream_player.stop()
	effects_started = false
	time_in_area = max(0, time_in_area - base_cooldown)
	final_effects_applied = false
	print("Sistema de música reseteado - 60 segundos de inmunidad")
	
func apply_effects_based_on_level():
	for i in range(1, 6):
		var effect_name = "intensidad_" + str(i)
		var should_be_visible = i <= current_effect_level
		
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_node(effect_name):
			var effect = ui.get_node(effect_name)
			if should_be_visible and effect.modulate.a < 1.0:
				effect.modulate.a = min(effect.modulate.a + 0.02, 1.0)
				effect.visible = true
			elif not should_be_visible and effect.modulate.a > 0.0:
				effect.modulate.a = max(effect.modulate.a - 0.02, 0.0)
				if effect.modulate.a <= 0.1:
					effect.visible = false
	if current_effect_level >= 5:
		update_camera_shake()
				
func reduce_bonus_time(amount: float):
	if bonus_time_accumulated > 0 and current_effect_level <= 0:
		bonus_time_accumulated = max(0, bonus_time_accumulated - amount)
		print("Reduciendo tiempo bonus: ", bonus_time_accumulated, " segundos restantes")
	if current_effect_level <= 0 and bonus_time_accumulated > 0:
		bonus_time_accumulated = min(bonus_time_accumulated + 1.0, 60.0)
		
func update_bonfire_time(delta: float):
	if bonus_accumulation_mode == "NONE":
		return
		
	time_in_bonfire += delta
	
	# Modo calentamiento (3 segundos)
	if bonus_accumulation_mode == "WARMING" and time_in_bonfire >= 3.0:
		bonus_accumulation_mode = "ACTIVE"
		time_in_bonfire = 0.0
		bonfire_ready = true
		print("¡Fogata lista! Ahora puedes ganar tiempo bonus")
		
	# Modo activo - acumular tiempo bonus solo si no hay efectos visibles
	elif bonus_accumulation_mode == "ACTIVE":
		reduce_effects_in_reverse_order()
		if current_effect_level == 0:  # Verifica que no haya efectos visibles
			if time_in_bonfire >= 10.0:  # Cada 10 segundos en la fogata
				bonus_time_accumulated = min(bonus_time_accumulated + 5.0, max_bonus_time)
				time_in_bonfire = 0.0  # Reinicia el contador de tiempo en la fogata
				print("Tiempo bonus acumulado: ", bonus_time_accumulated, " segundos")

func reset_effects_and_music():
	# Reiniciar el tiempo acumulado
	time_in_area = 0.0
	accumulated_intensity = 0.0
	current_effect_level = 0
	effects_started = false
	final_effects_applied = false
	
	# Detener la música y reiniciarla
	if audio_stream_player.playing:
		audio_stream_player.stop()
		audio_stream_player.seek(0)
	
	# Reiniciar los efectos visuales
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		for i in range(1, 6):
			var effect_name = "intensidad_" + str(i)
			if ui.has_node(effect_name):
				var effect = ui.get_node(effect_name)
				effect.modulate.a = 0.0
				effect.visible = false
	print("Efectos y musica reiniciados")
	
func check_music_loop():
	if final_effects_applied and audio_stream_player:
		var playback_position = audio_stream_player.get_playback_position()
		
		# Si la musica llega al minuto 3:33 (213 segundos), reiniciarla desde 2:12 (132 segundos)
		if playback_position >= 213.0:
			audio_stream_player.seek(132.0)  # Reiniciar desde 2:12
			print("Reiniciando música desde 2:12")
			
func update_camera_shake():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_node("Camera2D"):
		return
	
	var camera = player.get_node("Camera2D")
	
	# Si tenemos nivel 5, asegurar que la camara tiemble continuamente
	if current_effect_level >= 5 and camera.has_method("shake_screen"):
		if not camera.should_shake_continuously:
			camera.shake_screen(3.0, 0.0, true)
	# Si tenemos menos de nivel 5, detener el shake continuo
	elif current_effect_level < 5 and camera.has_method("stop_shake"):
		camera.stop_shake()
		
func apply_cold_multiplier(water_area: Area2D, multiplier: float):
	active_cold_water_areas[water_area] = multiplier
	var min_multiplier = get_current_min_water_multiplier()
	cold_multiplier = min_multiplier

func reset_cold_multiplier(water_area: Area2D):
	active_cold_water_areas.erase(water_area)
	if active_cold_water_areas.is_empty():
		cold_multiplier = 1.0
	else:
		var min_multiplier = get_current_min_water_multiplier()
		cold_multiplier = min_multiplier

func _on_health_loss_timer_timeout() -> void:
	if is_game_over:
		_stop_health_loss()
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player and should_lose_health:
		if player.health > 0:
			player.take_damage(1) # Reducir la vida en 1
			
			var player_health = player.get_health()
			var delay_increase = 0.0
			
			if player_health > 0 and player_health <= 5:
				var health_difference = 5 - player_health
				delay_increase = float(health_difference) * 3.0
			var total_wait_time = base_damage_interval + delay_increase
			
			health_loss_timer.wait_time = total_wait_time
			health_loss_timer.start()
		else:
			_stop_health_loss()
	else:
		_stop_health_loss()

func _start_health_loss():
	if should_lose_health:
		health_loss_timer.start()

func update_health_loss_state():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var new_should_lose_health = (current_effect_level >= 5 and not bonfire_active and player.modulate.r == 0)
		if new_should_lose_health != should_lose_health:
			should_lose_health = new_should_lose_health
			if should_lose_health:
				var random_delay = randf_range(15.0, 20.0)
				var delay_timer = get_tree().create_timer(random_delay)
				delay_timer.timeout.connect(_start_health_loss)
			else:
				_stop_health_loss()

func _stop_health_loss():
	if health_loss_timer and not health_loss_timer.is_stopped():
		health_loss_timer.stop()
		
func apply_cold_burst(multiplier: float, duration: float):
	cold_acceleration_factor += (multiplier - 1.0)
	cold_burst_timer.wait_time = duration
	cold_burst_timer.start()
	cold_acceleration_factor = max(1.0, cold_acceleration_factor)

func _on_cold_burst_timer_timeout() -> void:
	cold_acceleration_factor = 1.0

func get_current_min_water_multiplier() -> float:
	var min_mult = 999.0 # Inicializar con un valor muy alto
	for multiplier in active_cold_water_areas.values():
		min_mult = min(min_mult, multiplier)
	return min_mult

func freeze_cold_system():
	is_game_over = true
	_stop_health_loss() 
	timer.stop()
	effect_timer.stop()
	cold_burst_timer.stop()
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("hide_all_intensity_effects"):
		ui.hide_all_intensity_effects()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		reset_player_effects(player)
	if audio_stream_player.playing:
		audio_stream_player.stop()
	print("Sistema de frío congelado por fin del juego.")
