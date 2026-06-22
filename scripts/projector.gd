extends Node2D

enum ProjectorType {
	Entrance,
	Exit,
	TeleportIn,
	TeleportOut,
}

@export var type: ProjectorType

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

func _on_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
