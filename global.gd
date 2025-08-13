extends Node

var current_level := 1
var max_levels := 3  # Ajustar este número según los niveles que necesito

func get_level_path() -> String:
	return "res://scenes/words/word_%d.tscn" % current_level
	
