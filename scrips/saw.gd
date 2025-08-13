extends CharacterBody2D

var SPEED = 200
var can_damage: bool = true
const RAY_FLOOR_POSITION_X = 20
const RAY_WALL_TARGET_POSITION_X = 20
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	velocity.x = SPEED
	$raycast_floor_detection.position.x = RAY_WALL_TARGET_POSITION_X
	$raycast_wall_detection.target_position.x = RAY_WALL_TARGET_POSITION_X
	

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if not $raycast_floor_detection.is_colliding() || $raycast_wall_detection.is_colliding():
		velocity.x *= -1
		$raycast_floor_detection.position.x *= -1
		$raycast_wall_detection.target_position.x *= -1
	
		
	move_and_slide()


func _on_damage_zone_body_entered(body: Node2D) -> void:
	if can_damage and body.has_method("take_damage"):
		$AnimatedSprite2D.modulate = Color.RED
		body.take_damage()
		can_damage = false
		$cooldown_timer.start()
		

func _on_cooldown_timer_timeout() -> void:
	$AnimatedSprite2D.modulate = Color.WHITE
	can_damage = true
