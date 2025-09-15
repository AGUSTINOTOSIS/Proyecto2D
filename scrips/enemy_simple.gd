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

var is_dead: bool = false
var players_in_damage_zone: Array = []  # lista de jugadores en el area
var is_visible_on_screen: bool = false  # control de visibilidad
var last_wall_collision: Object = null

func _ready() -> void:
	velocity.x = speed
	floor_ray.position.x = 10
	wall_ray.target_position.x = 10

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
# solo procesar movimiento si está visible en pantalla
	if not is_visible_on_screen:
		return
		
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	if last_wall_collision and not is_instance_valid(last_wall_collision):
		flip_direction()
		last_wall_collision = null
		
	if not floor_ray.is_colliding() or (wall_ray.is_colliding() and wall_ray.get_collider() != last_wall_collision):
		flip_direction()
		
	move_and_slide()
	update_animation()
	
func flip_direction():
	velocity.x *= -1
	floor_ray.position.x *= -1
	wall_ray.target_position.x *= -1
	animated_sprite.flip_h = velocity.x < 0
	last_wall_collision = null
	
func update_animation():
	if is_visible_on_screen:
		animated_sprite.play("run")
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
			print("daño continuo aplicado: ", damage_amount)
		

func calculate_damage(player: Node2D) -> int:
	var base_damage = 10  # daño normal
	var critical_damage = 5  # daño cuando vida ≤ 20
	
	if player.has_method("get_health"):
		var player_health = player.get_health()
		if player_health <= 20:
			print("¡daño crítico! Jugador con poca vida: ", player_health)
			return critical_damage
	return base_damage
		


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	is_visible_on_screen = true
	print("enemigo visible - Activando movimiento")


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	is_visible_on_screen = false
	print("enemigo no visible - Pausando movimiento")
	
func handle_door_destroyed(door: Node):
	if last_wall_collision == door:
		flip_direction()
		print("Puerta destruida - Cambiando dirección")
