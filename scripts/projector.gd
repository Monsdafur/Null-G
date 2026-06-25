extends Node2D

class_name Projector
enum Type {
	NONE,
	ENTRANCE,
	EXIT,
	TELEPORT_IN,
	TELEPORT_OUT,
}

@export var type: Type = Type.NONE
@export var reversed: bool

@onready var collider: StaticBody2D = $Collider
@onready var trigger: Area2D = $Trigger
@onready var sprite: Sprite2D = $Sprite2D

signal win

func _ready() -> void:
	sprite.region_rect = Rect2i(64, 128, 16, 16) if not reversed else Rect2i(80, 128, 16, 16)
	collider.position = Vector2(0.0, 5.5) if not reversed else Vector2(0.0, -5.5)
	trigger.position = Vector2(0.0, 2.0) if not reversed else Vector2(0.0, -2.0)

func _on_trigger_body_entered(_body: Node2D) -> void:
	if (global.gravity_scale < 0.0 and reversed) or (global.gravity_scale > 0.0 and not reversed):
		if (type == Type.EXIT):
			win.emit()
