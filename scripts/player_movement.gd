extends CharacterBody2D

const SPEED = 96.0
const JUMP_VELOCITY = -250.0
var direction: float
var reverse: int

func _physics_process(delta: float) -> void:
	reverse = game_manager.gravity_scale
	up_direction = Vector2(0, -1) if reverse == 1 else Vector2(0, 1)
	
	if not is_on_floor():
		velocity += get_gravity() * reverse * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY * reverse

	direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
