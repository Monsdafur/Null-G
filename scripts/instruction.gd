extends Node2D

@export var target: Vector2
@export var player: CharacterBody2D
@export var radius: float

@onready var sprite: Sprite2D = $Sprite2D

func _process(delta: float) -> void:
	if player == null:
		return
	var distance: float = clamp(player.position.distance_to(target) / radius, 0.0, 1.0)
	sprite.self_modulate.a = 1.0 - distance
