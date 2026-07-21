extends StaticBody2D

@export var has_top_collision: bool = true

@onready var top_collision = $TopCollision #colision de arriba
@onready var bottom_area = $BottomArea #area con su colisi0on de abajo
@onready var interaction_area = $InteractionArea # Area2D para detectar jugador cercano
@onready var e_prompt = $EPrompt
@onready var progress_sprite = $ProgressSprite
@onready var construction_timer = $ConstructionTimer
@onready var main_sprite = $Sprite2D
@onready var build_sound_player = $BuildSoundPlayer
@onready var complete_sound_players = [
	$CompleteSoundPlayer1,
	$CompleteSoundPlayer2,
	$CompleteSoundPlayer3,
	$CompleteSoundPlayer4
]

var player_near: bool = false
var construction_progress: int = 0
var max_progress: int = 8
var is_constructed: bool = false
var my_number: int = 1  # numero de este tablon
var wood_required_per_press: int = 1  # madera requerida por cada E presionada

var auto_build_timer: float = 0.0
var auto_build_interval: float = 0.1  # Cada 0.5 segundos
var is_auto_building: bool = false

func _ready() -> void:
	my_number = get_plank_number(name)
	
	set_plank_visible(false)
	e_prompt.visible = false
	progress_sprite.visible = false
	
	if top_collision:
		if has_top_collision:
			top_collision.set_deferred("disabled", true)
		else:
			top_collision.set_deferred("disabled", true)
	if progress_sprite:
		progress_sprite.stop()
		
	if my_number > 1:
		set_process(false)
		interaction_area.set_deferred("monitoring", false)
		interaction_area.set_deferred("monitorable", false)

func find_and_setup_next_planks():
	if my_number != 1:
		return
	var all_planks = get_tree().get_nodes_in_group("wooden_planks")
	for plank in all_planks:
		if plank != self and plank.has_method("get_plank_number"):
			var other_number = plank.get_plank_number(plank.name)
			if other_number > my_number:
				plank.set_process(false)
				plank.interaction_area.set_deferred("monitoring", false)
				plank.interaction_area.set_deferred("monitorable", false)
					
func get_plank_number(plank_name: String) -> int:
	if "wooden_plank" in plank_name:
		var number_part = plank_name.replace("wooden_plank", "")
		if number_part == "":
			return 1
		elif number_part.is_valid_int():
			return number_part.to_int()
	return 999
	
func _process(delta: float) -> void:
	#construccion manual
	if player_near and not is_constructed and Input.is_action_just_pressed("interact_radio"):
		try_advance_construction()
	#contruccion automatica
	if player_near and not is_constructed and Input.is_action_pressed("interact_radio"):
		auto_build_timer += delta
		if auto_build_timer >= auto_build_interval:
			auto_build_timer = 0.0
			try_advance_construction()
	else:
		auto_build_timer = 0.0
		is_auto_building = false
		
func set_plank_visible(should_show: bool):
	if main_sprite:
		main_sprite.visible = should_show
	if top_collision and has_top_collision:
		top_collision.set_deferred("disabled", not should_show)
		
func set_interaction_enabled(enabled: bool):
	set_process(enabled)
	interaction_area.set_deferred("monitoring", enabled)
	interaction_area.set_deferred("monitorable", enabled)
	
	if not enabled:
		e_prompt.visible = false
		player_near = false

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_constructed:
		player_near = true
		e_prompt.visible = true
		progress_sprite.visible = false
		construction_timer.stop()
	
func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		e_prompt.visible = false
		progress_sprite.visible = false
		construction_timer.stop()
		auto_build_timer = 0.0
		
func try_advance_construction():
	# verificar si el jugador tiene suficiente madera
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("has_wood"):
		if ui.has_wood(wood_required_per_press):
			# consumir madera y avanzar construccion
			ui.use_wood(wood_required_per_press)
			advance_construction()
		else:
			print("No tienes suficiente madera. Necesitas: ", wood_required_per_press)
			
func advance_construction():
	construction_progress += 1
	construction_timer.start()
	
	e_prompt.visible = false
	progress_sprite.visible = true
	
	# Reproducir sonido de construcción
	if build_sound_player:
		build_sound_player.play() 
	
	if progress_sprite:
		progress_sprite.stop()
		progress_sprite.frame = construction_progress - 1

	if construction_progress >= max_progress:
		complete_construction()
		
func complete_construction():
	is_constructed = true
	construction_timer.stop()
	
	e_prompt.visible = false
	progress_sprite.visible = false
	
	set_plank_visible(true)
	
	if top_collision and has_top_collision:
		top_collision.set_deferred("disabled", false)
	enable_next_plank()
	
	# Reproducir un sonido al azar al completar la construcción
	if complete_sound_players.size() > 0:
		var random_index = randi() % complete_sound_players.size()
		var random_sound_player = complete_sound_players[random_index]
		if random_sound_player:
			random_sound_player.play()
	
func enable_next_plank():
	var all_planks = get_tree().get_nodes_in_group("wooden_planks")
	var next_number = my_number + 1
	var next_plank = null
	
	for plank in all_planks:
		if plank.has_method("get_plank_number"):
			var plank_number = plank.get_plank_number(plank.name)
			if plank_number == next_number:
				next_plank = plank
				break
	if next_plank:
		print("Habilitando tablón: ", next_plank.name)
		next_plank.set_process(true)
		next_plank.interaction_area.set_deferred("monitoring", true)
		next_plank.interaction_area.set_deferred("monitorable", true)
		
func _on_construction_timer_timeout() -> void:
	if not is_constructed:
		construction_progress = 0
		progress_sprite.visible = false
		
		if player_near:
			e_prompt.visible = true
		else:
			progress_sprite.visible = false

func _on_bottom_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_constructed and has_top_collision:
		if top_collision:
			top_collision.set_deferred("disabled", true)


func _on_bottom_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_constructed and has_top_collision:
		if top_collision:
			top_collision.set_deferred("disabled", false)
