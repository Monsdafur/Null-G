extends CharacterBody2D

@export var speed = 96.0
@export var jump_velocity = -250.0

var direction: int
var allow_move: bool = false
var is_holding: bool = false
var is_pushing: bool = false
var box: CharacterBody2D
var box_offset: float

func _physics_process(delta: float) -> void:
	up_direction = Vector2(0, -1) if global.gravity_scale == 1 else Vector2(0, 1)
	
	if not is_on_floor():
		velocity += get_gravity() * global.gravity_scale * delta
	elif Input.is_action_just_pressed("jump") and allow_move:
		velocity.y = jump_velocity * global.gravity_scale
	
	direction = 0
	if allow_move:
		if Input.is_action_pressed("move_left"):
			direction -= 1
		if Input.is_action_pressed("move_right"):
			direction += 1
	
	if not direction == 0:
		velocity.x = speed * direction
	else:	
		velocity.x = move_toward(velocity.x, 0, speed)

	if is_on_floor() and is_holding and Input.is_action_pressed("interact"):
			is_pushing = true
			box.velocity.x = direction * speed * 0.2
			box.is_holding = true
	else:
		if is_holding:
			box.is_holding = false
		is_pushing = false

	move_and_slide()

func set_allow_move(state: bool) -> void:
	allow_move = state

func _on_interact_trigger_body_entered(body: Node2D) -> void:
	is_holding = true
	box = body

func _on_interact_trigger_body_exited(_body: Node2D) -> void:
	is_holding = false
	box.is_holding = false

func _on_crush_trigger_body_entered(_body: Node2D) -> void:
	global.game_over.emit()
