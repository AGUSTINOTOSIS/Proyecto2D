@tool
extends Node2D

@export_enum("apple", "banana", "cherry") var fruitType : String = "apple":
	set(value):
		fruitType = value
		$animations.animation = fruitType
		
@onready var visibility_notifier = $VisibleOnScreenNotifier2D
		
# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		if visibility_notifier.is_on_screen():
			$animations.play(fruitType)
		else:
			$animations.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_area_collect_body_entered(body):
	if body.has_method("collectfruit"):
		body.collectfruit(fruitType)
	$collect_fruit.play()
	$animations.play("collected")

func _on_animations_animation_finished():
	if $animations.animation == "collected":
		self.queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not $animations.is_playing():
		$animations.play(fruitType)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if $animations.is_playing():
		$animations.stop()
