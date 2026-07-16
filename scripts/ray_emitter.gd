extends Node2D

class_name RayEmitter
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

@export var direction: Direction = Direction.RIGHT
@export var width: float = 2.0
@export var length: float = 60.0

@onready var trigger: Area2D = $Trigger
@onready var segment: AnimatedSprite2D = $Segment
@onready var hit: AnimatedSprite2D = $Hit
@onready var ray_sound: AudioStreamPlayer = $"../AudioStreamManager/LaserSound"
@onready var ray_a: RayCast2D = $RayA
@onready var ray_b: RayCast2D = $RayB

var direction_vector: Vector2
var pre_length: float = 0.0

func _ready() -> void:
	if not ray_sound.playing:
		ray_sound.play()
	trigger.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	trigger.get_node("CollisionShape2D").shape.size = Vector2(16.0, 16.0)
	match direction:
			Direction.LEFT:
				ray_a.position.y = -width * 0.5
				ray_b.position.y = width * 0.5
				direction_vector = Vector2(-1.0, 0.0)
				segment.play("horizontal")
				hit.play("left");
			Direction.RIGHT:
				ray_a.position.y = width * 0.5
				ray_b.position.y = -width * 0.5
				direction_vector = Vector2(1.0, 0.0)
				segment.play("horizontal")
				hit.play("right");
			Direction.UP:
				ray_a.position.x = -width * 0.5
				ray_b.position.x = width * 0.5
				direction_vector = Vector2(0.0, -1.0)
				segment.play("vertical")
				hit.play("up");
			Direction.DOWN:
				ray_a.position.x = width * 0.5
				ray_b.position.x = -width * 0.5
				direction_vector = Vector2(0.0, 1.0)
				segment.play("vertical")
				hit.play("down");
	ray_a.target_position = ray_a.position + direction_vector * length * 16.0
	ray_b.target_position = ray_b.position + direction_vector * length * 16.0

func _physics_process(_delta: float) -> void:
	if (not ray_a.is_colliding()) and (not ray_b.is_colliding()):
		return
	
	var point_a: Vector2 = ray_a.get_collision_point()
	var point_b: Vector2 = ray_b.get_collision_point()
	var ray_length_a = (point_a - ray_a.global_position).length()
	var ray_length_b = (point_b - ray_b.global_position).length()
	var ray_length = min(ray_length_a, ray_length_b)
	if abs(ray_length - pre_length) < 0.005:
		return
	
	var offset = direction_vector * ray_length * 0.5
	trigger.position = offset
	segment.position = offset
	hit.position = offset * 2.0 - (direction_vector * 8.0)
	if direction == Direction.UP or direction == Direction.DOWN:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(width, ray_length - 0.5)
		segment.scale = Vector2(1.0, ray_length / 16.0)
	elif direction == Direction.RIGHT or direction == Direction.LEFT:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(ray_length - 0.5, width)
		segment.scale = Vector2(ray_length / 16.0, 1.0)

func _on_trigger_body_entered(body: Node2D) -> void:
	if body.get_groups().count("player") > 0:
		global.game_over.emit()
