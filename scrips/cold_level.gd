extends Node2D

var frost_times = [0.0, 20.0, 46.0, 78.0, 132.0]
var frost_timer:float = 0
var frost_progress:int = 0
var player_in_cold:bool = true

var heat_times = [0.0, 3.0, 8.0, 15.0, 20.0]
var heat_progress = 0.0

@onready var music = $delaymusic/AudioStreamPlayer
var music_tween = null
@onready var player = $player
@onready var ui = $UI
var overlay_header = "intensidad_" #ui.node(filter_header + #)

func _ready() -> void:
	pass

func player_heat_change() -> void:
	for fire in get_tree().get_nodes_in_group("bonfire"):
		print("Has bonfire variable? ", "player_in_bonfire" in fire)
		if "player_in_bonfire" in fire and fire.player_in_bonfire:
			player_in_cold = false
			heat_progress = 0
			return
		# \/ only happens if no fires are touching the player
		player_in_cold = true
		heat_progress = 0
	pass
	
func update_frost(stage:int) -> void: #ALWAYS runs when the frost level changes
	print("UPDATE TO FROST LEVEL ", stage)
	heat_progress = 0
	
	#frost_progress is used as the "last stage" value, UNTIL the end of this function, where it gets updated
	
	if(stage == 0): #JUST reached max warmth
		#hide UI elements
		for overlay in ui.find_children(overlay_header):
			if overlay.visible:
				var twn = create_tween()
				twn.tween_property(overlay, "modulate:a", 0.0, 0.5)
				twn.tween_callback(func():
					if overlay and overlay.visible:
						overlay.visible = false
				)
		#remove player effects 
		
		#update music
		music.stop()
		
	else:
		if(stage < frost_progress): #ONLY when you warmed up
			frost_timer = frost_times[stage]
			var last_overlay = ui.get_node(overlay_header + str(frost_progress))
			var twn = create_tween()
			twn.tween_property(last_overlay, "modulate:a", 0.0, 0.5)
			twn.tween_callback(func():
				if last_overlay and last_overlay.visible:
					last_overlay.visible = false
			)
		else: #ONLY when you got colder
			pass
			
		#Always happens, AS LONG AS it's not 0
		#update UI elements
	
		#update player effects 
		
		#update music
		if not(music.playing):
			music.play()
		if(music_tween != null):
			music_tween.cancel()
			
	#update AT THE END, so that frost_progress can be used as a "previous stage" value during this function
	frost_progress = stage 
		
func _process(delta: float) -> void:
	if(player_in_cold):
		frost_timer += delta
		print("COLD DATA: ", frost_progress, ": ", frost_timer)
		for i in range(len(frost_times)-1, 0, -1): #4->1
			#Update things when the timer reaches a different "stage" of progression
			if frost_timer >= frost_times[i]: 
				if(frost_progress != i):
					update_frost(i)
					pass #update stuff when the timer reaches a new stage
				return #handle stuff here, for each level
		#only ends up happening if frost_timer < frost_times[1] 
		if frost_progress != 0:
			update_frost(0)
		
	else: #When player is getting warm
		heat_progress += delta
		print("HEAT DATA: ", heat_progress, "/", heat_times[frost_progress])
		if(heat_progress >= heat_times[frost_progress]):
			update_frost(max(frost_progress-1, 0)) #Frost can ONLY ever drop to 0; never below that
