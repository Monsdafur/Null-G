extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var filter: ColorRect = $ColorRect

var stop: bool = false

func _ready() -> void:
	timer.start()

func _process(_delta: float) -> void:
	if stop:
		return
	var progress = timer.time_left / timer.wait_time
	filter.material.set_shader_parameter("scale", progress)
	filter.material.set_shader_parameter("time", timer.wait_time - timer.time_left)
	
	
func _on_timer_timeout() -> void:
	stop = true
