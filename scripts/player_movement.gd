extends CharacterBody2D

@export var speed = 96.0
@export var jump_velocity = -250.0

var direction: float
var allow_move: bool = false

func _physics_process(delta: float) -> void:
	up_direction = Vector2(0, -1) if global.gravity_scale == 1 else Vector2(0, 1)
	
	if not is_on_floor():
		velocity += get_gravity() * global.gravity_scale * delta
	elif Input.is_action_just_pressed("ui_up") and allow_move:
		velocity.y = jump_velocity * global.gravity_scale
	
	direction = Input.get_axis("ui_left", "ui_right") if allow_move else 0.0
	
	if not direction == 0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
