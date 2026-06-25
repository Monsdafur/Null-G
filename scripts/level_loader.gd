extends Node2D

@export var level: int = 1
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

var map_width: int
var tilemap_layers: Array[TileMapLayer]

func convert_position(grid_position: int, map_width: int) -> Vector2:
	var x: int = grid_position % map_width
	var y: int = grid_position / map_width
	return Vector2i(x, y)
	
func load_json() -> Dictionary:
	var path: String = String("res://data/levels/level%d.tmj" % level)
	if not FileAccess.file_exists(path):
		print("File do not exist")
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var string_data = file.get_as_text()
	file.close()
	
	return JSON.parse_string(string_data)
	
func load_level(data: Dictionary) -> void:
	map_width = data["width"]
	var layers: Array = data["layers"]
	
	for layer: Dictionary in layers:
		if layer["type"] == "tilelayer":
			load_tilemap_layer(layer)
	
func load_tilemap_layer(data: Dictionary) -> void:
	var tilemap_data = data["data"]
	var layer: TileMapLayer = TileMapLayer.new()
	layer.tile_set = tileset
	
	print(data["name"])
	var p: int = -1
	for gid: int in tilemap_data:
		p += 1
		if gid == 0:
			continue
		gid -= 1
		var atlas_position: Vector2i = convert_position(gid, atlas_width)
		var tile_position: Vector2i = convert_position(p, map_width)
		layer.set_cell(tile_position, 0, atlas_position)
	
	add_child(layer)
	tilemap_layers.append(layer)
	
func load_objects() -> void:
	pass
	
func _ready() -> void:
	var json_data: Dictionary = load_json()
	assert(not json_data.is_empty())
	load_level(json_data)
	
