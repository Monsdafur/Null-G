extends Node2D

@export var max_level: int = 1

@onready var player_spawn_timer: Timer = $PlayerSpawnDelay
@onready var fade_effect: AnimationPlayer = $"../../FadeScreen/AnimationPlayer"
@onready var overlay: ColorRect = $BlueprintOverlay
@onready var audio_stream_manager: Node2D = $AudioStreamManager

var tileset: Resource = preload("res://assets/tileset/tileset.tres")
var water_tileset: Resource = preload("res://assets/tileset/water.tres")
var glass_tileset: Resource = preload("res://assets/tileset/glass.tres")
var water_shader: Resource = preload("res://assets/shaders/water.gdshader")
var noise_texture: Resource = preload("res://assets/textures/noise.tres")

var ins_pressure_pad: Resource = preload("res://scenes/pressure_pad.tscn")
var ins_platform: Resource = preload("res://scenes/platform.tscn")
var ins_spike: Resource = preload("res://scenes/spike.tscn")
var ins_player: Resource = preload("res://scenes/player.tscn")
var ins_pipe: Resource = preload("res://scenes/pipe.tscn")
var ins_emitter: Resource = preload("res://scenes/ray_emitter.tscn")
var ins_box: Resource = preload("res://scenes/box.tscn")
var ins_instruction: Resource = preload("res://scenes/instruction.tscn")

var levels: Dictionary
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
	var path: String = String("res://data/levels/Null.ldtk")
	if not FileAccess.file_exists(path):
		print("File do not exist")
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var string_data = file.get_as_text()
	file.close()
	
	var map_data: Dictionary = JSON.parse_string(string_data)
	for i in range(map_data["levels"].size()):
		var level: Dictionary = map_data["levels"][i]
		levels[level["identifier"]] = level

func load_pipe(entity_position: Vector2, entity: Dictionary, order: int, inverted: bool) -> void:
	var properties: Array = entity["fieldInstances"]
	var type: String = String(properties[0]["__value"])
	var pipe: Node2D = ins_pipe.instantiate()
	match type:
		"Entrance":
			if has_entrance:
				print("Cant have more than 1 entrance, skipping")
				return
			player_spawn_point = entity_position
			player_spawn_point += Vector2(1.0, -5.0) if not inverted else Vector2(1.0, 5.0)
			has_entrance = true
			global.set_gravity_scale(1 if not inverted else -1)
			pipe.type = Pipe.Type.ENTRANCE
		"Exit":
			pipe.type = Pipe.Type.EXIT
	pipe.reversed = inverted
	pipe.position = entity_position
	add_child(pipe)
	pipe.sprite.z_index = order
	pipes.append(pipe)
	
func load_box(entity_position: Vector2, order: int) -> void:
	var box: Node2D = ins_box.instantiate()
	add_child(box)
	box.position = entity_position
	box.sprite.z_index = order
	boxes.append(box)
	
func load_platform(entity_position: Vector2, entity: Dictionary, order: int) -> void:
	var properties: Array = entity["fieldInstances"]
	var id: String = String(entity["iid"])
	var type: String = String(properties[0]["__value"])
	var speed: float = float(properties[1]["__value"])
	var x1: float = float(properties[2]["__value"]["cx"])
	var y1: float = float(properties[2]["__value"]["cy"])
	var reversed: bool = bool(properties[3]["__value"])
	
	var p0: Vector2 = entity_position
	var p1: Vector2 = Vector2(x1, y1) * 16.0 + Vector2(8.0, 8.0)
	
	var platform: AnimatableBody2D = ins_platform.instantiate()
	platform.reversed = reversed
	platform.position = p0 if not reversed else p1
	platform.z_index = order
	platform.p0 = p0
	platform.p1 = p1
	platform.speed = speed
	match type:
		"Horizontal":
			platform.type = Platform.Type.HORIZONTAL
		"Vertical":
			platform.type = Platform.Type.VERTICAL
	add_child(platform)
	platforms[id] = platform
	
func load_spike(entity_position: Vector2, entity: Dictionary, order: int, inverted: bool) -> void:
	var properties: Array = entity["fieldInstances"]
	var id: String = String(entity["iid"])
	var activated: bool = bool(properties[0]["__value"])
	
	var spike: Node2D = ins_spike.instantiate()
	spike.reversed = inverted
	spike.activated = activated
	spike.position = entity_position
	spike.z_index = order
	add_child(spike)
	spikes[id] = spike

func load_pressure_pad(entity_position: Vector2, entity: Dictionary, order: int, inverted: bool) -> void:
	var properties: Array = entity["fieldInstances"]
	var pad_type: String = properties[0]["__value"]
	var pressure_pad: Area2D = ins_pressure_pad.instantiate()
	pressure_pad.reversed = inverted
	pressure_pad.position = entity_position
	pressure_pad.z_index = order
	
	match pad_type:
		"Gravity":
			var gravity: int = 1 if inverted else -1
			pressure_pad.activation_functions.append(global.set_gravity_scale.bind(gravity))
		"Platform":
			var count: int = properties[1]["__value"].size()
			for i: int in range(count):
				var platform_id: String = properties[1]["__value"][i]["entityIid"]
				pressure_pad.activation_functions.append(platforms[platform_id].set_reverse.bind(true))
				pressure_pad.deactivation_functions.append(platforms[platform_id].set_reverse.bind(false))
		"Spike":
			var count: int = properties[1]["__value"].size()
			for i: int in range(count):
				var spike_id: String = properties[1]["__value"][i]["entityIid"]
				pressure_pad.activation_functions.append(spikes[spike_id].deactivate)
				pressure_pad.deactivation_functions.append(spikes[spike_id].activate)
			
	add_child(pressure_pad)
	pressure_pads.append(pressure_pad)
	
func load_instruction(entity_position: Vector2, entity: Dictionary) -> void:
	var properties: Array = entity["fieldInstances"]
	var px: float = float(properties[0]["__value"]["cx"])
	var py: float = float(properties[0]["__value"]["cy"])
	var ax: int = int(properties[1]["__value"][0])
	var ay: int = int(properties[1]["__value"][1])
	var radius: float = float(properties[2]["__value"])
	
	var instruction: Node2D = ins_instruction.instantiate()
	add_child(instruction)
	instruction.position = entity_position
	instruction.target = Vector2(px, py) * 16.0 + Vector2(8.0, 8.0)
	instruction.radius = radius
	instruction.z_index = 10
	instruction.sprite.region_rect = Rect2i(ax, ay, 16, 16)
	instruction.sprite.visible = false
	instructions.append(instruction)
	

func load_entities(entity_layer: Dictionary, order: int) -> void:
	var platform_data: Dictionary
	var pad_data: Dictionary
	var pad_inv_data: Dictionary
	var spike_data: Dictionary
	var spike_inv_data: Dictionary
	for entity: Dictionary in entity_layer["entityInstances"]:
		var identifier: String = entity["__identifier"]
		var entity_position: Vector2 = Vector2(float(entity["__grid"][0]), float(entity["__grid"][1])) * 16.0
		entity_position += Vector2(8.0, 8.0)
		
		match identifier:
			"Box":
				load_box(entity_position, order)
			"Pipe":
				load_pipe(entity_position, entity, order, false)
			"PipeInv":
				load_pipe(entity_position, entity, order, true)
			"Platform":
				platform_data[entity_position] = entity
			"Spike":
				spike_data[entity_position] = entity
			"SpikeInv":
				spike_inv_data[entity_position] = entity
			"PressurePad":
				pad_data[entity_position] = entity
			"PressurePadInv":
				pad_inv_data[entity_position] = entity
			"Instruction":
				load_instruction(entity_position, entity)
				
	for entity_position: Vector2 in platform_data:
		load_platform(entity_position, platform_data[entity_position], order)
		
	for entity_position: Vector2 in spike_data:
		load_spike(entity_position, spike_data[entity_position], order, false)
		
	for entity_position: Vector2 in spike_inv_data:
		load_spike(entity_position, spike_inv_data[entity_position], order, true)
	
	# must be loaded last
	for entity_position: Vector2 in pad_data:
		load_pressure_pad(entity_position, pad_data[entity_position], order, false)
		
	for entity_position: Vector2 in pad_inv_data:
		load_pressure_pad(entity_position, pad_inv_data[entity_position], order, true)

func load_emitter(cell_position: Vector2i, direction: RayEmitter.Direction, order: int) -> void:
	var emitter_position: Vector2 = Vector2(cell_position) * 16.0 + Vector2(8.0, 8.0)
	var emitter: Node2D = ins_emitter.instantiate()
	emitter.direction = direction
	add_child(emitter)
	emitter.position = emitter_position
	emitter.z_index = order
	emitters.append(emitter)
	
func load_layer(layer: Dictionary, order: int) -> void:
	if layer["__identifier"] == "Blueprint":
		overlay.z_index = order
	var tilemap_layer: TileMapLayer = TileMapLayer.new()
	for cell: Dictionary in layer["autoLayerTiles"]:
		var cell_position: Vector2i = Vector2i(int(cell["px"][0]), int(cell["px"][1]))
		cell_position /= 16
		var atlas_coord: Vector2i = Vector2i(int(cell["src"][0]), int(cell["src"][1]))
		atlas_coord /= 16
		if layer["__identifier"] == "Water" or layer["__identifier"] == "DangerousWater":
			tilemap_layer.tile_set = water_tileset
			tilemap_layer.add_to_group("water")
		elif layer["__identifier"] == "Glass":
			tilemap_layer.tile_set = glass_tileset
		else:
			tilemap_layer.tile_set = tileset
		tilemap_layer.set_cell(cell_position, 0, atlas_coord)
		
		if atlas_coord.y == 6:
			if atlas_coord.x == 0:
				load_emitter(cell_position, RayEmitter.Direction.RIGHT, order - 3)
			elif atlas_coord.x == 1:
				load_emitter(cell_position, RayEmitter.Direction.DOWN, order - 3)
			elif atlas_coord.x == 2:
				load_emitter(cell_position, RayEmitter.Direction.UP, order - 3)
			elif atlas_coord.x == 3:
				load_emitter(cell_position, RayEmitter.Direction.LEFT, order - 3)
				
	add_child(tilemap_layer)
	tilemap_layers[layer["__identifier"]] = tilemap_layer
	tilemap_layer.z_index = order
	tilemap_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if (layer["__identifier"] == "DangerousWater") and global.effect_on:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = water_shader
		tilemap_layer.material = shader_material
		tilemap_layer.material.set_shader_parameter("enabled", true)
		tilemap_layer.material.set_shader_parameter("noise", noise_texture)
		tilemap_layer.material.set_shader_parameter("direction", Vector2(1.0, 1.0).normalized());
		tilemap_layer.material.set_shader_parameter("distortion_scale", Vector2(0.5, 4.0));
		tilemap_layer.material.set_shader_parameter("speed", 0.02);

func load_level() -> void:
	audio_stream_manager.stop_all()
	var level: Dictionary = levels["Level_%d" % global.current_level]
	var order: int = level["layerInstances"].size()
	
	for layer: Dictionary in level["layerInstances"]:
		if layer["__type"] == "Entities":
			load_entities(layer, order)
		else:
			load_layer(layer, order)
		order -= 1

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
		instruction.sprite.visible = true

func clear_level() -> void:
	player.queue_free()
	for key: String in tilemap_layers:
		tilemap_layers[key].queue_free()
	tilemap_layers.clear()

	for pipe: Node2D in pipes:
		pipe.queue_free()
	pipes.clear()

	for key: String in spikes:
		spikes[key].queue_free()
	spikes.clear()

	for emitter: Node2D in emitters:
		emitter.queue_free()
	emitters.clear()

	for key: String in platforms:
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
	if reloading:
		return
	reloading = true
	global.in_game = false
	if not instant:
		player_spawn_timer.start()
		await player_spawn_timer.timeout
	fade_effect.play("fade in")
	await fade_effect.animation_finished
	clear_level()
	load_level()
	fade_effect.play("fade out")
	await fade_effect.animation_finished
	spawn_player()
	reloading = false
	global.in_game = true

func _ready() -> void:
	load_map_data()
	load_level()
	fade_effect.play("fade out")
	await fade_effect.animation_finished
	spawn_player()
	global.in_game = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload"):
		reload(true)
	if Input.is_action_pressed("blueprint_enable"):
		overlay.color.a = min(0.5, overlay.color.a + delta)
	else:
		overlay.color.a = max(0.0, overlay.color.a - delta)
	if tilemap_layers.has("Blueprint"):
		tilemap_layers["Blueprint"].self_modulate.a = overlay.color.a / 0.5
	for box: CharacterBody2D in boxes:
		if not box == null:
			box.highlight.self_modulate.a = overlay.color.a / 0.5
	for pipe: Node2D in pipes:
		pipe.highlight.self_modulate.a = overlay.color.a / 0.5

	if Input.is_action_just_pressed("next") and not reloading:
		global.current_level += 1
		if global.current_level > max_level:
			global.current_level = 0
		reload(true)
		
func _on_player_death() ->void:
	reload()

func _on_player_win() ->void:
	global.current_level += 1
	if global.current_level > max_level:
		global.current_level = 0
	global.save_progress()
	reload()
