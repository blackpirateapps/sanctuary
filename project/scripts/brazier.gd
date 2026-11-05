# scripts/brazier.gd
# Interactive normal-mapped light emitter with organic flame flicker.
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

@export var is_lit: bool = true
@export var base_energy: float = 1.2
@export var flicker_speed: float = 8.0
@export var flame_color: Color = Color(1.0, 0.658824, 0.294118, 1.0)

var ember_audio: AudioStreamPlayer2D = null
var _time_offset: float = 0.0

func _ready() -> void:
	_time_offset = randf() * 100.0
	_setup_canvas_texture()
	_setup_audio()
	if light:
		light.color = flame_color
		if flame_color != Color(1.0, 0.658824, 0.294118, 1.0):
			sprite.modulate = flame_color.lerp(Color.WHITE, 0.3)

func _setup_audio() -> void:
	ember_audio = AudioStreamPlayer2D.new()
	ember_audio.name = "EmberAudio"
	ember_audio.bus = "SFX"
	ember_audio.max_distance = 260.0
	ember_audio.attenuation = 1.8
	ember_audio.volume_db = -5.0
	add_child(ember_audio)
	
	var path: String = "res://assets/audio/loops/embers_loop_01.ogg"
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		if stream:
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			ember_audio.stream = stream
			if is_lit:
				ember_audio.play(randf() * 20.0) # Random offset avoids phasing

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
		if ember_audio and ember_audio.playing:
			ember_audio.stop()
		return
		
	if ember_audio and not ember_audio.playing and ember_audio.stream:
		ember_audio.play()
		
	# Cycle the 6-frame flame animation
	var frame_idx: int = int((Time.get_ticks_msec() / 110.0) + _time_offset) % 6
	sprite.frame = frame_idx
		
	var t: float = (Time.get_ticks_msec() / 1000.0) * flicker_speed + _time_offset
	# Multi-frequency noise-like flicker
	var flicker: float = sin(t) * 0.12 + sin(t * 2.3) * 0.08 + sin(t * 5.7) * 0.04
	light.energy = clampf(base_energy + flicker, 0.6, 1.8)
	light.position.y = -20.0 + (sin(t * 1.5) * 0.5)
