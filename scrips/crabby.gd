extends CharacterBody2D

@export var speed: float = 50.0
@export var gravity: int = 1200

@onready var animated_sprite = $AnimatedSprite2D
@onready var stop_timer = $StopTimer
@onready var interaction_area = $InteractionArea
@onready var e_prompt = $ELight
@onready var interaction_cooldown_timer = $TimerInteraccion
@onready var walk_sound_player = $WalkSoundPlayer
@onready var give_wood_sound_player = $GiveWoodSoundPlayer

var is_moving: bool = true
var direction: int = 1
var is_stopped: bool = false
var stop_zones: Array = []  # se guardan las zonas de parada
var ignored_zones: Array = []  # zonas que actualmente esta afectando al cangrejo
var player_in_range: bool = false
var wood_given: bool = false  # para evitar dar madera multiples veces
var interaction_ready: bool = true  # controla si se puede interactuar
var last_activated_zone: Area2D = null  # ultima zona que activo la parada

func _ready() -> void:
	stop_timer.one_shot = true
	stop_timer.wait_time = 5.0
	velocity.x = speed * direction
	
	# configura timer de cooldown
	if interaction_cooldown_timer:
		interaction_cooldown_timer.one_shot = true
		interaction_cooldown_timer.wait_time = 3.0
	
	stop_zones = get_tree().get_nodes_in_group("stop_zones")
	print("Zonas de parada encontradas: ", stop_zones.size())
		
	
	if e_prompt:
		e_prompt.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	if not is_stopped:
		check_stop_zones()
		
	if (player_in_range and Input.is_action_just_pressed("interact_radio")
		and not wood_given and is_stopped and interaction_ready):
			give_wood_to_player()
		
	if is_moving and not is_stopped:
		velocity.x = speed * direction
	else:
		velocity.x = 0
		
	move_and_slide()
	update_animation()
	update_prompt_visibility()
	
func update_prompt_visibility():
	if e_prompt:
		e_prompt.visible = (player_in_range and is_stopped and interaction_ready and not wood_given)
		
	
func check_stop_zones():
	for zone in stop_zones:
		if zone is Area2D and zone not in ignored_zones:
			#verifica si el cangrejo esta dentro del area
			var bodies = zone.get_overlapping_bodies()
			if bodies.has(self):
				last_activated_zone = zone
				ignored_zones.append(zone)
				stop_and_wait()
				break # salir del loop una vez encontrada una zona
				
func check_zone_exit():
	# verifica si se salio de la zona que nos detuvo
	if last_activated_zone:
		var bodies = last_activated_zone.get_overlapping_bodies()
		if not bodies.has(self):
			await get_tree().create_timer(0.5).timeout
			if last_activated_zone in ignored_zones:
				ignored_zones.erase(last_activated_zone)
			last_activated_zone = null
	
func update_animation():
	if is_stopped:
		animated_sprite.play("idle")
		if walk_sound_player.playing:
			walk_sound_player.stop()  # Detener el sonido si está detenido
	elif is_moving:
		animated_sprite.play("run")
		if not walk_sound_player.playing:
			walk_sound_player.play()  # Reproducir el sonido si está caminando
		# se gira el sprite segun la dirección
	animated_sprite.flip_h = direction < 0
	
func stop_and_wait():
	is_stopped = true
	is_moving = false
	stop_timer.start()
	print("Cangrejo detenido por 30 segundos")
	
func resume_movement():
	is_stopped = false
	is_moving = true
	direction *= -1  # cambiar dirección
	velocity.x = speed * direction
	
	wood_given = false
	interaction_ready = true
	
	# esperar un poco antes de poder reactivar la misma zona
	await get_tree().create_timer(1.0).timeout
	if last_activated_zone in ignored_zones:
		ignored_zones.erase(last_activated_zone)
	last_activated_zone = null
	
func _on_stop_timer_timeout() -> void:
	resume_movement()
	
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if e_prompt:
			e_prompt.visible = false
		
func give_wood_to_player():
	wood_given = true
	interaction_ready = false
	print("¡+60 de madera! Cooldown de 3 segundos iniciado")
	
	# Reproducir sonido de dar madera
	if give_wood_sound_player:
		give_wood_sound_player.play()
	
	if interaction_cooldown_timer:
		interaction_cooldown_timer.start()
	
	var ui = get_node("../UI")
	if ui and ui.has_method("add_wood"):
		ui.add_wood(60)
	else:
		print("Error: No se encontró la UI o no tiene el metodo add_wood")

func _on_timer_interaccion_timeout() -> void:
	interaction_ready = true
	print("Cooldown terminado - listo para interactuar de nuevo")
	if player_in_range and is_stopped:
		if e_prompt:
			e_prompt.visible = true
