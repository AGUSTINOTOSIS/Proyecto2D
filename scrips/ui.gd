extends CanvasLayer

@onready var damage_overlay = $damageOverlay

@onready var timer_label = $tiempo_label
@onready var countdown_timer = $countdown
@onready var audio_stream_player = $emergencia

var time_left : int = 180
var special_music_playing: bool = false
var camera_shake_playing: bool = false
var original_volume: float = 0.0

var damage_color = Color("#8d0027")
var max_alpha = 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	damage_overlay.color = damage_color
	damage_overlay.color.a = 0
	damage_overlay.visible = false
	
	if get_parent().has_node("player"):
		$health_ProgressBar.value = get_parent().get_node("player").health
		$FuitpointsLabel.text = "Frutas:" + str(get_parent().get_node("player").fruitCount)
	
	countdown_timer.wait_time = 1.0
	countdown_timer.start()
	timer_label.text = str(time_left)
	
	var bg_music = get_node("../audio_fondo")
	if bg_music:
		original_volume = bg_music.volume_db
		
func update_damage_effect(health_percent: float):
	var lost_health = 100 - health_percent
	var alpha = min(max_alpha, (lost_health / 100.0) * max_alpha)
	damage_overlay.color.a = alpha
	damage_overlay.visible = alpha > 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$health_ProgressBar.value = get_parent().get_node("player").health
	$FuitpointsLabel.text = "Frutas:" + str(get_parent().get_node("player").fruitCount)
	
	if get_parent().has_node("player"):
		var health = get_parent().get_node("player").health
		var health_percent = (float(health) / 100.0) * 100
		update_damage_effect(health_percent)
		
func flash_damage():
	var tween = create_tween()
	tween.tween_property(damage_overlay, "color:a", max_alpha, 0.1)
	tween.tween_property(damage_overlay, "color:a", damage_overlay.color.a, 0.3)
	



func _on_countdown_timeout() -> void:
	time_left -= 1
	timer_label.text = str(time_left)
	
	if time_left <= 94 and not camera_shake_playing:
		start_camera_shake()
	
	if time_left <= 110 and not special_music_playing:
		start_special_effects()
	
	if time_left <= 6 and camera_shake_playing:
		stop_camera_shake()
		
	if time_left <= 0:
		end_game()
		
func start_camera_shake():
	camera_shake_playing = true
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").shake_screen(1.0, 0.0, true) #20.0
		
func stop_camera_shake():
	camera_shake_playing = false
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").stop_shake()
		
func start_special_effects():
	special_music_playing = true
	audio_stream_player.play()
	
	Radio.emergency_music = true
	var bg_music = get_node("../audio_fondo")
	if bg_music:
		var tween = create_tween()
		tween.tween_property(bg_music, "volume_db", -80.0, 5.0)
		
	# Silenciar música de radio si está sonando
	
	#FIVERR: may want to tweak the values a bit, here, depending on what SOUNDS better.
	var tween_radio = create_tween()
	tween_radio.tween_property(Radio, "MAX_VOLUME", -20.0, 3.0)
	tween_radio.tween_property(Radio, "BG_MUSIC_REDUCTION", -20.0, 3.0)
	#var radios = get_tree().get_nodes_in_group("radio")
	#for radio in radios:
		#if radio.audio_player.playing:
			#tween_radio.tween_property(radio.audio_player, "volume_db", -20.0, 3.0)
			
		
func end_game():
	var player = get_parent().get_node("player")
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").stop_shake()
	get_tree().change_scene_to_file("res://scenes/UIs/game_over.tscn")

func stop_timer():
	countdown_timer.stop()  # Detiene el contador
