extends CanvasLayer

@onready var damage_overlay = $damageOverlay
@onready var freeze_effect = $Effect5
@onready var freeze_timer = $freeze_timer

@onready var timer_label = $tiempo_label
@onready var countdown_timer = $countdown
@onready var audio_stream_player = $emergencia

@onready var wall_message_label = $WallMessageLabel
@onready var wall_message_timer = $WallMessageTimer
@onready var wood_label = $wood
@onready var fps_label = $FPSLabel #para los FPS

var time_left : int = 180
var special_music_playing: bool = false
var camera_shake_playing: bool = false
var original_volume: float = 0.0

var damage_color = Color("#8d0027")
var max_alpha = 0.4
var wood_count: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if freeze_effect:
		freeze_effect.modulate.a = 0
		freeze_effect.visible = false
		
		
	damage_overlay.color = damage_color
	damage_overlay.color.a = 0
	damage_overlay.visible = false
	
	if get_parent().has_node("player"):
		$health_ProgressBar.value = get_parent().get_node("player").health
		$FuitpointsLabel.text = "Frutas:" + str(get_parent().get_node("player").fruitCount)
	
	countdown_timer.wait_time = 1.0
	countdown_timer.start()
	timer_label.text = str(time_left)
	
	var bg_music = get_node("../audio_fondo")
	if bg_music:
		original_volume = bg_music.volume_db
	
	# Verificar si el nivel actual es "word_20"
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "word_20":
		$FuitpointsLabel.visible = false  # Ocultar frutas
		timer_label.visible = false       # Ocultar tiempo
		countdown_timer.stop()            # Detener el temporizador
	
	if wall_message_label:
		wall_message_label.text = ""
		wall_message_label.visible = false


func show_freeze_effect(duration: float):
	if freeze_effect and freeze_timer:
		freeze_timer.stop()
		var tween = create_tween()
		tween.tween_property(freeze_effect, "modulate:a", 1.0, 0.1)
		freeze_effect.visible = true
		
		freeze_timer.wait_time = duration
		freeze_timer.start()
		
func extend_freeze_effect(duration: float):
	if freeze_effect and freeze_effect.visible:
		if freeze_timer:
			freeze_timer.wait_time = duration
			freeze_timer.start()
			
func hide_freeze_effect():
	if freeze_effect:
		var tween_hide = create_tween()
		tween_hide.set_parallel(true)
		tween_hide.tween_property(freeze_effect, "modulate:a", 0.0, 1.0)
		tween_hide.tween_callback(func():
			if freeze_effect and freeze_effect.visible:
				freeze_effect.visible = false
		).set_delay(1.0)
		
func _on_freeze_timer_timeout() -> void:
	var player = get_parent().get_node("player")
	if player and player.has_method("is_frozen") and not player.is_frozen:
			hide_freeze_effect()


func update_damage_effect(health_percent: float):
	var lost_health = 100 - health_percent
	var alpha = min(max_alpha, (lost_health / 100.0) * max_alpha)
	damage_overlay.color.a = alpha
	damage_overlay.visible = alpha > 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$health_ProgressBar.value = get_parent().get_node("player").health
	$FuitpointsLabel.text = "Frutas:" + str(get_parent().get_node("player").fruitCount)
	
	if get_parent().has_node("player"):
		var health = get_parent().get_node("player").health
		var health_percent = (float(health) / 100.0) * 100
		update_damage_effect(health_percent)
		
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: " + str(snapped(fps, 0.1))
		
func flash_damage():
	var tween = create_tween()
	tween.tween_property(damage_overlay, "color:a", max_alpha, 0.1)
	tween.tween_property(damage_overlay, "color:a", damage_overlay.color.a, 0.3)
	



func _on_countdown_timeout() -> void:
	time_left -= 1
	timer_label.text = str(time_left)
	
	if time_left <= 94 and not camera_shake_playing:
		start_camera_shake()
	
	if time_left <= 110 and not special_music_playing:
		start_special_effects()
	
	if time_left <= 6 and camera_shake_playing:
		stop_camera_shake()
		
	if time_left <= 0:
		end_game()
		
func start_camera_shake():
	camera_shake_playing = true
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").shake_screen(10.0, 0.0, true) #20
		
func stop_camera_shake():
	camera_shake_playing = false
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").stop_shake()
		
func start_special_effects():
	special_music_playing = true
	audio_stream_player.play()
	
	Radio.emergency_music = true
	var bg_music = get_node("../audio_fondo")
	if bg_music:
		var tween = create_tween()
		tween.tween_property(bg_music, "volume_db", -80.0, 5.0)
	var tween_radio = create_tween()
	tween_radio.tween_property(Radio, "MAX_VOLUME", -20.0, 3.0)
	tween_radio.tween_property(Radio, "BG_MUSIC_REDUCTION", -20.0, 3.0)
		
func end_game():
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").stop_shake()
	get_tree().change_scene_to_file("res://scenes/UIs/game_over.tscn")

func stop_timer():
	countdown_timer.stop()  # Detiene el contador
	
func add_wood(amount: int):
	wood_count += amount
	update_wood_display()
	#if has_node("wood"):
		#$wood.text = "Madera: " + str(wood_count)
		
func has_wood(amount: int) -> bool:
	return wood_count >= amount
	
func use_wood(amount: int):
	if has_wood(amount):
		wood_count -= amount
		update_wood_display()

func update_wood_display():
	if wood_label: 
		wood_label.text = "Madera: " + str(wood_count)
		
func show_intensity_effect(effect_name: String):
	if has_node(effect_name):
		var effect = get_node(effect_name)
		var tween = create_tween()
		tween.tween_property(effect, "modulate:a", 1.0, 2.0)
		effect.visible = true
		
func hide_all_intensity_effects():
	for i in range(1, 6):
		var effect_name = "intensidad_" + str(i)
		if has_node(effect_name):
			var effect = get_node(effect_name)
			var tween = create_tween()
			tween.tween_property(effect, "modulate:a", 0.0, 1.0)
			tween.tween_callback(func():
				if effect and effect.visible:
					effect.visible = false
			).set_delay(1.0)
		
func reduce_intensity_effects(amount: float):
	for i in range(1, 6):
		var effect_name = "intensidad_" + str(i)
		if has_node(effect_name):
			var effect = get_node(effect_name)
			if effect.modulate.a > 0:
				var new_alpha = max(0.0, effect.modulate.a - amount)
				effect.modulate.a = new_alpha
				if new_alpha <= 0.1:
					effect.visible = false
					
func reduce_all_effects(power: float):
	for i in range(1, 6):
		var effect_name = "intensidad_" + str(i)
		if has_node(effect_name):
			var effect = get_node(effect_name)
			var new_alpha = max(0.0, effect.modulate.a - power)
			effect.modulate.a = new_alpha
			if new_alpha <= 0.1:
				effect.visible = false
				
func show_wall_message(planks_needed: int):
	if wall_message_label and wall_message_timer:
		var message: String
		if planks_needed > 0:
			message = "Faltan " + str(planks_needed) + " tablones para abrir el camino."
		else:
			message = "¡Camino despejado!" # Esto no debería pasar, pero es una seguridad
	
		wall_message_label.text = message
		wall_message_label.visible = true
		wall_message_timer.start()

func _on_wall_message_timer_timeout() -> void:
	if wall_message_label:
		var tween = create_tween()
		tween.tween_property(wall_message_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): 
			wall_message_label.visible = false
			wall_message_label.modulate.a = 1.0
)
