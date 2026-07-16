extends CharacterBody2D

@onready var death_timer: Timer = $DeathTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite
@onready var highlight: Sprite2D = $Highlight
@onready var hit_sound: AudioStreamPlayer = $"../AudioStreamManager/ActivationSound"

var box_fragments = preload("res://assets/textures/box_fragments.png")
var ins_fragment = preload("res://scenes/fragment.tscn")

var is_pushing: bool = false
var dead: bool = false
var on_floor_last_frame: bool = true
var frame_count: int = 0

func _physics_process(delta: float) -> void:
	up_direction = Vector2(0, -1) if global.gravity_scale == 1 else Vector2(0, 1)
	
	if not is_on_floor():
		velocity += get_gravity() * global.gravity_scale * delta
	elif (not on_floor_last_frame) and frame_count > 30:
		hit_sound.play()
		
	if not is_pushing or not is_on_floor():
		velocity.x = 0.0
	
	on_floor_last_frame = is_on_floor()
	move_and_slide()
	if frame_count <= 30:
		frame_count += 1

func _on_death_trigger_body_entered(body: Node2D) -> void:
	if body != get_node(".") and !dead and body.get_groups().count("player") == 0:
		dead = true
		hit_sound.play()
		sprite.visible = false
		collision_shape.queue_free()
		set_physics_process(false)
		for i in range(7):
			var fragment: Node2D = ins_fragment.instantiate()
			fragment.frag_index = i
			add_child(fragment)
		death_timer.start()
		await death_timer.timeout
		queue_free()

func _on_death_trigger_area_entered(area: Area2D) -> void:
	if area.get_groups().count("spike") > 0:
		dead = true
		hit_sound.play()
		sprite.visible = false
		collision_shape.queue_free()
		set_physics_process(false)
		for i in range(7):
			var fragment: Node2D = ins_fragment.instantiate()
			fragment.frag_index = i
			add_child(fragment)
		death_timer.start()
		await death_timer.timeout
		queue_free()
