extends AnimatableBody2D

@export var p0: Vector2
@export var p1: Vector2
@export var speed: float
var dst: Vector2
var reverse: bool

func _ready() -> void:
	global_position = p0
	dst = p1
	reverse = false

func _physics_process(delta: float) -> void:
	position = position.move_toward(dst, speed * delta)
	if position.distance_to(dst) < 0.1:
		reverse = !reverse
		dst = p0 if reverse else p1
