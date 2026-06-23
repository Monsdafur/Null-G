extends Node2D

@export var max_level: int = 1
@export var level: int = 1
@export var atlas_width: int
@onready var level_layer: TileMapLayer = $LevelLayer
@onready var background_layer: TileMapLayer = $Background
@onready var player_spawn_timer: Timer = $PlayerSpawnDelay
@onready var transition_filter: CanvasLayer = $"TransitionFilter"

var ins_pressure_pad: Resource =  preload("res://scenes/pressure_pad.tscn")
var ins_platform: Resource = preload("res://scenes/platform.tscn")
var ins_spike: Resource = preload("res://scenes/spike.tscn")
var ins_player: Resource = preload("res://scenes/player.tscn")
var ins_projector: Resource = preload("res://scenes/projector.tscn")

var exit_reversed: bool = false
var entrance: Node2D
var exit: Node2D
var player: CharacterBody2D
var start_game: bool = false

var platforms: Array[AnimatableBody2D] = []
var spikes: Array[Node2D] = []
var projectors: Array[Node2D] = []
var pressure_pads: Array[Area2D] = []

func convert_position(grid_position: Vector2):
	return grid_position * 16.0 + Vector2(8.0, 8.0)

func load_pressure_pad(cell: Dictionary) -> void:
	var reversed: bool
	if int(cell["gid"]) == 32:
		reversed = false
	elif int(cell["gid"]) == 25: 
		reversed = true
	else:
		return
	var pressure_pad: Area2D = ins_pressure_pad.instantiate()
	var pad_position: Vector2 = Vector2(float(cell["x"]), float(cell["y"]))
	pad_position += Vector2(0.0, 1.0) if reversed else Vector2(0.0, -1.0)
	pressure_pad.reversed = reversed
	pressure_pad.gravity_scale = 1 if reversed else -1
	pressure_pad.position = convert_position(pad_position)
	pressure_pad.z_index = 2
	add_child(pressure_pad)
	pressure_pads.append(pressure_pad)

func load_tilemap(tilemap: TileMapLayer, key: String, json_data: Dictionary) -> void:
	for cell in json_data[key]:
		var tile_position: Vector2i = Vector2i(cell["x"], cell["y"])
		var atlas_position: Vector2i = Vector2i(int(cell["gid"]) % atlas_width, int(cell["gid"]) / atlas_width);
		tilemap.set_cell(tile_position, 0, atlas_position)
		load_pressure_pad(cell)
		
func load_objects(object_data: Array) -> void:
	for obj in object_data:
		var object_position: Vector2 = convert_position(Vector2(float(obj["x"]), float(obj["y"])))
		var id: int = int(obj["gid"])
		if id == 11 or id == 19:
			var spike: Node2D = ins_spike.instantiate()
			spike.reversed = id == 19
			spike.position = object_position
			spike.z_index = 1
			add_child(spike)
			spikes.append(spike)
		
func load_projectors(projector_data: Array) -> void:
	for prj in projector_data:
		var projector_position: Vector2 = convert_position(Vector2(float(prj["x"]), float(prj["y"])))
		var projector: Node2D = ins_projector.instantiate()
		match String(prj["type"]):
			"entrance": 
				projector.type = Projector.Type.ENTRANCE
				entrance = projector
			"exit": 
				projector.type = Projector.Type.EXIT
				exit = projector
		projector.position = projector_position
		projector.reversed = bool(prj["reversed"])
		projector.z_index = 1
		add_child(projector)
		projectors.append(projector)

func clear_level() -> void:
	for platform in platforms:
		platform.queue_free()
	platforms.clear()
	for spike in spikes:
		spike.queue_free()
	spikes.clear()
	for pad in pressure_pads:
		pad.queue_free()
	pressure_pads.clear()
	for projector in projectors:
		projector.queue_free()
	projectors.clear()
	level_layer.clear()
	background_layer.clear()
	
func load_level() -> void:
	clear_level()
	# Json data loading
	var level_file: String = "res://data/levels/level_%d.json" % level
	var file: FileAccess = FileAccess.open(level_file, FileAccess.READ)
	if file == null:
		push_error("Failed to open level file %s" % level_file)
		return
	var text_data: String = file.get_as_text()
	file.close()
	
	var json_data: Dictionary = JSON.parse_string(text_data)
	
	# Begin loading to tilemap
	load_tilemap(level_layer, "level", json_data)
	load_tilemap(background_layer, "background", json_data)
	
	if json_data.has("platform"):
		for pf in json_data["platform"]:
			var platform: AnimatableBody2D = ins_platform.instantiate()
			var p0: Vector2 = convert_position(Vector2(float(pf["x0"]), float(pf["y0"])))
			var p1: Vector2 = convert_position(Vector2(float(pf["x1"]), float(pf["y1"])))
			platform.position = p0
			platform.z_index = 2
			platform.p0 = p0
			platform.p1 = p1
			platform.speed = float(pf["speed"])
			add_child(platform)
			platforms.append(platform)
	
	load_objects(json_data["objects"])
	load_projectors(json_data["projector"])
	assert(entrance.type == Projector.Type.ENTRANCE)
	assert(exit.type == Projector.Type.EXIT)
	exit.win.connect(_on_player_win)
	game_manager.gravity_scale = 1 if not entrance.reversed else -1
	
func spanw_player() -> void:
	player = ins_player.instantiate()
	player.get_node("AnimationTree").death.connect(_on_player_death)
	player.get_node("Sprite2D").flip_v = entrance.reversed
	var offset: Vector2 = Vector2(1.0, -5.0) if not entrance.reversed else Vector2(0.0, 5.0)
	player.position = entrance.position + offset
	player_spawn_timer.start()
	await player_spawn_timer.timeout
	add_child(player)
	player.get_node("Sprite2D").visible = true
	player.get_node("Sprite2D").region_enabled = false
	

func _ready() -> void:
	transition_filter.timer.start()
	load_level()
	spanw_player()
	start_game = true

func _on_player_win() -> void:
	level += 1
	if level > max_level:
		level = 1
	var player_animation_tree: AnimationTree = player.get_node("AnimationTree")
	player.allow_move = false
	player_animation_tree.set("parameters/conditions/dead", true)
	
	await player_animation_tree.animation_finished
	player.queue_free()
	await get_tree().process_frame
	transition_filter.reverse = true;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	load_level()
	transition_filter.reverse = false;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	spanw_player()
	
func _on_player_death() -> void:
	player.queue_free()
	await get_tree().process_frame
	transition_filter.reverse = true;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	load_level()
	transition_filter.reverse = false;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	spanw_player()
