extends Area2D

@export var speed: float = 250.0
@export var damage: int = 3
@export var lifetime: float = 4.0
@export var freeze_duration: float = 6.0

var direction: Vector2 = Vector2.RIGHT
var has_hit: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = lifetime
	$Timer.start()
	# Reproducir animación de disparo inicial
	play_shot_animation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not has_hit:  # Solo moverse si no ha impactado
		global_position += direction * speed * delta
	
func _on_body_entered(body: Node2D) -> void:
	if has_hit:  # Evitar múltiples impactos
		return
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		apply_freeze_effect(body)
		play_bang_animation(true)  # Animación de impacto
		await get_tree().create_timer(0.5).timeout  # Esperar animación
		queue_free()
	elif body is TileMapLayer:
		play_bang_animation(false)  # Animación de impacto
		await get_tree().create_timer(0.5).timeout  # Esperar animación
		queue_free()
		
func _on_timer_timeout() -> void:
	if not has_hit:  # Solo si no ha impactado
		play_nothing_animation()  # Animación de desvanecimiento
		await get_tree().create_timer(0.5).timeout  # Esperar animación
		queue_free()
		
func initialize(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	
func apply_freeze_effect(player: Node2D):
	if player.has_method("apply_freeze"):
		player.apply_freeze(freeze_duration)
		
func play_shot_animation():
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("shot")
		
func play_bang_animation(play_sound: bool = true):
	has_hit = true  # Marcar que impactó
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("bang")
		if play_sound:
			play_impact_sound()
		await $AnimatedSprite2D.animation_finished
		
func play_nothing_animation():
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("nothing")
		await $AnimatedSprite2D.animation_finished
		
func play_impact_sound():
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()
	
