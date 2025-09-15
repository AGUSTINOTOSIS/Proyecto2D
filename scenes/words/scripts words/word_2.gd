extends Node2D

func _ready() -> void:
	# guardar este nivel como el último jugado
	Global.last_level_path = self.scene_file_path
