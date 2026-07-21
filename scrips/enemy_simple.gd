extends CharacterBody2D

@export var speed: float = 50.0
@export var gravity: int = 1200

@onready var animated_sprite = $AnimatedSprite2D
@onready var floor_ray = $raycast_floor_detection
@onready var wall_ray = $raycast_wall_detection
@onready var damage_zone = $damage_zone
@onready var hurt_area = $damage_bodyEnemy
@onready var stomp_timer = $stomp_cooldown_timer
@onready var damage_cooldown_timer = $damage_cooldown_timer
@onready var visibility_notifier = $VisibleOnScreenNotifier2D
@onready var idle_timer = $IdleTimer

var is_dead: bool = false
var players_in_damage_zone: Array = []  # lista de jugadores en el area
var is_visible_on_screen: bool = false  # control de visibilidad
var last_wall_collision: Object = null
var is_in_word_20: bool = false

#ESTADO Y VARIABLES DE SPAWN
const WORLD_LAYER = 1
const SPAWN_LAYER = 2
const ENEMY_LAYER = 3
enum EnemyState {SPAWNING, IDLE, WALKING, DEAD}
var current_state: EnemyState = EnemyState.SPAWNING
var target_y_position: float = 0.0
@export var spawn_offset_y: float = 8.0 
@export var spawn_rise_speed: float = -20.0

func _ready() -> void:
	velocity.x = 0
	current_state = EnemyState.SPAWNING
	enable_spawning_mode()
	#velocity.x = speed
	floor_ray.position.x = 10
	wall_ray.target_position.x = 10
	
	# Verificar si el nivel actual es word_20
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "word_20":
		is_in_word_20 = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if !is_in_word_20 && !is_visible_on_screen && current_state == EnemyState.WALKING:
		velocity = Vector2.ZERO
		update_animation()
		return
	
	match current_state:
		EnemyState.DEAD:
			return
			
		EnemyState.SPAWNING:
			handle_spawning(delta)
		EnemyState.IDLE:
			handle_idle(delta)
		EnemyState.WALKING:
			handle_walking(delta)
	move_and_slide()
	update_animation()
	
func flip_direction():
	if wall_ray.is_colliding():
		var collider = wall_ray.get_collider()
		if collider and collider.is_in_group("enemies"):
			# Ignorar colisión con otros enemigos
			pass
	
	velocity.x *= -1
	floor_ray.position.x *= -1
	wall_ray.target_position.x *= -1
	animated_sprite.flip_h = velocity.x < 0
	last_wall_collision = null
	
func update_animation():
	if current_state == EnemyState.WALKING and is_visible_on_screen:
		animated_sprite.play("run")
	elif current_state == EnemyState.SPAWNING and is_visible_on_screen:
		animated_sprite.play("reposo") 
	elif current_state == EnemyState.IDLE and is_visible_on_screen:
		animated_sprite.play("idle")
	else:
		animated_sprite.stop()
	
func die():
	is_dead = true
	
	damage_zone.set_deferred("monitoring", false)
	hurt_area.set_deferred("monitoring", false)
	
	velocity.x = 0
	velocity.y = -300
	move_and_slide()
	
	animated_sprite.modulate = Color.RED
	
	await get_tree().create_timer(0.1).timeout
	queue_free()
	
	var spawners = get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		if spawner.has_method("notify_enemy_died"):
			spawner.notify_enemy_died()
	
func _on_stomp_cooldown_timer_timeout() -> void:
	damage_zone.set_deferred("monitoring", true)
	print("area de stomp reactivada")
	
func _on_damage_zone_body_entered(body: Node2D) -> void:
	if not is_dead and body.is_in_group("player"):
		die()
		if body.has_method("bounce"):
			body.bounce()
			
func _on_damage_body_enemy_body_entered(body: Node2D) -> void:
	if not is_dead and body.is_in_group("player") and body.has_method("take_damage"):
		var damage_amount = calculate_damage(body)
		body.take_damage(damage_amount)
		damage_zone.set_deferred("monitoring", false)
		stomp_timer.start()
		
		if is_in_word_20:
			var music_area = get_tree().get_first_node_in_group("music_area")
			if music_area and music_area.has_method("apply_cold_burst"):
				music_area.apply_cold_burst(4.0, 5.0)
		
		# añadir jugador a la lista y iniciar timer si es el primero
		if not players_in_damage_zone.has(body):
			players_in_damage_zone.append(body)
			if damage_cooldown_timer.is_stopped():
				damage_cooldown_timer.start()

func _on_damage_body_enemy_body_exited(body: Node2D) -> void:
	if players_in_damage_zone.has(body):
		players_in_damage_zone.erase(body)
		# detener el timer si no hay jugadores en el area
		if players_in_damage_zone.is_empty():
			damage_cooldown_timer.stop()

func _on_damage_cooldown_timer_timeout() -> void:
	# aplicar daño a todos los jugadores en el area cada segundo
	for player in players_in_damage_zone:
		if is_instance_valid(player) and player.has_method("take_damage"):
			var damage_amount = calculate_damage(player)
			player.take_damage(damage_amount)

func calculate_damage(player: Node2D) -> int:
	var base_damage = 10  # daño normal
	var critical_damage = 5  # daño cuando vida ≤ 20
	var player_health: int = 0
	
	if player.has_method("get_health"):
		player_health = player.get_health()
	if is_in_word_20 and player_health > 0 and player_health <= 5:
		return 1
	if player_health <= 20:
		return critical_damage
	return base_damage

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	is_visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	is_visible_on_screen = false
	
func handle_door_destroyed(door: Node):
	if last_wall_collision == door:
		last_wall_collision = null
		if velocity.x == 0:
			velocity.x = speed if not animated_sprite.flip_h else -speed
			
func follow_player(_delta: float):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		velocity.x = direction_to_player * speed
		animated_sprite.flip_h = velocity.x < 0
		
func handle_walking(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	if is_in_word_20:
		follow_player(delta)
	else:
		if wall_ray.is_colliding():
			var collider = wall_ray.get_collider()
			if collider and (collider.is_in_group("player") or collider.is_in_group("enemies")):
				current_state = EnemyState.IDLE 
				velocity.x = 0
			elif wall_ray.get_collider() != last_wall_collision:
				flip_direction()
		if not floor_ray.is_colliding() and current_state == EnemyState.WALKING:
			flip_direction()

func handle_spawning(_delta: float):
	velocity.y = spawn_rise_speed
	velocity.x = 0
	
	if floor_ray.is_colliding():
		if target_y_position == 0.0:
			var collision_point_y = floor_ray.get_collision_point().y
			var enemy_half_height = $CollisionShape2D.shape.size.y / 2.0
			target_y_position = collision_point_y - enemy_half_height - spawn_offset_y
			
		if global_position.y <= target_y_position:
			global_position.y = target_y_position 
			current_state = EnemyState.IDLE
			enable_idle_mode()
			velocity = Vector2.ZERO
			idle_timer.start(2.0)
			target_y_position = 0.0
	
func enable_idle_mode():
	# CAPAS
	set_collision_layer_value(WORLD_LAYER, true) # Vuelve a capa del mundo
	set_collision_layer_value(SPAWN_LAYER, false)
	set_collision_layer_value(ENEMY_LAYER, true)
	
	# MASCARAS
	set_collision_mask_value(WORLD_LAYER, true)  # SÍ choca con el suelo
	set_collision_mask_value(SPAWN_LAYER, false)
	set_collision_mask_value(ENEMY_LAYER, false) # NO choca con otros enemigos

func enable_spawning_mode():
	set_collision_layer_value(WORLD_LAYER, false) # No visible en la capa del mundo
	set_collision_layer_value(SPAWN_LAYER, true)  # Visible en la capa de spawn
	set_collision_layer_value(ENEMY_LAYER, true)  # Visible para otros enemigos (si lo buscan)
	
	# MASCARAS
	set_collision_mask_value(WORLD_LAYER, false) # NO choca con el suelo (para atravesarlo)
	set_collision_mask_value(SPAWN_LAYER, false) # No choca con otros objetos de spawn
	set_collision_mask_value(ENEMY_LAYER, false) # NO choca con otros enemigos (para traspasarse)

func enable_walking_mode():
	# CAPAS
	set_collision_layer_value(WORLD_LAYER, true)
	set_collision_layer_value(SPAWN_LAYER, false)
	set_collision_layer_value(ENEMY_LAYER, true)
	
	# MASCARAS
	set_collision_mask_value(WORLD_LAYER, true)  # SÍ choca con el suelo
	set_collision_mask_value(SPAWN_LAYER, false)
	set_collision_mask_value(ENEMY_LAYER, true)  # SÍ choca con otros enemigos
	
func handle_idle(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	velocity.x = 0
	if idle_timer.is_stopped():
		var is_blocked = false
		if wall_ray.is_colliding():
			var collider = wall_ray.get_collider()
			if collider and (collider.is_in_group("player") or collider.is_in_group("enemies")):
				is_blocked = true
		if !is_blocked:
			current_state = EnemyState.WALKING
			velocity.x = speed if !animated_sprite.flip_h else -speed

func _on_idle_timer_timeout() -> void:
	enable_walking_mode()
	current_state = EnemyState.WALKING
	if animated_sprite.flip_h:
		velocity.x = -speed
	else:
		velocity.x = speed
