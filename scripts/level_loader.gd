extends Node2D

@export var level: int = 1
@export var max_level: int = 1
@export var atlas_width: int
@onready var player_spawn_timer: Timer = $PlayerSpawnDelay
@onready var transition_filter: CanvasLayer = $TransitionFilter
@onready var overlay: ColorRect = $BluePrintOverlay

var tileset: Resource = preload("res://assets/tileset/level.tres")

var ins_pressure_pad: Resource = preload("res://scenes/pressure_pad.tscn")
var ins_platform: Resource = preload("res://scenes/platform.tscn")
var ins_spike: Resource = preload("res://scenes/spike.tscn")
var ins_player: Resource = preload("res://scenes/player.tscn")
var ins_pipe: Resource = preload("res://scenes/pipe.tscn")
var ins_emitter: Resource = preload("res://scenes/ray_emitter.tscn")
var ins_box: Resource = preload("res://scenes/box.tscn")
var ins_instruction: Resource = preload("res://scenes/instruction.tscn")

var map_data: Dictionary
var map_width: int
var has_entrance: bool = false
var blueprint_enable: bool = false
var tilemap_layers: Dictionary
var pipes: Array[Node2D]
var spikes: Dictionary
var platforms: Dictionary
var emitters: Array[Node2D]
var pressure_pads: Array[Area2D]
var boxes: Array[CharacterBody2D]
var instructions: Array[Node2D]
var player: CharacterBody2D
var reloading: bool =  false

var player_spawn_point: Vector2

func convert_position(grid_position: int, width: int) -> Vector2:
	var x: int = grid_position % width
	var y: int = int(floor(float(grid_position) / float(width)))
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
			load_objects(layer, order)
	
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
	var layer_name = data["name"]
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
		if gid == 70:
			load_box(tile_position)
		elif gid == 48 or gid == 49 or gid == 50 or gid == 51:
			load_emitter(tile_position, gid)
			layer.set_cell(tile_position, 0, atlas_position)
		else:
			layer.set_cell(tile_position, 0, atlas_position)
	
	add_child(layer)
	tilemap_layers[layer_name] = layer
	
func load_pipe(data: Dictionary, order: int) -> void:
	var reversed = data["gid"] == 70
	var type: Dictionary = data["properties"][0]
	var pipe: Node2D = ins_pipe.instantiate()
	var pipe_position = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	match type["value"]:
		"entrance":
			if has_entrance:
				print("Cant have more than 1 entrance, skipping")
				return
			player_spawn_point = pipe_position
			player_spawn_point += Vector2(1.0, -5.0) if not reversed else Vector2(1.0, 5.0)
			has_entrance = true
			global.gravity_scale = 1 if not reversed else -1
			pipe.type = Pipe.Type.ENTRANCE
		"exit":
			pipe.type = Pipe.Type.EXIT
	pipe.reversed = reversed
	pipe.position = pipe_position
	add_child(pipe)
	pipe.sprite.z_index = order
	pipes.append(pipe)
	
func load_platform(data: Dictionary, order: int) -> void:
	var id: int = data["id"]
	var reversed: bool = data["properties"][0]["value"]
	var speed: float = data["properties"][1]["value"]
	var x1: int = data["properties"][2]["value"]
	var y1: int = data["properties"][3]["value"]
	var p0: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	var p1: Vector2 = p0 + Vector2(x1 * 16.0, y1 * 16.0)
	
	var platform: AnimatableBody2D = ins_platform.instantiate()
	platform.reversed = reversed
	platform.position = p0 if not reversed else p1
	platform.z_index = order
	platform.p0 = p0
	platform.p1 = p1
	platform.speed = speed
	match int(data["gid"]):
		42:
			platform.type = Platform.Type.HORIZONTAL
		56:
			platform.type = Platform.Type.VERTICAL
	add_child(platform)
	platforms[id] = platform
	
func load_spike(data: Dictionary, order: int) -> void:
	var id: int = data["id"]
	var reversed = data["gid"] == 60
	var activated: bool = bool(data["properties"][0]["value"])
	var p0: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	
	var spike: Node2D = ins_spike.instantiate()
	spike.reversed = reversed
	spike.activated = activated
	spike.position = p0
	spike.z_index = order
	add_child(spike)
	spikes[id] = spike
	
func load_pressure_pad(data: Dictionary, order: int) -> void:
	var reversed = data["gid"] == 66
	var pad_type: String = data["properties"][0]["value"]
	var pressure_pad: Area2D = ins_pressure_pad.instantiate()
	var pad_position: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	pressure_pad.reversed = reversed
	pressure_pad.position = pad_position
	pressure_pad.z_index = order
	
	match pad_type:
		"gravity pad":
			var gravity: int = data["properties"][1]["value"]
			pressure_pad.activation_functions.append(global.set_gravity_scale.bind(gravity))
		"platform pad":
			var platform_id: int = data["properties"][1]["value"]
			pressure_pad.activation_functions.append(platforms[platform_id].set_reverse.bind(true))
			pressure_pad.deactivation_functions.append(platforms[platform_id].set_reverse.bind(false))
		"spike pad":
			pass
			var count: int = data["properties"][1]["value"]
			for i: int in range(count):
				var spike_id: int = int(data["properties"][i + 2]["value"])
				pressure_pad.activation_functions.append(spikes[spike_id].deactivate)
				pressure_pad.deactivation_functions.append(spikes[spike_id].activate)
			
	add_child(pressure_pad)
	pressure_pads.append(pressure_pad)
	
func load_instruction(data: Dictionary) -> void:
	var gid: int = int(data["gid"]) - 1
	var radius: float = float(data["properties"][0]["value"])
	var x: int = int(data["properties"][1]["value"])
	var y: int = int(data["properties"][2]["value"])
	var instruction_position: Vector2 = Vector2(float(data["x"]), float(data["y"])) + Vector2(8.0, -8.0)
	var target: Vector2 = Vector2(x * 16.0, y * 16.0) + Vector2(8.0, 8.0)
	var atlas_position: Vector2i = Vector2i(gid % atlas_width, int(floor(float(gid) / float(atlas_width)))) * 16
	
	var instruction: Node2D = ins_instruction.instantiate()
	instruction.position = instruction_position
	instruction.target = target
	instruction.radius = radius
	add_child(instruction)
	instruction.sprite.self_modulate.a = 0.0
	instruction.sprite.region_enabled = true
	instruction.sprite.region_rect = Rect2i(atlas_position, Vector2i(16, 16))
	instruction.sprite.z_index = 10
	instructions.append(instruction)
	
func load_objects(data: Dictionary, order: int) -> void:
	var objects_data: Array = data["objects"]
	var pipes_data: Array[Dictionary]
	var platforms_data: Array[Dictionary]
	var spikes_data: Array[Dictionary]
	var pressure_pads_data: Array[Dictionary]
	for object: Dictionary in objects_data:
		match object["name"]:
			"pipe":
				pipes_data.append(object)
			"platform":
				platforms_data.append(object)
			"spike":
				spikes_data.append(object)
			"pressure pad":
				pressure_pads_data.append(object)
			"instruction":
				load_instruction(object)
				
	for object: Dictionary in pipes_data:
		load_pipe(object, order)
	for object: Dictionary in platforms_data:
		load_platform(object, order)
	for object: Dictionary in spikes_data:
		load_spike(object, order)
	for object: Dictionary in pressure_pads_data:
		load_pressure_pad(object, order)

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
	
	for instruction: Node2D in instructions:
		instruction.player = player

func clear_level() -> void:
	player.queue_free()
	for key: String in tilemap_layers:
		tilemap_layers[key].queue_free()
	tilemap_layers.clear()
	
	for pipe: Node2D in pipes:
		pipe.queue_free()
	pipes.clear()
	
	for key: int in spikes:
		spikes[key].queue_free()
	spikes.clear()
	
	for emitter: Node2D in emitters:
		emitter.queue_free()
	emitters.clear()
	
	for key: int in platforms:
		platforms[key].queue_free()
	platforms.clear()
	
	for pad: Area2D in pressure_pads:
		pad.queue_free()
	pressure_pads.clear()
	
	for box: CharacterBody2D in boxes:
		if not box == null:
			box.queue_free()
	boxes.clear()
	
	for instruction: Node2D in instructions:
		instruction.queue_free()
	instructions.clear()
	
	has_entrance = false
	
func reload(instant: bool = false) -> void:
	reloading = true
	if not instant:
		player_spawn_timer.start()
		await player_spawn_timer.timeout
	transition_filter.reverse = true;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	clear_level()
	load_level()
	transition_filter.reverse = false;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	spawn_player()
	reloading = false

func _ready() -> void:
	load_map_data()
	load_level()
	transition_filter.reverse = false;
	transition_filter.timer.start();
	await transition_filter.timer.timeout
	spawn_player()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload") and not reloading:
		reload(true)
	if Input.is_action_pressed("blueprint_enable"):
		overlay.color.a = min(0.5, overlay.color.a + delta)
	else:
		overlay.color.a = max(0.0, overlay.color.a - delta)
	if tilemap_layers.has("blueprint0"):
		tilemap_layers["blueprint0"].self_modulate.a = overlay.color.a / 0.5
	for box: CharacterBody2D in boxes:
		box.highlight.self_modulate.a = overlay.color.a / 0.5
	for pipe: Node2D in pipes:
		pipe.highlight.self_modulate.a = overlay.color.a / 0.5
		
	if Input.is_action_just_pressed("next"):
		level += 1
		if level > max_level:
			level = 1
		load_map_data()
		reload(true)
		
func _on_player_death() ->void:
	reload()

func _on_player_win() ->void:
	level += 1
	if level > max_level:
		level = 1
	load_map_data()
	reload()
