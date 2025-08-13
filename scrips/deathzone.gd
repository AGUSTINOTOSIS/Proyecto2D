extends Area2D

#parametros configurables
@export var respawn_point := Vector2(341, 177)
@export var damage := 50
@export var shake_intensity := 25 # para efescto de pantalla
@export var shake_duration := 0.1 # el tiempo que dura

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		#hacer daño y respawn
		body.take_damage(damage)
		body.global_position = respawn_point
		#efecto visual
		_play_effects(body)

func _play_effects(player):
	#sonido
	if has_node("drop_sound"):
		$drop_sound.play()
	
	#sacudida de camara
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("shake_screen"):
			camera.shake_screen(shake_intensity, shake_duration)
			
