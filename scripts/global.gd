extends Node

var gravity_scale: int = 1
signal game_over
signal level_cleared

func set_gravity_scale(scale: int) -> void:
	gravity_scale = scale
