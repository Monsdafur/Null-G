extends Node

var main_menu_fade: bool = false
var gravity_scale: int = 1
var sound_on: bool = true
var music_on: bool = true
var effect_on: bool = true
var current_level: int = 0
var in_game: bool = false

@warning_ignore("unused_signal")
signal game_over
@warning_ignore("unused_signal")
signal level_cleared
@warning_ignore("unused_signal")
signal gravity_reversed

func set_gravity_scale(scale: int) -> void:
	gravity_scale = scale
	gravity_reversed.emit()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var path: String = String("user://game.json")
	var game_data: Dictionary
	if not FileAccess.file_exists(path):
		print("Game data file do not exist will create new file")
	else:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var string_data: String = file.get_as_text()
		file.close()
		game_data = JSON.parse_string(string_data)
		sound_on = bool(game_data["settings"]["sound on"])
		music_on = bool(game_data["settings"]["music on"])
		effect_on = bool(game_data["settings"]["effect on"])
		current_level = int(game_data["progress"]["current level"])

func save_progress() -> void:
	var path: String = String("user://game.json")
	var game_data: Dictionary
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	var string_data: String
	game_data["settings"] = {}
	game_data["progress"] = {}
	game_data["settings"]["sound on"] = sound_on
	game_data["settings"]["music on"] = music_on
	game_data["settings"]["effect on"] = effect_on
	game_data["progress"]["current level"] = current_level
	string_data = JSON.stringify(game_data, "\t")
	file.store_string(string_data)
	file.close()

func quit_game() -> void:
	save_progress()
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = 'https://monsdafur.itch.io/null';")
	else:
		get_tree().quit()
