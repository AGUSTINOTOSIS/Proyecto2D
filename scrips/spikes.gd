extends Area2D

@export var normal_damage := 5
@export var low_health_damage := 1
@export var low_health_threshold := 10
@export var flash_duration := 0.3  # Duración del efecto visual en segundos

@onready var flash_timer = $flashtimer

func _ready() -> void:
	body_entered.connect(_on_body_entered, CONNECT_REFERENCE_COUNTED)

func _on_body_entered(body: Node2D) -> void:
	if not (body.has_method("take_damage") and body.has_method("get_health")):
		return
		
	var current_health = body.get_health()
	var damage = low_health_damage if current_health <= low_health_threshold else normal_damage
	body.take_damage(damage)
	modulate = Color.RED  # Feedback visual
	$flashtimer.start(flash_duration)

func _on_flashtimer_timeout() -> void:
	modulate = Color.WHITE
