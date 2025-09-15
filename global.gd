extends Node

var current_level := 1
var max_levels := 3  # Ajustar este número según los niveles que necesito
var first_time_menu := true
var last_level_path: String = ""  # guardara la última escena jugada

func get_level_path() -> String:
	return "res://scenes/words/word_%d.tscn" % current_level
	
