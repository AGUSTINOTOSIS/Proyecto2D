extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var e_prompt = $EPrompt
@onready var progress_sprite = $ProgressSprite
@onready var construction_timer = $ConstructionTimer
@onready var main_sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var damage_timer = $DamageTimer #timer para daño
@onready var shake_timer = $ShakeTimer #para efecto de temblor
@onready var enemy_detection_area = $EnemyDetectionArea

var player_near: bool = false
var construction_progress: int = 0
var max_progress: int = 5
var is_constructed: bool = false
var wood_required_per_press: int = 2
var health: int = 10
var max_health: int = 10
var enemies_colliding: Array = [] #lista de enemigos colisionando
var is_shaking: bool = false
var original_position: Vector2

func _ready() -> void:
	main_sprite.visible = false
	e_prompt.visible = false
	progress_sprite.visible = false
	original_position = main_sprite.position
	collision_shape.set_deferred("disabled", true)
	enemy_detection_area.set_deferred("monitoring", false)

func _process(_delta: float) -> void:
	if player_near and not is_constructed and Input.is_action_just_pressed("interact_radio"):
		try_advance_construction()
		
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_constructed:
		player_near = true
		e_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		e_prompt.visible = false
		construction_timer.stop()
		
func try_advance_construction():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("has_wood"):
		if ui.has_wood(wood_required_per_press):
			ui.use_wood(wood_required_per_press)
			advance_construction()
		else:
			print("No tienes suficiente madera")

func advance_construction():
	construction_progress += 1
	construction_timer.start()
	
	e_prompt.visible = false
	progress_sprite.visible = true
	
	if progress_sprite:
		progress_sprite.frame = construction_progress - 1
		
	if construction_progress >= max_progress:
		complete_construction()
		
func complete_construction():
	is_constructed = true
	construction_timer.stop()
	
	e_prompt.visible = false
	progress_sprite.visible = false
	main_sprite.visible = true
	health = max_health #restablecer vida
	
	damage_timer.wait_time = 2.0
	shake_timer.wait_time = 0.1
	collision_shape.set_deferred("disabled", false)
	enemy_detection_area.set_deferred("monitoring", true)
	
func _on_construction_timer_timeout() -> void:
	if not is_constructed:
		construction_progress = 0
		progress_sprite.visible = false
		
		if player_near:
			e_prompt.visible = true
			
func take_damage(amount: int = 1):
	if not is_constructed:
		return
	health -= amount
	if health <= 0:
		destroy_door()
	else:
		start_shake()
		
func start_shake():
	if is_shaking:
		return
	is_shaking = true
	shake_timer.start()
	var shake_intensity = 3.0
	for i in range(3):
		main_sprite.position = original_position + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		await get_tree().create_timer(0.05).timeout
	main_sprite.position = original_position
	is_shaking = false

func destroy_door():
	is_constructed = false
	construction_progress = 0
	main_sprite.visible = false
	progress_sprite.visible = false
	e_prompt.visible = false
	
	collision_shape.set_deferred("disabled", true)
	enemy_detection_area.set_deferred("monitoring", false)
	
	for enemy in enemies_colliding:
		if is_instance_valid(enemy):
			var push_direction = sign(enemy.velocity.x)
			if push_direction == 0:
				push_direction = 1 if randf() > 0.5 else -1
			enemy.position.x += 10 * push_direction
			enemy.handle_door_destroyed(self)
	#reinicia la vida
	health = max_health
	damage_timer.stop()
	construction_timer.stop()
	#limpiar lista de enemigos
	#for enemy in enemies_colliding:
		#enemy.handle_door_destroyed(self)
	enemies_colliding.clear()
	
	if player_near:
		e_prompt.visible = true
	
func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and is_constructed:
		if not enemies_colliding.has(body):
			enemies_colliding.append(body)
			body.last_wall_collision = self
			if enemies_colliding.size() == 1:
				damage_timer.start()
				
func _on_enemy_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies") and enemies_colliding.has(body):
		enemies_colliding.erase(body)
		if enemies_colliding.is_empty():
			damage_timer.stop()
			
func _on_damage_timer_timeout() -> void:
	if is_constructed and enemies_colliding.size() > 0:
		take_damage(1)
