# scripts/weather_overlay.gd
# Dynamic full-screen 2D weather phenomenon overlay system with seamless
# tiling loops, smooth crossfading, lightning strikes, and puddle splashes.
# Restricts snow, rain, leaves, and fireflies strictly above ground level (y <= 312).
# Runs overlay frame animations at a smooth 60 FPS.
extends CanvasLayer

@onready var weather_rect: TextureRect = $WeatherRect
@onready var screen_flash: ColorRect = $ScreenFlash
@onready var lightning_bolt: AnimatedSprite2D = $LightningBolt
@onready var rain_splashes: CPUParticles2D = $RainSplashes

var background_stars_rect: TextureRect = null

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
var _ambient_sfx_timer: float = 15.0

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
	
	if get_parent() and get_parent().has_node("ParallaxBackground/Sky_Stars/StarsRect"):
		background_stars_rect = get_parent().get_node("ParallaxBackground/Sky_Stars/StarsRect")
		background_stars_rect.modulate.a = 0.0
	
	_load_all_presets()
	_setup_lightning_animation()
	
	# Connect to HabitManager signal
	HabitManager.weather_changed.connect(set_weather)
	
	# Initial weather from persistent state
	set_weather(HabitManager.selected_weather, false)
	_update_geometry()

func _load_all_presets() -> void:
	var clear_frames: Array[Texture2D] = []
	_presets["clear"] = {
		"frames": clear_frames,
		"frame_ms": 1000.0,
		"opacity": 0.0,
		"above_ground_only": false
	}
	_presets["rain"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/rain", "rain_light_128px_rain_", 16),
		"frame_ms": 50.0, # 20.0 FPS gentle steady rain (~0.8s cycle)
		"opacity": 0.85,
		"above_ground_only": true
	}
	_presets["snow"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/snow", "snow_medium_128px_snow_", 32),
		"frame_ms": 55.0, # ~18.2 FPS calm snowfall (~1.76s cycle, smooth without stutter)
		"opacity": 0.90,
		"above_ground_only": true
	}
	_presets["fog"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/fog", "fog_thin_128px_fog_", 32),
		"frame_ms": 70.0, # ~14.3 FPS slow rolling mist (~2.24s cycle, fluid drift)
		"opacity": 0.55,
		"above_ground_only": false
	}
	_presets["leaves"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/leaves", "leaves_autumn_128px_autumn_", 32),
		"frame_ms": 75.0, # ~13.3 FPS graceful tumbling leaves (~2.4s cycle)
		"opacity": 0.95,
		"above_ground_only": true
	}
	_presets["fireflies"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/fireflies", "fireflies_128px_firefly_", 32),
		"frame_ms": 85.0, # ~11.8 FPS tranquil hovering fireflies (~2.72s cycle)
		"opacity": 0.85,
		"above_ground_only": true
	}
	_presets["stars"] = {
		"frames": _load_frames_from_dir("res://assets/weather/overlays/stars", "stars_twinkle_128px_stars_", 32),
		"frame_ms": 100.0, # 10.0 FPS gentle celestial twinkle (~3.2s cycle)
		"opacity": 0.75,
		"above_ground_only": false
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
	frames_res.set_animation_speed("bolt", 24.0)
	
	for i in range(1, 8):
		var p: String = "res://assets/weather/overlays/lightning/lightning_bolt_a_bolt_%02d.png" % i
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			if tex:
				frames_res.add_frame("bolt", tex)
				
	lightning_bolt.sprite_frames = frames_res
	lightning_bolt.animation_finished.connect(func(): lightning_bolt.visible = false)

func _get_ground_screen_y() -> float:
	var default_ground_y: float = 312.0
	var vp: Viewport = get_viewport()
	if vp:
		var screen_ground: Vector2 = vp.get_canvas_transform() * Vector2(0.0, 312.0)
		var vp_h: float = vp.get_visible_rect().size.y
		if vp_h <= 0.0:
			vp_h = 360.0
		if screen_ground.y > 0.0:
			return clampf(screen_ground.y, 0.0, vp_h)
	return default_ground_y

func _update_geometry() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size if get_viewport() else Vector2(640.0, 360.0)
	var screen_w: float = vp_size.x if vp_size.x > 0.0 else 640.0
	var screen_h: float = vp_size.y if vp_size.y > 0.0 else 360.0
	
	var is_above_ground_only: bool = _presets.get(current_weather, {}).get("above_ground_only", false)
	
	if is_above_ground_only:
		var ground_screen_y: float = _get_ground_screen_y()
		weather_rect.position = Vector2(0.0, 0.0)
		weather_rect.size = Vector2(screen_w, ground_screen_y)
		
		# Rain splashes sit right on top of the ground line
		rain_splashes.position = Vector2(screen_w * 0.5, ground_screen_y)
		rain_splashes.emission_rect_extents = Vector2(screen_w * 0.5, 2.0)
		if ground_screen_y >= screen_h:
			rain_splashes.emitting = false
		elif current_weather == "rain":
			rain_splashes.emitting = true
	else:
		weather_rect.position = Vector2(0.0, 0.0)
		weather_rect.size = Vector2(screen_w, screen_h)
		if current_weather == "rain":
			rain_splashes.position = Vector2(screen_w * 0.5, 312.0)
			rain_splashes.emission_rect_extents = Vector2(screen_w * 0.5, 2.0)
			rain_splashes.emitting = true

func set_weather(weather_id: String, animate_transition: bool = true) -> void:
	if not _presets.has(weather_id):
		weather_id = "clear"
		
	current_weather = weather_id
	var preset: Dictionary = _presets[weather_id]
	_current_frame_ms = preset["frame_ms"]
	_target_opacity = preset["opacity"]
	
	_update_geometry()
	
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
			
		if current_weather == "stars":
			weather_rect.texture = null
			weather_rect.modulate.a = 0.0
			if background_stars_rect:
				background_stars_rect.visible = true
				background_stars_rect.modulate.a = _target_opacity
				if _current_frames.size() > 0:
					background_stars_rect.texture = _current_frames[0]
		else:
			if background_stars_rect:
				background_stars_rect.modulate.a = 0.0
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
		
	_current_frames.clear()
	for tex in preset["frames"]:
		_current_frames.append(tex)
		
	_crossfade_tween = create_tween()
	
	if current_weather == "stars":
		# Foreground weather clears immediately so stars never draw in front of trees
		weather_rect.texture = null
		_crossfade_tween.tween_property(weather_rect, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
		if background_stars_rect:
			background_stars_rect.visible = true
			if _current_frames.size() > 0:
				background_stars_rect.texture = _current_frames[0]
			_crossfade_tween.parallel().tween_property(background_stars_rect, "modulate:a", _target_opacity, 0.35).set_trans(Tween.TRANS_SINE)
	else:
		if background_stars_rect and background_stars_rect.modulate.a > 0.0:
			_crossfade_tween.parallel().tween_property(background_stars_rect, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
			
		_crossfade_tween.tween_property(weather_rect, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
		_crossfade_tween.tween_callback(func():
			if _current_frames.size() > 0:
				weather_rect.texture = _current_frames[0]
			else:
				weather_rect.texture = null
		)
		_crossfade_tween.tween_property(weather_rect, "modulate:a", _target_opacity, 0.22).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	_update_geometry()
	
	# Animate active overlay frames at 60 FPS
	if not _current_frames.is_empty():
		_anim_timer += delta * 1000.0
		var total_cycle_ms: float = _current_frame_ms * _current_frames.size()
		if total_cycle_ms > 0.0 and _anim_timer >= total_cycle_ms:
			_anim_timer = fmod(_anim_timer, total_cycle_ms)
			
		var frame_index: int = int(_anim_timer / _current_frame_ms) % _current_frames.size()
		if current_weather == "stars":
			weather_rect.texture = null
			if background_stars_rect and background_stars_rect.texture != _current_frames[frame_index]:
				background_stars_rect.texture = _current_frames[frame_index]
		else:
			if weather_rect.texture != _current_frames[frame_index]:
				weather_rect.texture = _current_frames[frame_index]
		
	# Lightning loop during rain
	if current_weather == "rain":
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_trigger_lightning()
			_lightning_timer = randf_range(8.0, 16.0)

	# Periodic atmospheric one-shots (wind gusts or droplets)
	_ambient_sfx_timer -= delta
	if _ambient_sfx_timer <= 0.0:
		if current_weather in ["snow", "leaves", "fog"]:
			if AudioManager:
				AudioManager.play_sfx("wind_gust", Vector2(0.9, 1.1), -5.0)
			_ambient_sfx_timer = randf_range(18.0, 32.0)
		elif current_weather == "rain":
			if AudioManager:
				var drop_sfx: String = "rain_splash" if randf() < 0.6 else "water_ripple"
				AudioManager.play_sfx(drop_sfx, Vector2(0.95, 1.05), -6.0)
			_ambient_sfx_timer = randf_range(6.0, 14.0)
		else:
			_ambient_sfx_timer = 20.0

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

	if AudioManager:
		AudioManager.play_sfx("thunder_close", Vector2(0.85, 1.1), 1.5)
