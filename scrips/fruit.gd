@tool
extends Node2D

@export_enum("apple", "banana", "cherry") var fruitType : String = "apple":
	set(value):
		fruitType = value
		$animations.animation = fruitType
		
# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		$animations.play(fruitType)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_area_collect_body_entered(body):
	if body.has_method("collectfruit"):
		body.collectfruit(fruitType)
	$collect_fruit.play()
	$animations.play("collected")

func _on_animations_animation_finished():
	self.queue_free()
