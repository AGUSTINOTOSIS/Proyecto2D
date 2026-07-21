extends Area2D

@export var victory_screen: PackedScene # Escena UI de victoria
@export var victory_sound: AudioStream

@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if !victory_screen:
		push_warning("No se asignó victory_screen en el inspector")
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("¡Trofeo recolectado!")
		
		#Detener el tiempo
		stop_game_timer()
		
		#Silenciar todas las músicas
		silence_all_music()
		
		#LLAMADA PARA CONGELAR EL SISTEMA DE FRÍO
		freeze_cold_system()
		
		#Detener el shake de la cámara
		stop_camera_shake(body)
		
		#reproducir sonido
		if audio_player and victory_sound:
			audio_player.stream = victory_sound
			audio_player.play()
		
		# Muestra la pantalla de victoria
		if victory_screen:
			var victory_ui = victory_screen.instantiate()
			get_tree().root.add_child(victory_ui)
			
			if body.has_method("set_block_player"):
				body.set_block_player(true)
			
		# Desactivar trofeo
		collision_shape.set_deferred("disabled", true)
		visible = false

func silence_all_music():
	# Silenciar música de fondo del nivel
	var bg_music = get_node("../audio_fondo")
	if bg_music:
		var tween_bg = create_tween()
		tween_bg.tween_property(bg_music, "volume_db", -80.0, 1.0)
		
	# Silenciar todas las radios activas
	var radios = get_tree().get_nodes_in_group("radio")
	for radio in radios:
		if radio.audio_player.playing:
			var tween_radio = create_tween()
			tween_radio.tween_property(radio.audio_player, "volume_db", -80.0, 1.0)
			
	# Silenciar música de emergencia (tiempo)
	var ui = get_node("../UI")
	if ui and ui.has_node("emergencia"):
		var emergency_music = ui.get_node("emergencia")
		var tween_emergency = create_tween()
		tween_emergency.tween_property(emergency_music, "volume_db", -80.0, 1.0)
	
func stop_game_timer():
	var ui = get_node("../UI")
	if ui and ui.has_method("stop_timer"):
		ui.stop_timer()
		
func stop_camera_shake(player):
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("stop_shake"):
			camera.stop_shake()

func freeze_cold_system():
	var music_areas = get_tree().get_nodes_in_group("music_area")
	for area in music_areas:
		if area.has_method("freeze_cold_system"):
			area.freeze_cold_system()
