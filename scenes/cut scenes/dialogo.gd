extends Sprite2D

@export var texto : String = "":
	set(value):
		visible = true
		texto = value
		$Timer.start()

var index = 0;

func _on_timer_timeout():
	if index >= texto.length():
		$Timer_esconde.start()
		$Timer.stop()
	else:
		$Label.text = $Label.text + texto[index]
		index += 1

func _on_timer_esconde_timeout():
	visible = false
	$Label.text = ""
	index = 0
