extends Area2D
class_name Radio #so UI can access static emergency_music variable

const FADE_DURATION := 1.2 #0.8
static var MAX_VOLUME := -1.0  # Volumen máximo de la radio #FIVERR: was "constant", not "static var"
const MIN_VOLUME := -80.0  # Volumen mínimo (silenciado)
static var BG_MUSIC_REDUCTION := -40 #-20.0 #FIVERR: was "constant", not "static var"
const SOUND_RADIUS := 300.0  # radio del area de sonido en píxeles
static var emergency_music:= false


@onready var audio_player = $AudioStreamPlayer
@onready var prompt = $promptSprite
@onready var sound_area = $soundArea
@onready var sound_shape = $soundArea/CollisionShape2D

#var MAX_VOLUME := -1.0
var player_in_range := false
var radio_is_on := false
var toggle_cooldown := false
var player_in_sound_area := false
var original_radio_volume = 0.0  # se uarda el volumen original aquí
var player_ref: Node2D = null
var bg_music_tween: Tween
var target_volume_percent: float = 0 #FIVERR: To help with making the music properly fade in & out

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emergency_music = false
	prompt.visible = false
	audio_player.volume_db = MIN_VOLUME
	audio_player.stop()
	
	if sound_shape and sound_shape.shape is CircleShape2D:
		sound_shape.shape.radius = SOUND_RADIUS
	
func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact_radio") and not toggle_cooldown:
		toggle_radio()
		
	if audio_player.playing and player_ref:
		update_radio_volume()
		
func toggle_radio():
	toggle_cooldown = true
	if radio_is_on:
		stop_radio()
	else:
		play_radio()

func play_radio():
	radio_is_on = true
	audio_player.volume_db = MIN_VOLUME
	#FIVERR: for the Random Song, check the AudioStreamPlayer "Stream" value
	#FIVERR: The radio song was never told to actually play
	audio_player.play()
	_fade_sound(true)
	_adjust_background_music(BG_MUSIC_REDUCTION)
			
func stop_radio():
	radio_is_on = false
	_fade_sound(false)
	await get_tree().create_timer(FADE_DURATION).timeout
	audio_player.stop()
	_adjust_background_music(0.0)
	
func update_radio_volume():
	if not player_ref:
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	var distance_percent = clamp(1.0 - (distance / SOUND_RADIUS), 0.0, 1.0)
	
	#FIVERR: I couldn't think of a good way to explain what lerp (or lerpf, in this case) does. 
	#I highly reccomend googling it, as it is a very effective tool.
	#It basically gets the distance between two values, and the last value tells it 
	#the percent needed to do (-80 + (distance*percent)).
	#the percent value should be between 0 and 1 (use floats)
	#print(linear_to_db(distance_percent))
	var target_volume = lerpf(-80, MAX_VOLUME+linear_to_db(distance_percent), target_volume_percent)
	
	audio_player.volume_db = target_volume
	if abs(audio_player.volume_db - target_volume) > 1.0:
		audio_player.volume_db = target_volume
	
	if distance <= SOUND_RADIUS:
		var bg_target = (target_volume_percent * BG_MUSIC_REDUCTION) * distance_percent#(1.0 - distance_percent)
		_adjust_background_music(bg_target)
	else:
		_adjust_background_music(0.0)

#func _fade_sound(target_volume: bool):
	#var tween = create_tween()
	#tween.tween_property(audio_player, "volume_db", target_volume, FADE_DURATION)

func _fade_sound(turning_up: bool):
	#toggle_cooldown = true
	var tween = create_tween()
	#tween.tween_property(audio_player, "volume_db", target_volume, FADE_DURATION)
	tween.tween_property(self, "target_volume_percent", 1 if turning_up else 0, FADE_DURATION)
	tween.finished.connect(allow_toggle) 
	#FIVERR: when the Tween finishes, it calls the allow_toggle function.
	#It sets the toggle_cooldown to false, allowing the player to toggle the radio again
	
func allow_toggle():
	toggle_cooldown = false;
		
func _adjust_background_music(target_volume: float):
	#FIVERR: Change what "bg music" is targeted, when the emergency music is playing
	var bg_music = get_node_or_null("../UI/emergencia" if emergency_music else "../audio_fondo")
	if bg_music:
		bg_music.volume_db = target_volume
		#if bg_music_tween and bg_music_tween.is_valid():
			#bg_music_tween.kill()
		#bg_music_tween = create_tween()
		#bg_music_tween.tween_property(bg_music, "volume_db", target_volume, FADE_DURATION)
	#var emergency_music = get_node_or_null("/")
	
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
			
