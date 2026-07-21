extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var auto_start: bool = true
@onready var spawn_timer = $SpawnTimer

var is_spawning: bool = false
var max_global_enemies: int = 30
var respawn_threshold: int = 15

func _ready():
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	if auto_start:
		start_spawning()

func start_spawning():
	if not is_spawning and enemy_scene:
		is_spawning = true
		spawn_timer.start()
		print("Spawner iniciado - Intervalo: ", spawn_interval, "s")
	else:
		print("Error: No hay escena de enemigo asignada")

func stop_spawning():
	is_spawning = false
	spawn_timer.stop()
	print("Spawner detenido")
	
func get_global_enemy_count() -> int:
	var enemy_count = 0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:  # Asumiendo que tu enemigo tiene variable is_dead
			enemy_count += 1
	return enemy_count

func spawn_enemy():
	var global_count = get_global_enemy_count()
	if global_count >= max_global_enemies:
		return
	
	if global_count < respawn_threshold:
		if spawn_timer.is_stopped() and is_spawning:
			spawn_timer.start()
	if not enemy_scene:
		return
	
	var enemy_instance = enemy_scene.instantiate()
	# Posición aleatoria dentro del área de spawn
	var spawn_area = $SpawnArea
	if spawn_area and spawn_area.get_child_count() > 0:
		var collision_shape = spawn_area.get_child(0)
		if collision_shape is CollisionShape2D:
			var shape = collision_shape.shape
			if shape is RectangleShape2D:
				var spawn_position = global_position
				spawn_position.x += randf_range(-shape.size.x / 2, shape.size.x / 2)
				spawn_position.y += randf_range(-shape.size.y / 2, shape.size.y / 2)
				enemy_instance.global_position = spawn_position
			else:
				enemy_instance.global_position = global_position
		else:
			enemy_instance.global_position = global_position
	else:
		enemy_instance.global_position = global_position
	
	# Agregar a la escena
	get_parent().add_child(enemy_instance)

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	
func check_global_spawn_conditions():
	var global_count = get_global_enemy_count()
	
	if global_count >= max_global_enemies:
		# Pausar todos los spawners
		stop_spawning()
		print("Spawner pausado - Límite global alcanzado")
	elif global_count < respawn_threshold and not spawn_timer.is_stopped():
		# Reanudar si estaba pausado y ahora hay menos del threshold
		if is_spawning:
			spawn_timer.start()
			print("Spawner reanudado - Enemigos bajaron a: ", global_count)
			
func set_spawn_interval(new_interval: float):
	spawn_interval = new_interval
	spawn_timer.wait_time = new_interval

func notify_enemy_died():
	check_global_spawn_conditions()
