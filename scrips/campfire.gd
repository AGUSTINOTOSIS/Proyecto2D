extends Area2D

@onready var reduction_timer = $ReductionTimer

var player_in_bonfire: bool = false
#var reduction_times = {
	#"intensidad_1": 0.0,
	#"intensidad_2": 3.0,
	#"intensidad_3": 8.0,
	#"intensidad_4": 15.0,
	#"intensidad_5": 20.0
#}
##var reduction_rate: float = 15.0  # reduce 5 "unidades" por segundo

#var current_reduction_time: float = 0.0
#var current_effect: String = ""

var reduction_times = [0.0, 3.0, 8.0, 15.0, 20.0]
var current_reduction_time: float = 0.0
var current_effect: int = 0
#reduction_time[current_effect]: [0] = 0, [1] = 3.0, ect.

func _ready() -> void:
	reduction_timer.wait_time = 0.1
	reduction_timer.one_shot = false

#delta = "How much time has passed since the last frame update of the game (or last time this function was called)
#func _process(delta):
	#if(player_in_bonfire):
		#current_reduction_time -= delta
		#if(current_reduction_time<=0):
			#process_reduction()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("START WARMING!")
		player_in_bonfire = true
		body.add_to_group("in_bonfire")
		start_reduction_process()
		if(reduction_times[current_effect] > 0):
			reduction_timer.wait_time = reduction_times[current_effect] 
			reduction_timer.start()
		print("Reduction time on enter = ", reduction_times[current_effect])
		
		var root = get_tree().root.get_node("word_20") #FUTURE FIX; replace this with dynamic string that always gets level name?
		if(root.has_method('player_heat_change')):
			root.player_heat_change()
		#Set the timer's wait-time to the amount of time needed to wait. Then, once it ends, it simply updates the 
		#value since it calls process_reduction 
		#Instead of using timers, you could also use _process(delta) [I left code, in case you want to use it, commented out]

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_bonfire = false
		body.remove_from_group("in_bonfire")
		reduction_timer.stop()
		current_reduction_time = 0.0
		#current_effect = 0
		print("El Player salio de fogata - Deteniendo reduccion")
		var root = get_tree().root.get_node("word_20")
		if(root.has_method('player_heat_change')):
			root.player_heat_change()
		
func _on_reduction_timer_timeout() -> void:
	if player_in_bonfire:
		process_reduction()
		#var player = get_tree().get_first_node_in_group("player")
		#if player:
			#reduce_effects_on_player(player)
		#reduce_global_effects()

func reduce_effects_on_player(player: Node2D):
	var current_color = player.modulate
	if current_color.r < 1.0:
		var new_r = min(current_color.r + 0.05, 1.0)
		player.modulate = Color(new_r, current_color.g, current_color.b, current_color.a)
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		if camera.has_method("reduce_shake_intensity"):
			camera.reduce_shake_intensity(0.3)
	
	#var current_color = player.modulate
	#if current_color.r < 1.0:
		#var new_r = min(current_color.r + 0.1, 1.0)
		#player.modulate = Color(new_r, current_color.g, current_color.b, current_color.a)
	#if player.has_node("Camera2D"):
		#var camera = player.get_node("Camera2D")
		#if camera.has_method("reduce_shake_intensity"):
			#camera.reduce_shake_intensity(0.5)
			
func reduce_global_effects():
	var music_area = get_tree().get_first_node_in_group("music_area")
	if music_area and music_area.has_method("reduce_music_volume"):
		music_area.reduce_music_volume(0.1)
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("reduce_intensity_effects"):
		ui.reduce_intensity_effects_reverse(0.15)
		
func start_reduction_process():
	print("START HEAT!")
	var ui = get_tree().get_first_node_in_group("ui") #doesn't find UI?
	if ui:
		print("UI!")
		for i in range(5, 0, -1):
			var effect_name = "intensidad_" + str(i)
			print("check for ", effect_name)
			if ui.has_node(effect_name) and ui.get_node(effect_name).modulate.a > 0.1:
				print("current effect is ", i)
				current_effect = i
				current_reduction_time = 0.0
				print("cOmienza reduccion para: ", current_effect)
				return
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("stop_music_immediately"):
			music_area.stop_music_immediately()

func process_reduction():
	#print("GETTING WARMER!")
	#current_reduction_time += 0.1
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui or current_effect==0:
		return
		
	#var required_time = reduction_times[current_effect]
	#print(required_time, current_reduction_time, current_effect)
	#if current_reduction_time >= required_time: #Only called when timer is finished, now
	remove_current_effect()
	move_to_next_effect()

func remove_current_effect():
	var ui = get_tree().get_first_node_in_group("ui")
	var nodeName = "intensidad_" + str(current_effect+1)
	print(nodeName)
	if ui and ui.has_node(nodeName):
		var effect = ui.get_node(nodeName)
		var tween = create_tween()
		tween.tween_property(effect, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if effect and effect.visible:
				effect.visible = false
		)
		
func move_to_next_effect():
	#var current_number = int(current_effect.replace("intensidad_", ""))
	if current_effect > 1: #(a<0, 0) = 0, (a>0, 0) = a
		current_effect -= max(current_effect-1, 0) #"intensidad_" + str(current_number - 1)
		reduction_timer.wait_time = reduction_times[current_effect] #make the timer's "wait" be however long it needs to be, for the CURRENT STAGE of frost
		print("New Frost timer: ", reduction_times[current_effect])
		#current_reduction_time = 0.0
		print("pasando a reducir: ", current_effect)
	else:
		#current_effect = ""
		var music_area = get_tree().get_first_node_in_group("music_area")
		if music_area and music_area.has_method("stop_music_immediately"):
			music_area.stop_music_immediately()
