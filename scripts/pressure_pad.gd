extends Area2D

@export var gravity_scale: int
@onready var sprite_animation := $AnimatedSprite2D

func _on_body_entered(_body: Node2D) -> void:
	game_manager.gravity_scale = gravity_scale
	sprite_animation.play("triggered")

func _on_body_exited(_body: Node2D) -> void:
	sprite_animation.play("not_trigger")
