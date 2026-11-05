# scripts/weather_overlay.gd
# Dynamic full-screen 2D weather phenomenon overlay system with seamless
# tiling loops, smooth crossfading, lightning strikes, and puddle splashes.
extends CanvasLayer

@onready var weather_rect: TextureRect = $WeatherRect
@onready var screen_flash: ColorRect = $ScreenFlash
@onready var lightning_bolt: AnimatedSprite2D = $LightningBolt
@onready var rain_splashes: CPUParticles2D = $RainSplashes

var current_weather: String = "clear"

# Frame cache and metadata
var _presets: Dictionary = {}
var _current_frames: Array[Texture2D] = []
var _current_frame_ms: float = 60.0
var _target_opacity: float = 1.0
var _anim_timer: float = 0.0
var _crossfade_tween: Tween = null

# Lightning mechanics during rain
var _lightning_timer: float = 0.0

func _ready() -> void:
	layer = 2 # Render above world background/platforms, below UI HUD (layer 10)
	weather_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weather_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	weather_rect.stretch_mode = TextureRect.STRETCH_TILE
	weather_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning_bolt.visible = false
	rain_splashes.emitting = false
	
	_load_all_presets()
	_setup_lightning_animation()
	
	# Connect to HabitManager signal
	HabitManager.weather_changed.connect(set_weather)
	
	# Initial weather from persistent state
	set_weather(HabitManager.selected_weather, false)

func _load_all_presets() -> void:
	var clear_frames: Array[Texture2D] = []
	_presets["clear"] = {
		"frames": clear_frames,
		"frame_ms": 1000.0,
		"opacity": 0.0
	}
	_presets["rain"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/rain", "rain_light_128px_rain_", 16),
		"frame_ms": 50.0,
		"opacity": 0.85
	}
	_presets["snow"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/snow", "snow_medium_128px_snow_", 32),
		"frame_ms": 80.0,
		"opacity": 0.90
	}
	_presets["fog"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/fog", "fog_thin_128px_fog_", 32),
		"frame_ms": 120.0,
		"opacity": 0.55
	}
	_presets["leaves"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/leaves", "leaves_autumn_128px_autumn_", 32),
		"frame_ms": 80.0,
		"opacity": 0.95
	}
	_presets["fireflies"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/fireflies", "fireflies_128px_firefly_", 32),
		"frame_ms": 90.0,
		"opacity": 0.85
	}
	_presets["stars"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/stars", "stars_twinkle_128px_stars_", 32),
		"frame_ms": 120.0,
		"opacity": 0.75
	}

func _load_frames_from_dir(dir_path: String, prefix: String, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(1, count + 1):
		var file_name: String = "%s%02d.png" % [prefix, i]
		var full_path: String = "%s/%s" % [dir_path, file_name]
		if ResourceLoader.exists(full_path):
			var tex: Texture2D = load(full_path) as Texture2D
			if tex:
				frames.append(tex)
	return frames

func _setup_lightning_animation() -> void:
	var frames_res: SpriteFrames = SpriteFrames.new()
	frames_res.add_animation("bolt")
	frames_res.set_animation_loop("bolt", false)
	frames_res.set_animation_speed("bolt", 16.0) # ~60ms per frame
	
	for i in range(1, 8):
		var p: String = "res://assets/weather/overlays/lightning/lightning_bolt_a_bolt_%02d.png" % i
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			if tex:
				frames_res.add_frame("bolt", tex)
				
	lightning_bolt.sprite_frames = frames_res
	lightning_bolt.animation_finished.connect(func(): lightning_bolt.visible = false)

func set_weather(weather_id: String, animate_transition: bool = true) -> void:
	if not _presets.has(weather_id):
		weather_id = "clear"
		
	current_weather = weather_id
	var preset: Dictionary = _presets[weather_id]
	_current_frame_ms = preset["frame_ms"]
	_target_opacity = preset["opacity"]
	
	# Rain specific features
	if current_weather == "rain":
		_lightning_timer = randf_range(6.0, 12.0)
		rain_splashes.emitting = true
	else:
		rain_splashes.emitting = false
		lightning_bolt.visible = false
		screen_flash.color.a = 0.0

	if not animate_transition:
		_current_frames.clear()
		for tex in preset["frames"]:
			_current_frames.append(tex)
		if _current_frames.size() > 0:
			weather_rect.texture = _current_frames[0]
			weather_rect.modulate.a = _target_opacity
		else:
			weather_rect.texture = null
			weather_rect.modulate.a = 0.0
		return

	# Smooth crossfade
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(weather_rect, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	_crossfade_tween.tween_callback(func():
		_current_frames.clear()
		for tex in preset["frames"]:
			_current_frames.append(tex)
		if _current_frames.size() > 0:
			weather_rect.texture = _current_frames[0]
		else:
			weather_rect.texture = null
	)
	_crossfade_tween.tween_property(weather_rect, "modulate:a", _target_opacity, 0.2).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	# Animate active overlay frames
	if not _current_frames.is_empty():
		_anim_timer += delta * 1000.0
		var frame_index: int = int(_anim_timer / _current_frame_ms) % _current_frames.size()
		weather_rect.texture = _current_frames[frame_index]
		
	# Lightning loop during rain
	if current_weather == "rain":
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_trigger_lightning()
			_lightning_timer = randf_range(8.0, 16.0)

func _trigger_lightning() -> void:
	# Screen flash
	screen_flash.color = Color(1.0, 1.0, 1.0, 0.4)
	var flash_tw: Tween = create_tween()
	flash_tw.tween_property(screen_flash, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Lightning bolt strike
	var strike_x: float = randf_range(80.0, 560.0)
	lightning_bolt.position = Vector2(strike_x, 110.0)
	lightning_bolt.scale = Vector2(2.0, 2.0)
	lightning_bolt.visible = true
	lightning_bolt.frame = 0
	lightning_bolt.play("bolt")
