extends Area2D

@export_enum("Normal", "Hielo") var bullet_type: int = 0
@export var bullet_scene: PackedScene
@export var ice_bullet_scene: PackedScene
@export var shoot_interval: float = 1.5
@export var detection_range: float = 400.0
@export var bullet_speed: float = 300.0

var player: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = shoot_interval
	$RayCast2D.target_position = Vector2(detection_range, 0)
	$RayCast2D.collide_with_areas = true
	$RayCast2D.collide_with_bodies = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player:
		update_aim()
		try_shoot()
		
func update_aim():
	var direction = (player.global_position - global_position).normalized()
	$RayCast2D.target_position = direction * detection_range
	$RayCast2D.force_raycast_update()
	
func try_shoot():
	if player and $RayCast2D.is_colliding():
		var collider = $RayCast2D.get_collider().get_parent()
		if collider == player and $Timer.is_stopped():
			shoot()
			$Timer.start()
		
		
func shoot():
	if player and has_node("Marker2D"):
		# ELEGIR EL TIPO DE BALA SEGUN bullet_type
		var selected_bullet_scene: PackedScene
		match bullet_type:
			0: # Normal
				selected_bullet_scene = bullet_scene
			1: # Hielo
				selected_bullet_scene = ice_bullet_scene
			_:
				selected_bullet_scene = bullet_scene  # Por defecto
				
		if selected_bullet_scene:
			var bullet = selected_bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = $Marker2D.global_position
			var dir = (player.global_position - bullet.global_position).normalized()
			bullet.initialize(dir)
			bullet.speed = bullet_speed
			if has_node("ShootSound"):
				$ShootSound.play()
			print("Bala ", ["Normal", "Hielo"][bullet_type], " disparada en dirección: ", dir)
			
		
func _on_timer_timeout() -> void:
	$Timer.stop()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		print("Jugador detectado: ", player.name)
		print("Posición jugador: ", player.global_position)
		print("Posición enemigo: ", global_position)

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		print("Jugador salio del area de deteccion")
		player = null
	
