extends Node

var gravity_scale: int = 1

@warning_ignore("unused_signal")
signal game_over
@warning_ignore("unused_signal")
signal level_cleared

func set_gravity_scale(scale: int) -> void:
	gravity_scale = scale
