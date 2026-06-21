extends Node2D

@onready var player_movement = $".."
@onready var animated_sprite = $"../AnimatedSprite2D"

func _ready() -> void:
	game_manager.game_over.connect(_on_game_manager_game_over)

func _process(_delta: float) -> void:
	animated_sprite.flip_v = player_movement.reverse == -1
	animated_sprite.offset = Vector2i(0, 0) if player_movement.reverse == 1 else Vector2i(0, 1)
	
	if not player_movement.is_on_floor():
		animated_sprite.play("jump_up" if player_movement.velocity.y < 0.0 else "falling")
		
	if player_movement.direction:
		if player_movement.is_on_floor():
			animated_sprite.play("running")
		if player_movement.direction == -1:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
	else:
		if player_movement.is_on_floor():
			animated_sprite.play("idle")

func _on_game_manager_game_over() -> void:
	set_process(false)
	animated_sprite.play("death")
	player_movement.set_physics_process(false)
	await animated_sprite.animation_finished
	animated_sprite.visible = false
