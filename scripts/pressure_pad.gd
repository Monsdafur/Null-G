extends Area2D

@export var reversed: bool
@export var activation_functions: Array[Callable]
@export var deactivation_functions: Array[Callable]

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer

var bodies: int = 0
var started: bool = false

func _ready() -> void:
	global.gravity_reversed.connect(_on_gravity_reversed)
	sprite.region_rect = Rect2i(16, 480, 16, 16) if not reversed else Rect2i(32, 480, 16, 16)
	shape.position = Vector2(0.0, 6.0) if not reversed else Vector2(0.0, -6.0)
	update_state()
	started = true
	
func update_state() -> void:
	var is_active: bool = (reversed and global.gravity_scale == -1) or (not reversed and global.gravity_scale == 1)
	if is_active:
		set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		shape.set_deferred("disabled", false)
	else:
		set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		shape.set_deferred("disabled", true)
		bodies = 0
		if started and timer.is_inside_tree():
			timer.start()
		
func _on_body_entered(_body: Node2D) -> void:
	bodies += 1
	if bodies > 1:
		return
	sprite.visible = false
	for function: Callable in activation_functions:
		if function.is_valid():
			function.call()
			
func _on_timer_timeout() -> void:
	sprite.visible = true
	for function: Callable in deactivation_functions:
		if function.is_valid():
			function.call()

func _on_body_exited(_body: Node2D) -> void:
	bodies -= 1
	if bodies > 0:
		return
	if timer.is_inside_tree():
		timer.start()

func _on_gravity_reversed() -> void:
	if global.in_game:
		update_state()
