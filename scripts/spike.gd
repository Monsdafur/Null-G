extends Node2D

enum State {
	DORMANT,
	ACTIVATING,
	IDLING,
	RETRACT,
}

@export var reversed: bool

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var activate_sound: AudioStreamPlayer = $"../AudioStreamManager/ActivationSound"

var state: State
var dormant_animation: String
var idle_animation: String
var activated_animation: String
var retract_animation: String
var activated: bool

func activate() -> void:
	if state == State.IDLING:
		return
	state = State.ACTIVATING
	activate_sound.play()
	animated_sprite.play(activated_animation)
	
func deactivate() -> void:
	if state == State.DORMANT:
		return
	state = State.RETRACT
	area.process_mode = Node.PROCESS_MODE_DISABLED
	activate_sound.play()
	animated_sprite.play(retract_animation)

func _ready() -> void:
	area.position.y = 5.0 if not reversed else -5.0
	dormant_animation = "dormant" if not reversed else "dormant_inverted"
	idle_animation = "idle" if not reversed else "idle_inverted"
	activated_animation = "activated" if not reversed else "activated_inverted"
	retract_animation = "retract" if not reversed else "retract_inverted"
	state = State.IDLING if activated else State.DORMANT
	area.process_mode = Node.PROCESS_MODE_INHERIT if activated else Node.PROCESS_MODE_DISABLED
	animated_sprite.play(idle_animation if activated else dormant_animation)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.get_groups().count("player") > 0:
		global.game_over.emit()

func _on_animated_sprite_2d_animation_finished() -> void:
	if state == State.ACTIVATING:
		state = State.IDLING
		animated_sprite.play(idle_animation)
		area.process_mode = Node.PROCESS_MODE_INHERIT
	elif state == State.RETRACT:
		state = State.RETRACT
		animated_sprite.play(dormant_animation)
