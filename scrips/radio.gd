extends Area2D
class_name Radio #so UI can access static emergency_music variable

const FADE_DURATION := 0.8 #0.8
static var MAX_VOLUME := -1.0  # Volumen máximo de la radio was "constant", not "static var"
const MIN_VOLUME := -80.0  # Volumen mínimo (silenciado)
static var BG_MUSIC_REDUCTION := -20
const SOUND_RADIUS := 500.0  # radio del area de sonido en píxeles
# guarda las musicas ordenadas
const RADIO_TRACKS = [
	preload("res://musica/radio/full rat dance green screen - Le bazars de Nono3.mp3"),
	preload("res://musica/radio/Sonic CD Remastered - Metallic Madness Past - Church of Kondo.mp3"),
	preload("res://musica/radio/Clint Eastwood [8 Bit Cover Tribute to Gorillaz] - 8 Bit Universe - 8 Bit Universe.mp3"),
	]

@onready var audio_player = $AudioStreamPlayer
@onready var prompt = $promptSprite
@onready var sound_area = $soundArea
@onready var sound_shape = $soundArea/CollisionShape2D

#var MAX_VOLUME := -1.0
var player_in_range := false
var radio_is_on := false
var player_in_sound_area := false
var original_radio_volume = 0.0  # se uarda el volumen original aquí
var original_bg_volume: float = -10.0  # guarda el volumen original de fondo
var player_ref: Node2D = null
var bg_music_tween: Tween
var target_volume_percent: float = 0 #To help with making the music properly fade in & out
static var emergency_music:= false
var current_track_index := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emergency_music = false
	prompt.visible = false
	audio_player.volume_db = MIN_VOLUME
	audio_player.stop()
	
	# guarda el volumen original de la musica de fondo
	var bg_music = get_node_or_null("../audio_fondo")
	if bg_music:
		original_bg_volume = bg_music.volume_db
	
	if sound_shape and sound_shape.shape is CircleShape2D:
		sound_shape.shape.radius = SOUND_RADIUS
	
func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact_radio"):
		toggle_radio()
		
	if audio_player.playing and player_ref:
		update_radio_volume()
		
func toggle_radio():
	if radio_is_on:
		stop_radio()
	else:
		play_radio()

func play_radio():
	radio_is_on = true
	current_track_index = (current_track_index + 1) % RADIO_TRACKS.size()
	audio_player.stream = RADIO_TRACKS[current_track_index]
	audio_player.volume_db = MIN_VOLUME
	audio_player.play()
	_fade_sound(true)
	_adjust_background_music(BG_MUSIC_REDUCTION)
			
func stop_radio():
	radio_is_on = false
	_fade_sound(false)
	await get_tree().create_timer(FADE_DURATION).timeout
	audio_player.stop()
	_adjust_background_music(original_bg_volume)
	#_adjust_background_music(0.0)
	
func update_radio_volume():
	if not player_ref:
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= 0:
		distance = 0.001
	var distance_percent = clamp(1.0 - (distance / SOUND_RADIUS), 0.0, 1.0)
	if is_nan(target_volume_percent):
		target_volume_percent = 0.0
	var linear_volume = lerpf(-80, MAX_VOLUME+linear_to_db(distance_percent), target_volume_percent)
	var target_volume = linear_volume if not is_nan(linear_volume) else MIN_VOLUME
	if not is_nan(target_volume):
		audio_player.volume_db = target_volume
	if distance <= SOUND_RADIUS:
		var bg_target = (target_volume_percent * BG_MUSIC_REDUCTION) * distance_percent#(1.0 - distance_percent)
		_adjust_background_music(bg_target)
	else:
		_adjust_background_music(original_bg_volume)
		#_adjust_background_music(0.0)

func _fade_sound(turning_up: bool):
	var tween = create_tween()
	tween.tween_property(self, "target_volume_percent", 1 if turning_up else 0, FADE_DURATION)
		
func _adjust_background_music(target_volume: float):
	if emergency_music:
		return
	#Change what "bg music" is targeted, when the emergency music is playing
	var bg_music = get_node_or_null("../audio_fondo")
	if bg_music and not emergency_music:
		if bg_music_tween and bg_music_tween.is_valid():
			bg_music_tween.kill()
			
		bg_music_tween = create_tween()
		bg_music_tween.tween_property(bg_music, "volume_db", target_volume, FADE_DURATION)
		#bg_music.volume_db = target_volume
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt.visible = false
		


func _on_sound_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		if audio_player.playing:
			_adjust_background_music(BG_MUSIC_REDUCTION)

func _on_sound_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and radio_is_on:
		audio_player.volume_db = MIN_VOLUME
		_adjust_background_music(original_bg_volume)
		#_adjust_background_music(0.0)
			
