extends Node2D

enum State {
	DORMANT,
	WAIT,
	ACTIVATING,
	IDLING,
	RETRACT,
}

@onready var animated_sprite = $AnimatedSprite2D
@onready var trigger = $Trigger
@onready var area = $Area2D
@onready var activation_timer = $ActivationTimer
@onready var idle_timer = $IdleTimer
var state: State

func _ready() -> void:
	state = State.DORMANT
	area.process_mode = Node.PROCESS_MODE_DISABLED
	animated_sprite.play("dormant")

func _on_trigger_body_entered(_body: Node2D) -> void:
	if not state == State.DORMANT:
		return
	activation_timer.start()
	state = State.WAIT

func _on_activation_timer_timeout() -> void:
	state = State.ACTIVATING
	area.process_mode = Node.PROCESS_MODE_INHERIT
	animated_sprite.play("activated")

func _on_area_2d_body_entered(_body: Node2D) -> void:
	global_variables.game_over.emit()
	
func _on_idle_timer_timeout() -> void:
	animated_sprite.play("retract")
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if state == State.ACTIVATING:
		state = State.IDLING
		idle_timer.start()
	elif state == State.IDLING:
		area.process_mode = Node.PROCESS_MODE_DISABLED
		state = State.DORMANT
		animated_sprite.play("dormant")
