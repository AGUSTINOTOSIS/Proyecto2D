extends Area2D

@onready var escena = preload("res://scenes/cut scenes/cut_scene_1.tscn").instantiate()
var permiso : bool = true

func _on_body_entered(body):
	if permiso:
		permiso = false
		body.block_player = true
		$AnimationPlayer.play("to_black")
	else:
		queue_free()

func _on_animation_player_animation_finished(anim_name):
	if (anim_name == "to_black"):
		get_parent().get_node("UI").visible = false
		escena.get_node("AnimationPlayer").connect("animation_finished", on_escene_end)
		get_parent().add_child(escena)
		escena.get_node("Path2D/PathFollow2D/Camera2D").make_current()
		$AnimationPlayer.play("to_transparent")

func on_escene_end(anim_name):
	if (anim_name == "new_animation"):
		$AnimationPlayer.stop()
		escena.queue_free()
		$AnimationPlayer.play("to_transparent")
		get_parent().get_node("player").block_player = false
		get_parent().get_node("UI").visible = true
		print(anim_name)
	
