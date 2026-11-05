# scripts/brazier.gd
# Interactive normal-mapped light emitter with organic flame flicker.
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

@export var is_lit: bool = true
@export var base_energy: float = 1.2
@export var flicker_speed: float = 8.0

var _time_offset: float = 0.0

func _ready() -> void:
	_time_offset = randf() * 100.0
	_setup_canvas_texture()

func _setup_canvas_texture() -> void:
	# Load diffuse and normal map for 3D normal lighting
	var diffuse: Texture2D = load("res://assets/props/dungeon/brazier-orange_32px_scroller_outline_lit.png")
	var normal: Texture2D = load("res://assets/props/dungeon/brazier-orange_32px_scroller_normal.png")
	
	if diffuse and normal:
		var ct: CanvasTexture = CanvasTexture.new()
		ct.diffuse_texture = diffuse
		ct.normal_texture = normal
		sprite.texture = ct
		sprite.hframes = 6

func _process(delta: float) -> void:
	if not is_lit:
		light.energy = 0.0
		return
		
	# Cycle the 6-frame flame animation
	var frame_idx: int = int((Time.get_ticks_msec() / 110.0) + _time_offset) % 6
	sprite.frame = frame_idx
		
	var t: float = (Time.get_ticks_msec() / 1000.0) * flicker_speed + _time_offset
	# Multi-frequency noise-like flicker
	var flicker: float = sin(t) * 0.12 + sin(t * 2.3) * 0.08 + sin(t * 5.7) * 0.04
	light.energy = clampf(base_energy + flicker, 0.6, 1.8)
	light.position.y = -18.0 + (sin(t * 1.5) * 0.5)
