extends Node2D

@onready var pause_menu: Control = $PauseMenu
@onready var resume_button: Button = $PauseMenu/Resume
@onready var menu_button: Button = $PauseMenu/MainMenu
@onready var game_complete_timer: Timer = $GameCompleteTimer
@onready var fade_effect: AnimationPlayer = $FadeScreen/AnimationPlayer
@onready var click_sound: AudioStreamPlayer = $ClickSound

var option_chosen: bool = false

func pause() -> void:
	get_tree().paused = true
	pause_menu.visible = true
	resume_button.grab_focus.call_deferred()
	
func resume() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	
func _ready() -> void:
	var sound_bus: int = AudioServer.get_bus_index("Sound")
	AudioServer.set_bus_mute(sound_bus, not global.sound_on)
	resume()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause()

func _on_resume_button_up() -> void:
	if option_chosen:
		return
	click_sound.play()
	resume()

func _on_main_menu_button_up() -> void:
	if option_chosen:
		return
	option_chosen = true
	click_sound.play()
	fade_effect.play("fade in")
	await fade_effect.animation_finished
	get_tree().paused = false
	global.main_menu_fade = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_button_up() -> void:
	if option_chosen:
		return
	option_chosen = true
	click_sound.play()
	fade_effect.play("fade in")
	await fade_effect.animation_finished
	global.quit_game()

func _on_game_complete_trigger_body_entered(body: Node2D) -> void:
	if body.get_groups().count("player") > 0:
		body.queue_free()
		game_complete_timer.start()
		await game_complete_timer.timeout
		fade_effect.play("fade in")
		await fade_effect.animation_finished
		get_tree().change_scene_to_file("res://scenes/end_scene.tscn")
		global.current_level = 0
