extends Node2D

@export var level: int = 1
@export var max_level: int = 1
@export var atlas_width: int
@onready var player_spawn_timer: Timer = $PlayerSpawnDelay
@onready var transition_filter: CanvasLayer = $TransitionFilter
@onready var glitch_filter: CanvasLayer = $GlitchFilter

var tileset: Resource = preload("res://assets/tileset/level.tres")

var ins_pressure_pad: Resource = preload("res://scenes/pressure_pad.tscn")
var ins_platform: Resource = preload("res://scenes/platform.tscn")
var ins_spike: Resource = preload("res://scenes/spike.tscn")
var ins_player: Resource = preload("res://scenes/player.tscn")
var ins_projector: Resource = preload("res://scenes/projector.tscn")
var ins_emitter: Resource = preload("res://scenes/ray_emitter.tscn")
var ins_box: Resource = preload("res://scenes/box.tscn")

var map_data: Dictionary
var map_width: int
var has_entrance: bool = false
var tilemap_layers: Array[TileMapLayer]
var projectors: Array[Node2D]
var spikes: Array[Node2D]
var platforms: Array[AnimatableBody2D]
var emitters: Array[Node2D]
var pressure_pads: Array[Area2D]
var boxes: Array[CharacterBody2D]
var player: CharacterBody2D

var player_spawn_point: Vector2

func convert_position(grid_position: int, map_width: int) -> Vector2:
	var x: int = grid_position % map_width
	var y: int = grid_position / map_width
	return Vector2i(x, y)
	
func load_map_data() -> void:
	var path: String = String("res://data/levels/level%d.tmj" % level)
	if not FileAccess.file_exists(path):
		print("File do not exist")
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var string_data = file.get_as_text()
	file.close()
	
	map_data = JSON.parse_string(string_data)
	
func load_level() -> void:
	map_width = map_data["width"]
	var layers: Array = map_data["layers"]
	
	var order: int = 0
	for layer: Dictionary in layers:
		if layer["type"] == "tilelayer":
			load_tilemap_layer(layer, order)
			order += 1
		elif layer["type"] == "objectgroup":
			load_objects(layer)
			
func load_spike(tile_position: Vector2i, reversed: bool) -> void:
	var spike: Node2D = ins_spike.instantiate()
	spike.reversed = reversed
	spike.position = Vector2i(tile_position) * 16.0 + Vector2(8.0, 8.0)
	spike.z_index = 1
	add_child(spike)
	spikes.append(spike)
	
func load_box(tile_position: Vector2i) -> void:
	var box: Node2D = ins_box.instantiate()
	box.position = Vector2i(tile_position) * 16.0 + Vector2(8.0, 8.0)
	box.z_index = 1
	add_child(box)
	boxes.append(box)
	
func load_emitter(tile_position: Vector2i, gid: int) -> void:
	var direction: RayEmitter.Direction
	if gid == 48:
		direction = RayEmitter.Direction.RIGHT
	elif gid == 49:
		direction = RayEmitter.Direction.DOWN
	elif gid == 50:
		direction = RayEmitter.Direction.UP
	elif gid == 51:
		direction = RayEmitter.Direction.LEFT
		
	var emitter: Node2D = ins_emitter.instantiate()
	emitter.position = Vector2i(tile_position) * 16.0 + Vector2(8.0, 8.0)
	emitter.direction = direction
	add_child(emitter)
	emitters.append(emitter)
			
func load_tilemap_layer(data: Dictionary, order: int) -> void:
	var tilemap_data = data["data"]
	var layer: TileMapLayer = TileMapLayer.new()
	layer.tile_set = tileset
	layer.z_index = order
	
	var p: int = -1
	for gid: int in tilemap_data:
		p += 1
		if gid == 0:
			continue
		gid -= 1
		var atlas_position: Vector2i = convert_position(gid, atlas_width)
		var tile_position: Vector2i = convert_position(p, map_width)
		if gid == 56 or gid == 59:
			load_spike(tile_position, gid == 59)
		elif gid == 70:
			load_box(tile_position)
		elif gid == 48 or gid == 49 or gid == 50 or gid == 51:
			load_emitter(tile_position, gid)
			layer.set_cell(tile_position, 0, atlas_position)
		else:
			layer.set_cell(tile_position, 0, atlas_position)
	
	add_child(layer)
	tilemap_layers.append(layer)
	
func load_projector(data: Dictionary) -> void:
	var reversed = data["gid"] == 70
	var type: Dictionary = data["properties"][0]
	var projector: Node2D = ins_projector.instantiate()
	var projector_position = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	match type["value"]:
		"entrance":
			if has_entrance:
				print("Cant have more than 1 entrance, skipping")
				return
			player_spawn_point = projector_position
			player_spawn_point += Vector2(1.0, -5.0) if not reversed else Vector2(1.0, 5.0)
			has_entrance = true
			global.gravity_scale = 1 if not reversed else -1
			projector.type = Projector.Type.ENTRANCE
		"exit":
			projector.type = Projector.Type.EXIT
	projector.reversed = reversed
	projector.position = projector_position
	add_child(projector)
	projectors.append(projector)
	
func load_platform(data: Dictionary) -> void:
	var speed: float = data["properties"][0]["value"]
	var x1: int = data["properties"][1]["value"]
	var y1: int = data["properties"][2]["value"]
	var p0: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	var p1: Vector2 = Vector2(x1 * 16.0, y1 * 16.0) + Vector2(8.0, 8.0)
	
	var platform: AnimatableBody2D = ins_platform.instantiate()
	platform.position = p0
	platform.z_index = 2
	platform.p0 = p0
	platform.p1 = p1
	platform.speed = speed
	add_child(platform)
	platforms.append(platform)
	
func load_pressure_pad(data: Dictionary) -> void:
	var reversed = data["gid"] == 67
	var pad_type: String = data["properties"][0]["value"]
	var pressure_pad: Area2D = ins_pressure_pad.instantiate()
	var pad_position: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	pressure_pad.reversed = reversed
	pressure_pad.position = pad_position
	pressure_pad.z_index = 2
	
	match pad_type:
		"gravity pad":
			var gravity: int = data["properties"][1]["value"]
			pressure_pad.function = global.set_gravity_scale.bind(gravity)
			
	add_child(pressure_pad)
	pressure_pads.append(pressure_pad)
	
func load_objects(data: Dictionary) -> void:
	var objects_data: Array = data["objects"]
	for object: Dictionary in objects_data:
		match object["name"]:
			"projector":
				load_projector(object)
			"platform":
				load_platform(object)
			"pressure pad":
				load_pressure_pad(object)

func spawn_player() -> void:
	if not has_entrance:
		print("No entrance found player will not spawning")
		return
	player = ins_player.instantiate()
	player.position = player_spawn_point
	player_spawn_timer.start()
	add_child(player)
	player.get_node("AnimationTree").death.connect(_on_player_death)
	player.get_node("AnimationTree").win.connect(_on_player_win)

func clear_level() -> void:
	player.queue_free()
	for tilemap_layer: TileMapLayer in tilemap_layers:
		tilemap_layer.queue_free()
	tilemap_layers.clear()
	for projector: Node2D in projectors:
		projector.queue_free()
	projectors.clear()
	for spike: Node2D in spikes:
		spike.queue_free()
	spikes.clear()
	for emitter: Node2D in emitters:
		emitter.queue_free()
	emitters.clear()
	for platform: AnimatableBody2D in platforms:
		platform.queue_free()
	platforms.clear()
	for pad: Area2D in pressure_pads:
		pad.queue_free()
	pressure_pads.clear()
	for box: CharacterBody2D in boxes:
		box.queue_free()
	boxes.clear()
	has_entrance = false
	
func reload() -> void:
	player_spawn_timer.start()
	await player_spawn_timer.timeout
	transition_filter.reverse = true;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	clear_level()
	load_level()
	transition_filter.reverse = false;
	transition_filter.timer.start();
	glitch_filter.timer.start()
	glitch_filter.stop = false
	await transition_filter.timer.timeout
	spawn_player()

func _ready() -> void:
	transition_filter.timer.start()
	load_map_data()
	load_level()
	spawn_player()
	
func _on_player_death() ->void:
	reload()

func _on_player_win() ->void:
	level += 1
	if level > max_level:
		level = 1
	load_map_data()
	reload()
