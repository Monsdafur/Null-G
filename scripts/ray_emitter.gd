extends Node2D

class_name RayEmitter
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

@export var direction: Direction = Direction.RIGHT
@onready var ray: RayCast2D = $RayCast2D
@onready var trigger: Area2D = $Trigger
@onready var segment: AnimatedSprite2D = $Segment
@onready var hit: AnimatedSprite2D = $Hit
@onready var ray_sound: AudioStreamPlayer = $"../AudioStreamManager/LaserSound"

var direction_vector: Vector2
var pre_length: float = 0.0

func _ready() -> void:
	if not ray_sound.playing:
		ray_sound.play()
	trigger.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	trigger.get_node("CollisionShape2D").shape.size = Vector2(16.0, 16.0)
	match direction:
			Direction.LEFT:
				direction_vector = Vector2(-1.0, 0.0)
				segment.play("horizontal")
				hit.play("left");
			Direction.RIGHT:
				direction_vector = Vector2(1.0, 0.0)
				segment.play("horizontal")
				hit.play("right");
			Direction.UP:
				direction_vector = Vector2(0.0, -1.0)
				segment.play("vertical")
				hit.play("up");
			Direction.DOWN:
				direction_vector = Vector2(0.0, 1.0)
				segment.play("vertical")
				hit.play("down");
	ray.target_position = ray.position + direction_vector * 30.0 * 16.0

func _process(_delta: float) -> void:
	if not ray.is_colliding():
		return
	
	var point: Vector2 = ray.get_collision_point()
	var length = (point - ray.global_position).length()
	if abs(length - pre_length) < 0.005:
		return
	
	var offset = ray.position + direction_vector * length * 0.5
	trigger.position = offset
	segment.position = offset
	hit.global_position = point - direction_vector * 8.0
	if direction == Direction.UP or direction == Direction.DOWN:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(2.0, length)
		segment.scale = Vector2(1.0, length / 16.0)
	elif direction == Direction.RIGHT or direction == Direction.LEFT:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(length, 2.0)
		segment.scale = Vector2(length / 16.0, 1.0)

func _on_trigger_body_entered(_body: Node2D) -> void:
	global.game_over.emit()
