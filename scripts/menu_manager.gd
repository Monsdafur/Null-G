extends Node2D

enum ButtonType {
	NONE,
	START,
	OPTIONS,
	QUIT,
}

@onready var start_button: Button = $MenuManager/StartButton
@onready var quit_button: Button = $MenuManager/QuitButton
@onready var fade_effect: AnimationPlayer = $FadeScreen/AnimationPlayer
@onready var title_fade: AnimationPlayer = $Title/AnimationPlayer
@onready var click_sound: AudioStreamPlayer = $ClickSound

var button_type: ButtonType = ButtonType.NONE
var chosen: bool = false

func _ready() -> void:
	start_button.grab_focus.call_deferred()
	fade_effect.animation_finished.connect(_on_transition_timeout)
	fade_effect.play("fade out")
	if global.main_menu_fade:
		pass

func _on_start_button_button_up() -> void:
	if chosen:
		return
	chosen = true
	click_sound.play()
	button_type = ButtonType.START
	title_fade.play("fade out")
	fade_effect.play("fade in")

func _on_options_button_button_up() -> void:
	if chosen:
		return
	chosen = true
	click_sound.play()
	button_type = ButtonType.OPTIONS
	fade_effect.play("fade in")

func _on_quit_button_button_up() -> void:
	if chosen:
		return
	chosen = true
	click_sound.play()
	button_type = ButtonType.QUIT
	title_fade.play("fade out")
	fade_effect.play("fade in")

func _on_transition_timeout(_anim_name: StringName) -> void:
	match button_type:
		ButtonType.START:
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		ButtonType.OPTIONS:
			get_tree().change_scene_to_file("res://scenes/option_menu.tscn")
		ButtonType.QUIT:
			global.quit_game()
