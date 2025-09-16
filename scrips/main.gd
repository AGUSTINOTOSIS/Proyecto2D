extends CanvasLayer

@onready var start_button = $Control/start
@onready var options_button = $Control/options
@onready var quit_button = $Control/quit
@onready var animation_player = $AnimationPlayer
@onready var music = $Control/music
@onready var music_intro = $music_intro
@onready var color_rect = $"intro 1"

var first_time := true  # variable temporal
var intro_skipped := false  # para evitar saltar múltiples veces

func _ready() -> void:
	start_button.grab_focus()
	if Global.first_time_menu:
		play_intro()
		#Global.first_time_menu = false  # marcar como visto
	else:
		skip_intro()
		
func _unhandled_input(event: InputEvent) -> void:
	if Global.first_time_menu and not intro_skipped and animation_player.is_playing():
		if event.is_action_pressed("ui_accept"):
			skip_intro_immediately()
			intro_skipped = true
			get_viewport().set_input_as_handled()
			
	
func play_intro():
	start_button.visible = false
	options_button.visible = false
	quit_button.visible = false
	color_rect.visible = true
	color_rect.modulate.a = 1.0
	
	music.stop()
	music_intro.play()
	
	animation_player.play("intro")
	await animation_player.animation_finished
	Global.first_time_menu = false
	show_menu()

func skip_intro_immediately():
	animation_player.stop() # Detener la animación
	animation_player.play("skip_intro") #New animation was added; basically does everything from the "intro" animation immedietely
	music_intro.stop()
	color_rect.visible = false
	show_menu()
	music.play()
	Global.first_time_menu = false
	
func skip_intro():
	color_rect.visible = false
	show_menu()
	music.play()
	
func show_menu():
	start_button.visible = true
	options_button.visible = true
	quit_button.visible = true
	start_button.grab_focus()
	
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/words/word_1.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		music_intro.stop()
		show_menu()
		music.play()  # Iniciar música al terminar intro
		print("Música debería estar sonando ahora")
