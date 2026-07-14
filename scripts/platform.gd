extends AnimatableBody2D

class_name Platform
enum Type {
	NONE,
	HORIZONTAL,
	VERTICAL
}

@export var p0: Vector2
@export var p1: Vector2
@export var speed: float
@export var type: Type = Type.NONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bounce_sound: AudioStreamPlayer = $"../AudioStreamManager/ActivationSound"

var reversed: bool = false
var active: bool = false
var distance: float
var destination: Vector2

func set_reverse(value: bool) -> void:
	if not (reversed == value):
		active = true
	reversed = value
	destination = p0 if not reversed else p1
	distance = position.distance_to(destination)

func _ready() -> void:
	sprite.region_enabled = true
	var shape: RectangleShape2D = RectangleShape2D.new()
	if type == Type.HORIZONTAL:
		shape.size = Vector2(48.0, 16.0)
		sprite.region_rect = Rect2i(96, 80, 48, 16)
	elif type == Type.VERTICAL:
		shape.size = Vector2(16.0, 48.0)
		sprite.region_rect = Rect2i(144, 64, 16, 48)
	collision_shape.shape = shape

func _physics_process(delta: float) -> void:
	if not active:
		return
	position = position.move_toward(destination, speed * delta)
	if position.distance_squared_to(destination) < 0.025:
		if distance > 16.0:
			bounce_sound.play()
		active = false
