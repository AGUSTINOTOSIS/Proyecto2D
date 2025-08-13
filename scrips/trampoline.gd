extends Node2D

func _on_activation_area_body_entered(body):
	$sonido_trampolin.play()
	$trampolin_animation.play("jump")
	body.velocity.y = -900
