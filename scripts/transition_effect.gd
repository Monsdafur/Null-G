extends ColorRect

@onready var timer: Timer = $Timer

var finished: bool = false
var reverse: bool = false

func _ready() -> void:
	timer.start()

func _process(_delta: float) -> void:
	var progress = (timer.wait_time - timer.time_left) / timer.wait_time
	if reverse:
		progress = 1.0 - progress
	material.set_shader_parameter("dt", progress)
