extends Node2D

var send_player = Vector2()
var player_in_range : bool = false
var player_in_sound_area : bool = false #nuevo estado para controlar el sonido
@onready var e_light = $ELight
@onready var teleport_sound = $TeleportSound

#sonidos de teletransportarse
@onready var fuiste_sound = $FuisteSound
@onready var te_fuiste_sound = $TeFuisteSound

#PARAMETROS DE SONIDO
const FADE_DURATION := 0.8 #duracion del fade en segundos
const MAX_VOLUME := -20.0 #volumen maximo (db)
const MIN_VOLUME := -80.0 #volumen minimo (silenciado)

# Called when the node enters the scene tree for the first time.
func _ready():
	e_light.visible = false # se oculta al inicio
	teleport_sound.volume_db = MIN_VOLUME # inicia silenciado
	teleport_sound.stop()
	_find_destination_portal() #busca el portal gemelo
	
func _find_destination_portal():
	var portals = get_tree().get_nodes_in_group("portal")
	for portal in portals:
		if portal != self:
			send_player = portal.position
			break
			
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact_radio"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_play_random_teleport_sound() #reproduce un sonido del portal alearttorio
			player.position = send_player
			
func _play_random_teleport_sound():
	var sounds = [fuiste_sound, te_fuiste_sound]
	var random_sound = sounds[randi() % sounds.size()]
	random_sound.play()

#FUNCIONES PARA LA TECLA E
func _on_teletransport_area_entered(area):
	if area.get_parent().is_in_group("player"):
		player_in_range = true
		e_light.visible = true #muestra la tecla E

func _on_teletransport_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		player_in_range = false
		e_light.visible = false # oculta la tecla E

#FUNCIONES PARA EL SONIDO AMBIENTAL DEL PORTAL
func _on_sound_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sound_area = true
		_handle_sound_state()

func _on_sound_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sound_area = false
		_handle_sound_state()
		
		
#FUNCIONES PARA CONTROLAR EL SONIDO CASTROZOOOOOO!!
func _handle_sound_state():
	if player_in_sound_area:
		_fade_sound(MAX_VOLUME)
		if not teleport_sound.playing:
			teleport_sound.play()
	else:
		_fade_sound(MIN_VOLUME)

func _fade_sound(tarjet_volume : float):
	var tween = create_tween()
	tween.tween_property(teleport_sound, "volume_db", tarjet_volume, FADE_DURATION)
	if tarjet_volume <= MIN_VOLUME + 5.0: #si es fade out
		tween.tween_callback(_stop_sound_if_needed) #detiene al final
		
func _stop_sound_if_needed():
	if not player_in_sound_area:
		teleport_sound.stop()
