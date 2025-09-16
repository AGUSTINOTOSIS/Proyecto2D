extends CharacterBody2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_remaining: float = 0.0


var SPEED : float = 300.0
const JUMP_VELOCITY : float = -400.0

var health : int = 100
var fruitCount : int = 0
var allow_animation : bool = false
var leave_floor : bool = false
var had_jump : bool = false
var max_jump : int = 2
var count_jump : int = 0
var double_jump : bool = false
var raycast_dimension = 10.5
var direction
var stuck_on_wall : bool = false
var block_player : bool = false
var block_movement := false

var is_frozen: bool = false
var freeze_timer: float = 0.0
var original_speed: float = SPEED
var freeze_speed: float = SPEED * 0.5
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$raycast_walljump.target_position.x = raycast_dimension
	$animaciones.play("appearing")
	
	modulate = Color(1, 1, 1, 1)

func _physics_process(delta):
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
			SPEED = original_speed
			var ui = get_node("../UI")
			if ui and ui.has_method("hide_freeze_effect"):
				ui.hide_freeze_effect()
	if shake_remaining != 0:
		if shake_duration > 0:
			shake_remaining = max(0, shake_remaining - delta)
			$Camera2D.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity) * (shake_remaining / shake_duration),
				randf_range(-shake_intensity, shake_intensity) * (shake_remaining / shake_duration)
			)
		else:
			$Camera2D.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
	
	if block_movement:
		return
	
	if block_player : return;
	
	if is_on_floor():
		leave_floor = false
		had_jump = false
		count_jump = 0
	
	# Add the gravity.
	if not is_on_floor():
		if not leave_floor:
			$right_timer.start()
			leave_floor = true
		velocity.y += gravity * delta


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and right_to_jump():
		if count_jump == 1:
			double_jump = true
			$doublejump.play()
		else:
			$jump.play()
		count_jump += 1
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis ("move_left", "move_right") + Input.get_axis("ui_left", "ui_right")
	direction = clamp(direction, -1.0, 1.0) #evita que se sumen las velocidades si se intenta apretar ambas teclas(ej: A + felcha izquierda)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if $raycast_walljump.get_collider():
		if $raycast_walljump.get_collider().is_in_group("wall_jump"):
			if velocity.y > 0:
				count_jump = 0
				velocity.y = 0
				stuck_on_wall = true
		else:
			stuck_on_wall = false
	else:
		stuck_on_wall = false
	move_and_slide()
	decide_animation()
	
func decide_animation():

	if direction < 0:
		$animaciones.flip_h = true
		$raycast_walljump.target_position.x = -raycast_dimension
	elif direction > 0:
		$animaciones.flip_h = false
		$raycast_walljump.target_position.x = raycast_dimension
		
	if double_jump:
		double_jump = false
		allow_animation = false
		$animaciones.play("double jump")
	
	if not allow_animation : return
	#eje de las x
	if stuck_on_wall:
		$animaciones.play("wall jump")
	else:
		if velocity.x == 0:
			$animaciones.play("idle")
		elif velocity.x < 0:
			$animaciones.play("run")
		elif velocity.x > 0:
			$animaciones.play("run")
		
	if velocity.y < 0:
		$animaciones.play("jump")
	elif velocity.y > 0:
		$animaciones.play("fall")
		
func right_to_jump():
	if had_jump: 
		if count_jump < max_jump: return true
		else: return false
	if is_on_floor() || stuck_on_wall:
		had_jump = true
		return true
	elif not $right_timer.is_stopped(): 
		had_jump = true
		return true
		
func collectfruit(fruitType):
	var auxstring = fruitType + "points"
	var gainedpoints = GeneralRules[auxstring]
	fruitCount += gainedpoints
	health = min(health + 5, 100) #cura 5HP sin pasarse de 100
	print("Frutas:", fruitCount, " - Salud:", health)
	

func _on_animaciones_animation_finished():
		allow_animation = true

func _on_right_timer_timeout():
	pass

func _on_damage_detection_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index):
	$damage.play()
	allow_animation = false
	velocity.y = -150
	$animaciones.play("hit")
	health -= 10
	print(health)
	print("daño")
	
func take_damage(amount: int = 10):
	$damage.play()
	allow_animation = false
	velocity.y = -150
	$animaciones.play("hit")
	health -= amount
	print(health)
	print("daño:", amount)
	
	if health <= 0:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/UIs/game_over.tscn")
	var ui = get_node("../UI")
	if ui and ui.has_method("flash_damage"):
		ui.flash_damage()
		
func set_block_player(block: bool):
	block_movement = block
	if block:
		$animaciones.play("idle")
		
func get_health() -> int:
	return health
	
func start_shake(intensity: float = 1.0, duration: float = -1.0):
	shake_intensity = intensity
	if duration > 0:
		shake_duration = duration
		shake_remaining = duration
	else:
		shake_duration = -1
		shake_remaining = -1
	
func stop_shake():
	shake_remaining = 0
	$Camera2D.offset = Vector2.ZERO
	
func apply_freeze(duration: float):
	print("APPLY FREEZE!, ", duration)
	if not is_frozen:
		is_frozen = true
		freeze_timer = duration
		SPEED = freeze_speed
	else:
		freeze_timer = max(freeze_timer, duration)
	var ui = get_node("../UI")
	if ui and ui.has_method("show_freeze_effect"):
		ui.show_freeze_effect(freeze_timer)
		
func apply_fade_effect(target_alpha: float, duration: float = 3.0):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, duration)

func reset_appearance():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)
	
