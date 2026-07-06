extends AnimationTree

@onready var player_movement: CharacterBody2D = $".."
@onready var sprite: Sprite2D = $"../Sprite2D"
@onready var state_machine: AnimationNodeStateMachinePlayback = get("parameters/playback")
@onready var death_sound: AudioStreamPlayer = $"../DeathSound"
@onready var spawn_sound: AudioStreamPlayer = $"../SpawnSound"
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

signal death
signal win

var dead: bool = false
var started: bool = false

func _ready() -> void:
	global.game_over.connect(_on_global_game_over)
	global.level_cleared.connect(_on_global_level_cleared)

func _process(_delta: float) -> void:
	sprite.flip_v = global.gravity_scale == -1
	
	if not player_movement.is_on_floor():
		if player_movement.velocity.y * global.gravity_scale < 0.0:
			state_machine.travel("jump_up")
		else:
			state_machine.travel("falling")
	else:
		if player_movement.is_pushing:
			if player_movement.direction == 0:
				state_machine.travel("push_idle")
			else:
				state_machine.travel("push")
		else:
			if player_movement.direction == 0:
				state_machine.travel("idle")
			else:
				state_machine.travel("running")
	
	if not player_movement.direction == 0:
		if player_movement.direction == -1:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	sprite.offset.x = -1.0 if sprite.flip_h else 0.0
	sprite.offset.y = 2.5 if sprite.flip_v else 0.0

func _on_global_game_over() -> void:
	if dead:
		return
	dead = true

	set_process(false)
	death_sound.play()
	state_machine.travel("death")
	player_movement.set_physics_process(false)
	while state_machine.get_current_node() != "death":
		await get_tree().process_frame
	await animation_finished
	sprite.visible = false
	death.emit()
	
func _on_global_level_cleared() -> void:
	if dead:
		return
	dead = true
	
	set_process(false)
	spawn_sound.play()
	state_machine.travel("death")
	player_movement.set_physics_process(false)
	while state_machine.get_current_node() != "death":
		await get_tree().process_frame
	await animation_finished
	sprite.visible = false
	win.emit()
