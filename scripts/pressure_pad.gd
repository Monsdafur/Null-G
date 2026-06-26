extends Area2D

@export var reversed: bool
@export var function: Callable

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	sprite.region_rect = Rect2i(Vector2i(0, 8) * 16, Vector2i(16, 16)) if not reversed else Rect2i(Vector2i(2, 8) * 16, Vector2i(16, 16))
	shape.position = Vector2(0.0, 7.0) if not reversed else Vector2(0.0, -7.0)

func _on_body_entered(_body: Node2D) -> void:
	sprite.visible = false
	function.call()

func _on_body_exited(_body: Node2D) -> void:
	sprite.visible = true
