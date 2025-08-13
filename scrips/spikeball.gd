extends Node2D
#el tamaño de los anillos es de 6 pixeles
var floorDetected : bool = false
var raycast_value : int = 36 #pixeles iniciales raycast
var safeTimeOut : bool = false
var can_damage : bool = true
# Called when the node enters the scene tree for the first time.
func _ready():
	$raycast_floor_detection.target_position.y = raycast_value
	$safeTime.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not floorDetected && safeTimeOut:
		$raycast_floor_detection.target_position.y += 6
		if $raycast_floor_detection.is_colliding():
			floorDetected = true
			$raycast_floor_detection.target_position.y -= 3
			init_spikeball()
			
func init_spikeball():
	var numerochains = ($raycast_floor_detection.target_position.y - raycast_value) / 6
	$SpikedBall.position.y += (numerochains * 6)
	for i in range(numerochains):
		var newRing = preload("res://scenes/objects/one_chain.tscn").instantiate()
		newRing.position = Vector2(0,(6*(i+1)))
		self.add_child(newRing)
	$Animation_rotation.play("regular_move")
	
func _on_safe_time_timeout():
	safeTimeOut = true


func _on_with_map_body_entered(_body):
	$Animation_rotation.speed_scale *= -1


func _on_damage_zone_body_entered(body: Node2D) -> void:
	if can_damage and body.has_method("take_damage"):
		body.take_damage()
		$".".modulate = Color.RED # si esta en rojo, te muestra que no te ara daño
		can_damage = false #desactiva el daño
		$cooldown_timer.start() #inicia el cooldown


func _on_cooldown_timer_timeout() -> void:
	$".".modulate = Color.WHITE #vuelve al color normal
	can_damage = true #vuelve a permitir el daño
