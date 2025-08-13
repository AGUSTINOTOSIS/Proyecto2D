extends Area2D

const FADE_DURATION := 0.8
const MAX_VOLUME := -1.0  # Volumen máximo de la radio
const MIN_VOLUME := -80.0  # Volumen mínimo (silenciado)
const BG_MUSIC_REDUCTION := -20.0
const SOUND_RADIUS := 300.0  # radio del area de sonido en píxeles


@onready var audio_player = $AudioStreamPlayer
@onready var prompt = $promptSprite
@onready var sound_area = $soundArea
@onready var sound_shape = $soundArea/CollisionShape2D

var player_in_range := false
var radio_is_on := false
var player_in_sound_area := false
var original_radio_volume = 0.0  # se uarda el volumen original aquí
var player_ref: Node2D = null
var bg_music_tween: Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prompt.visible = false
	audio_player.volume_db = MIN_VOLUME
	audio_player.stop()
	
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
	_fade_sound(MAX_VOLUME)
	_adjust_background_music(BG_MUSIC_REDUCTION)
			
func stop_radio():
	radio_is_on = false
	_fade_sound(MIN_VOLUME)
	await get_tree().create_timer(FADE_DURATION).timeout
	audio_player.stop()
	_adjust_background_music(0.0)
	
func update_radio_volume():
	if not player_ref:
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	var volume_percent = clamp(1.0 - (distance / SOUND_RADIUS), 0.0, 1.0)
	var target_volume = linear_to_db(volume_percent)
	audio_player.volume_db = target_volume
	if abs(audio_player.volume_db - target_volume) > 1.0:
		audio_player.volume_db = target_volume
	
	if distance <= SOUND_RADIUS:
		var bg_target = BG_MUSIC_REDUCTION * (1.0 - volume_percent)
		_adjust_background_music(bg_target)
	else:
		_adjust_background_music(0.0)
		
func _fade_sound(target_volume: float):
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", target_volume, FADE_DURATION)
		
func _adjust_background_music(target_volume: float):
	var bg_music = get_node_or_null("../audio_fondo")
	if bg_music:
		if bg_music_tween and bg_music_tween.is_valid():
			bg_music_tween.kill()
		bg_music_tween = create_tween()
		bg_music_tween.tween_property(bg_music, "volume_db", target_volume, FADE_DURATION)
	
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
		_adjust_background_music(0.0)
			
