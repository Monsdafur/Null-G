extends Node2D

@export var frag_index: int
@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

var velocity: Vector2

func _ready() -> void:
	var theta: float = ((PI * 2.0) / 7.0) * frag_index
	velocity = Vector2(cos(theta), -sin(theta)) * 60.0
	sprite.region_rect = Rect2i(frag_index * 16, 0, 16, 16)
	sprite.z_index = 5

func _process(delta: float) -> void:
	sprite.self_modulate.a = timer.time_left / timer.wait_time
	position += velocity * delta


func _on_timer_timeout() -> void:
	queue_free()
