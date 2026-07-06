extends Node2D

@onready var sound_checkbox: Button = $MenuManager/SoundCheckbox
@onready var music_checkbox: Button = $MenuManager/MusicCheckbox
@onready var effect_checkbox: Button = $MenuManager/WaterEffectCheckbox
@onready var return_button: Button = $MenuManager/Return
@onready var transition_filter: CanvasLayer = $TransitionFilter

func _ready() -> void:
	print("YES" if global.sound_on else "NO")
	sound_checkbox.set_state(global.sound_on)
	music_checkbox.set_state(global.music_on)
	effect_checkbox.set_state(global.effect_on)
	sound_checkbox.grab_focus.call_deferred()
	transition_filter.timer.start()

func _on_sound_checkbox_toggle(state: bool) -> void:
	global.sound_on = state

func _on_music_checkbox_toggle(state: bool) -> void:
	global.music_on = state
	
func _on_effect_checkbox_toggle(state: bool) -> void:
	global.effect_on = state
	
func _on_return_button_up() -> void:
	transition_filter.reverse = true
	transition_filter.timer.start()
	await transition_filter.timer.timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
