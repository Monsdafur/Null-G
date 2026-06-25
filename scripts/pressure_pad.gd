extends Area2D

@export var gravity_scale: int
@export var reversed: bool

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

var normal: Rect2i
var triggered: Rect2i

func _ready() -> void:
	normal = Rect2i(Vector2i(0, 8) * 16, Vector2i(16, 16)) if not reversed else Rect2i(Vector2i(2, 8) * 16, Vector2i(16, 16))
	triggered = Rect2i(Vector2i(1, 8) * 16, Vector2i(16, 16)) if not reversed else Rect2i(Vector2i(3, 8) * 16, Vector2i(16, 16))
	sprite.region_rect = normal
	shape.position = Vector2(0.0, 7.0) if not reversed else Vector2(0.0, -7.0)
	

func _on_body_entered(_body: Node2D) -> void:
	sprite.region_rect = triggered
	global.gravity_scale = gravity_scale

func _on_body_exited(_body: Node2D) -> void:
	sprite.region_rect = normal
