extends Control

enum ButtonType {
	START,
	QUIT,
}

@onready var start_button: TextureButton = $StartButton
@onready var quit_button: TextureButton = $QuitButton
@onready var timer: Timer = $Timer
@onready var transition_filter: ColorRect = $"../CanvasLayer/ColorRect"

var button_type: ButtonType

func _ready() -> void:
	start_button.grab_focus.call_deferred()
	transition_filter.process_mode = Node.PROCESS_MODE_DISABLED
	transition_filter.visible = false
	transition_filter.get_node("Timer").timeout.connect(_on_transition_timeout)

func _on_start_button_button_up() -> void:
	button_type = ButtonType.START
	transition_filter.reverse = true
	transition_filter.process_mode = Node.PROCESS_MODE_INHERIT
	transition_filter.visible = true
	transition_filter.timer.start()

func _on_quit_button_button_up() -> void:
	button_type = ButtonType.QUIT
	transition_filter.reverse = true
	transition_filter.process_mode = Node.PROCESS_MODE_INHERIT
	transition_filter.visible = true
	transition_filter.timer.start()

func _on_transition_timeout() -> void:
	match button_type:
		ButtonType.START:
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		ButtonType.QUIT:
			get_tree().quit()
