extends Camera2D

#se confioguran
@export var shake_power: float = 25.0 #aumenta para mas movimiento a la camara #25.0

var current_shake_duration: float = 0.0
var is_shaking := false
var should_shake_continuously := false

func shake_screen(power: float, duration: float, continuous: bool = false):
	shake_power = power
	if continuous:
		should_shake_continuously = true
		is_shaking = true
	else:
		current_shake_duration = duration
		is_shaking = true
		should_shake_continuously = false
		
func stop_shake():
	should_shake_continuously = false
	current_shake_duration = 0.0
	offset = Vector2.ZERO
	is_shaking = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_shaking:
		if should_shake_continuously:
			offset = Vector2(
				randf_range(-shake_power, shake_power),
				randf_range(-shake_power, shake_power)
			)
		elif current_shake_duration > 0:
			offset = Vector2(
				randf_range(-shake_power, shake_power),
				randf_range(-shake_power, shake_power)
			)
			current_shake_duration -= delta
		else:
			stop_shake()
			
func reduce_shake_intensity(amount: float):
	shake_power = max(0.0, shake_power - amount)
	current_shake_duration = max(0.0, current_shake_duration - amount * 10)
	if shake_power <= 1.0:
		stop_shake()
