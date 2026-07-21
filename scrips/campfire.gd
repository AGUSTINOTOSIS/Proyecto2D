extends Area2D

@onready var interaction_area = $InteractionArea
@onready var e_prompt = $EPrompt
@onready var progress_sprite = $ProgressSprite
@onready var construction_timer = $ConstructionTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var durability_timer = $DurabilityTimer
@onready var build_sound_player = $BuildSoundPlayer
@onready var complete_sound_player = $CompleteSoundPlayer
@onready var extinguish_sound_player = $ExtinguishSoundPlayer
@onready var fire_sound_player = $FireSoundPlayer
@onready var fire_ready_player = $Fire_ready
@onready var warming_timer = $WarmingTimer

var player_in_bonfire: bool = false
var player_near: bool = false
var reduction_power: float = 0.5
var construction_progress: int = 0
var max_progress: int = 8  # 8 presiones de E
var is_constructed: bool = false
var wood_required_per_press: int = 2  # 2 madera por cada E
var is_player_warmed: bool = false
var reconstruction_count: int = 0

var auto_build_timer: float = 0.0
var auto_build_interval: float = 0.1 # Intervalo de construcción automática
var is_auto_building: bool = false

enum DurabilityType {NORMAL, SHORT, VERY_SHORT}
var current_durability_type: DurabilityType
var durability_probabilities = {
	DurabilityType.NORMAL: 0.75,      # 75% - 80 segundos
	DurabilityType.SHORT: 0.20,       # 20% - 50 segundos  
	DurabilityType.VERY_SHORT: 0.05   # 5% - 5 segundos
}
var durability_times = {
	DurabilityType.NORMAL: 80.0,      # 1 minuto 20 segundos
	DurabilityType.SHORT: 50.0,       # 50 segundos
	DurabilityType.VERY_SHORT: 5.0    # 5 segundos
}

func _ready() -> void:
	if has_node("WarmingTimer"):
		warming_timer.wait_time = 3.0
		warming_timer.one_shot = true
	
	# Inicializar estado de construcción
	animated_sprite.play("no_fire")
	e_prompt.visible = false
	progress_sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	
func _process(delta: float) -> void:
	if player_near and not is_constructed:
		if Input.is_action_just_pressed("interact_radio"):
			# Construcción manual (un toque)
			try_advance_construction()
			auto_build_timer = 0.0
			is_auto_building = false
			
		elif Input.is_action_pressed("interact_radio"):
			# Construcción automática (mantener pulsado)
			is_auto_building = true
			auto_build_timer += delta
			if auto_build_timer >= auto_build_interval:
				auto_build_timer = 0.0
				try_advance_construction()
		
		elif Input.is_action_just_released("interact_radio") or not Input.is_action_pressed("interact_radio"):
			# Si se suelta la tecla o se deja de presionar, solo deten el progreso
			auto_build_timer = 0.0
			is_auto_building = false
			if construction_progress > 0:
				if build_sound_player:
					build_sound_player.stop()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_constructed:
		player_in_bonfire = true
		
		if warming_timer:
			warming_timer.start()
		
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("set_bonfire_state"):
			music_area.set_bonfire_state(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_constructed:
		player_in_bonfire = false
		
		if warming_timer and not warming_timer.is_stopped():
			warming_timer.stop()
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("set_bonfire_state"):
			music_area.set_bonfire_state(false)
		is_player_warmed = false
			
func apply_immediate_reduction():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var tween = create_tween()
		tween.tween_property(player, "modulate", Color(1, 1, 1, 1), 0.5)
		if player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			if camera.has_method("stop_shake"):
				camera.stop_shake()
				
func apply_bonfire_effects():
	if not is_constructed:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.modulate.r < 0.9:
			player.modulate = player.modulate.lerp(Color(1, 1, 1, 1), 0.1)
			
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if not is_constructed:
			e_prompt.visible = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		e_prompt.visible = false
		# Resetear estado visual/automático si no esta completa
		if not is_constructed:
			construction_timer.stop()
			progress_sprite.visible = false
			auto_build_timer = 0.0
			is_auto_building = false
			if build_sound_player:
				build_sound_player.stop()
			
			
func try_advance_construction():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("has_wood"):
		var wood_cost = wood_required_per_press
		if is_constructed == false and construction_progress == max_progress - 1:
			wood_cost += reconstruction_count
		
		if ui.has_wood(wood_cost):
			ui.use_wood(wood_cost)
			advance_construction()
			construction_timer.start()
		else:
			print("No tienes suficiente madera. Necesitas ", wood_cost, " madera")
		
func advance_construction():
	construction_progress += 1
	construction_timer.start()
	
	e_prompt.visible = false
	progress_sprite.visible = true
	
	# Reproducir sonido de construcción
	if build_sound_player:
		build_sound_player.play()
	
	if progress_sprite:
		progress_sprite.frame = construction_progress - 1
	if construction_progress >= max_progress:
		complete_construction()

func complete_construction():
	is_constructed = true
	construction_timer.stop()
	
	e_prompt.visible = false
	progress_sprite.visible = false
	
	#determinar durabilidad aleatoria
	determine_durability()
	
	var selected_durability = durability_times[current_durability_type]
	durability_timer.wait_time = selected_durability
	durability_timer.start()
	
	# Activar fogata
	animated_sprite.play("fire")
	collision_shape.set_deferred("disabled", false)
	durability_timer.start()
	
	# Reproducir sonido de fogata construida, fuego listo y fuego continuo
	if complete_sound_player:
		complete_sound_player.play()
	if fire_ready_player:
		fire_ready_player.play()
	if fire_sound_player:
		fire_sound_player.play()
		
	#mostrar mensaje segun el tipo de durabilidad
	show_durability_message()
	print("¡Fogata construida! Durabilidad: ", selected_durability, " segundos")

func reset_bonfire():
	is_constructed = false
	construction_progress = 0
	animated_sprite.play("no_fire")
	collision_shape.set_deferred("disabled", true)
	durability_timer.stop()
	is_player_warmed = false
	
	if warming_timer and not warming_timer.is_stopped():
		warming_timer.stop()
	
	# Detener sonido de fuego
	if fire_sound_player and fire_sound_player.playing:
		fire_sound_player.stop()
	
	# Reproducir sonido de fogata apagada
	if extinguish_sound_player:
		extinguish_sound_player.play()
	
	if player_in_bonfire:
		player_in_bonfire = false
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("set_bonfire_state"):
			music_area.set_bonfire_state(false)
	
	if player_near:
		e_prompt.visible = true
	reconstruction_count += 1
	print("Fogata se ha consumido. ser reconstruida.")

func _on_construction_timer_timeout() -> void:
	if not is_constructed:
		progress_sprite.visible = false
		if player_near:
			e_prompt.visible = true

func _on_durability_timer_timeout() -> void:
	if is_constructed:
		reset_bonfire()
		
func determine_durability():
	var random_value = randf()  # numero aleatorio entre 0.0 y 1.0
	var cumulative_probability = 0.0
	
	for durability_type in durability_probabilities:
		cumulative_probability += durability_probabilities[durability_type]
		if random_value <= cumulative_probability:
			current_durability_type = durability_type
			return
	
	current_durability_type = DurabilityType.NORMAL
	
func show_durability_message():
	var messages = {
		DurabilityType.NORMAL: "¡Fogata construida! Duradero (80 segundos)",
		DurabilityType.SHORT: "¡Fogata construida! Poco duradero (50 segundos)",
		DurabilityType.VERY_SHORT: "¡Fogata construida! Muy frágil (5 segundos)"
	}
	
	var _times = {
		DurabilityType.NORMAL: 80.0,
		DurabilityType.SHORT: 50.0,
		DurabilityType.VERY_SHORT: 5.0
	}
	print(messages[current_durability_type])

func _on_warming_timer_timeout() -> void:
	is_player_warmed = true
	apply_immediate_reduction()
