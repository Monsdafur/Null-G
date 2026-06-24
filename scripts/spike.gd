extends Node2D

enum State {
	DORMANT,
	WAIT,
	ACTIVATING,
	IDLING,
	RETRACT,
}

@export var reversed: bool

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger: Area2D = $Trigger
@onready var area: Area2D = $Area2D
@onready var activation_timer: Timer = $ActivationTimer
@onready var idle_timer: Timer = $IdleTimer

var state: State
var dormant_animation: String
var activated_animation: String
var retract_animation: String

func _ready() -> void:
	state = State.DORMANT
	area.process_mode = Node.PROCESS_MODE_DISABLED
	trigger.position.y = 6.0 if not reversed else -6.0
	area.position.y = 2.0 if not reversed else -2.0
	dormant_animation = "dormant" if not reversed else "dormant_inverted"
	activated_animation = "activated" if not reversed else "activated_inverted"
	retract_animation = "retract" if not reversed else "retract_inverted"
	animated_sprite.play(dormant_animation)

func _on_trigger_body_entered(_body: Node2D) -> void:
	if not state == State.DORMANT:
		return
	activation_timer.start()
	state = State.WAIT

func _on_activation_timer_timeout() -> void:
	state = State.ACTIVATING
	area.process_mode = Node.PROCESS_MODE_INHERIT
	animated_sprite.play(activated_animation)
	await animated_sprite.animation_finished
	state = State.IDLING
	idle_timer.start()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	game_manager.game_over.emit()
	
func _on_idle_timer_timeout() -> void:
	animated_sprite.play(retract_animation)
	await animated_sprite.animation_finished
	area.process_mode = Node.PROCESS_MODE_DISABLED
	state = State.DORMANT
	animated_sprite.play(dormant_animation)
