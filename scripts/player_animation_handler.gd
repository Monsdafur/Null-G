extends AnimationTree

@onready var player_movement: CharacterBody2D = $".."
@onready var sprite: Sprite2D = $"../Sprite2D"

signal death

var dead: bool = false
var started: bool = false

func _ready() -> void:
	set("parameters/conditions/dead", false)
	global.game_over.connect(_on_global_game_over)

func _process(_delta: float) -> void:
	sprite.flip_v = global.gravity_scale == -1
	sprite.offset = Vector2i(0, 0) if global.gravity_scale == 1 else Vector2i(0, 1)
	
	if not player_movement.is_on_floor():
		set("parameters/conditions/running", false)
		set("parameters/conditions/idle", false)
		if player_movement.velocity.y * global.gravity_scale < 0.0:
			set("parameters/conditions/falling", false)
			set("parameters/conditions/jump_up", true)
		else:
			set("parameters/conditions/falling", true)
			set("parameters/conditions/jump_up", false)
			
	else:
		set("parameters/conditions/falling", false)
		set("parameters/conditions/jump_up", false)
		if player_movement.direction == 0:
			set("parameters/conditions/running", false)
			set("parameters/conditions/idle", true)
		else:
			set("parameters/conditions/running", true)
			set("parameters/conditions/idle", false)
	
	if not player_movement.direction == 0:
		if player_movement.direction == -1:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

func _on_global_game_over() -> void:
	if dead:
		return
	dead = true
		
	set_process(false)
	set("parameters/conditions/dead", true)
	player_movement.set_physics_process(false)
	await animation_finished
	death.emit()

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "spawn":
		player_movement.allow_move = true
