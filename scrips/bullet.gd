extends Area2D

@export var speed: float = 300.0
@export var damage: int = 5
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configurar timer de autodestrucción
	$Timer.wait_time = lifetime
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Movimiento del proyectil
	global_position += direction * speed * delta
		

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		await play_impact_sound()
		queue_free() # Destruir el proyectil al impactar
	elif body is TileMapLayer:
		queue_free()

func _on_timer_timeout() -> void:
	queue_free() # Destruir el proyectil si no golpea nada
	
func initialize(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	# para otrso objhetos que tambien la bala pueda chocar
	if area.is_in_group("destructible"):
		queue_free()
		
func play_impact_sound():
	if has_node("ImpactSound"):
		$ImpactSound.play()
		await $ImpactSound.finished
