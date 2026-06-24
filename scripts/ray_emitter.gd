extends Node2D

class_name RayEmitter
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

@export var direction: Direction = Direction.RIGHT
@export var length: int = 30
@onready var sprite_frames: SpriteFrames = preload("res://assets/animation/ray.tres")
@onready var ray: RayCast2D = $RayCast2D
@onready var trigger: Area2D = $Trigger

var sprites: Array[AnimatedSprite2D]
var direction_vector: Vector2
var pre_length: int
var segment_animation: String
var hit_animation: String

func switch_animation(index: int, animation: String) -> void:
	var frame: int = sprites[index].frame
	var progress: float = sprites[index].frame_progress
	sprites[index].play(animation)
	sprites[index].frame = frame
	sprites[index].frame_progress = progress

func _ready() -> void:
	trigger.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	match direction:
			Direction.LEFT:
				direction_vector = Vector2(-1.0, 0.0)
				segment_animation = "horizontal_segment"
				hit_animation = "left_hit"
			Direction.RIGHT:
				direction_vector = Vector2(1.0, 0.0)
				segment_animation = "horizontal_segment"
				hit_animation = "right_hit"
			Direction.UP:
				direction_vector = Vector2(0.0, -1.0)
				segment_animation = "vertical_segment"
				hit_animation = "up_hit"
			Direction.DOWN:
				direction_vector = Vector2(0.0, 1.0)
				segment_animation = "vertical_segment"
				hit_animation = "down_hit"
				
	for i: int in range(length):
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.position = direction_vector * float(i + 1) * 16.0
		sprite.sprite_frames = sprite_frames
		sprite.visible = false
		sprite.z_index = -1
		add_child(sprite)
		sprites.append(sprite)
		sprite.play(segment_animation)
			
	ray.target_position = sprites.back().position + direction_vector * 8.0

func _process(_delta: float) -> void:
	if not ray.is_colliding():
		return
	
	var true_length = (ray.get_collision_point() - global_position).length()
	var current_length = int(floor(true_length / 16.0))
	if (current_length == pre_length):
		return
	pre_length = current_length
	
	var offset = direction_vector * true_length * 0.5
	trigger.position = offset
	if direction == Direction.UP or direction == Direction.DOWN:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(4.0, true_length)
	elif direction == Direction.RIGHT or direction == Direction.LEFT:
		trigger.get_node("CollisionShape2D").shape.size = Vector2(true_length, 4.0)
	
	for i: int in range(length):
		switch_animation(i, segment_animation)
		sprites[i].visible = i <= current_length
	switch_animation(current_length - 1, hit_animation)

func _on_trigger_body_entered(_body: Node2D) -> void:
	game_manager.game_over.emit()
