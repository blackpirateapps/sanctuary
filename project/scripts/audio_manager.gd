# scripts/audio_manager.gd
# Central audio controller for Sanctuary of the Wilds.
# Manages dual-player ambient weather crossfading, polyphonic SFX pooling,
# dynamic footstep sound synthesis, and persistent bus volume levels.
extends Node

# Signal emitted when audio configuration is modified
signal audio_settings_changed(muted: bool, master_step: int, ambience_step: int, sfx_step: int)

# Audio streams dictionary
var _streams: Dictionary = {}

# Dual-player ambience crossfader
var _ambience_player_a: AudioStreamPlayer
var _ambience_player_b: AudioStreamPlayer
var _active_ambience_player: AudioStreamPlayer = null
var _current_weather_track: String = ""
var _crossfade_tween: Tween = null

# Polyphonic SFX player pool
const SFX_POOL_SIZE: int = 6
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

# Dedicated footsteps player
var _footstep_player: AudioStreamPlayer

# Step volumes: 0 = 0% (off), 1 = 25%, 2 = 50%, 3 = 75%, 4 = 100%
const VOLUME_PERCENTAGES: Array[int] = [0, 25, 50, 75, 100]

var is_muted: bool = false
var master_step: int = 4
var ambience_step: int = 3
var sfx_step: int = 4

# Weather-to-loop mapping and base decibel balancing
const WEATHER_AUDIO_CONFIG: Dictionary = {
	"rain": {
		"stream_key": "rain_light",
		"base_db": 0.0,
		"silent": false
	},
	"snow": {
		"stream_key": "wind_light",
		"base_db": -2.0,
		"silent": false
	},
	"leaves": {
		"stream_key": "wind_light",
		"base_db": -2.0,
		"silent": false
	},
	"fog": {
		"stream_key": "wind_light",
		"base_db": -8.0,
		"silent": false
	},
	"fireflies": {
		"stream_key": "fireflies",
		"base_db": -1.0,
		"silent": false
	},
	"stars": {
		"stream_key": "fireflies",
		"base_db": -6.0,
		"silent": false
	},
	"clear": {
		"stream_key": "wind_light",
		"base_db": -22.0,
		"silent": false
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_audio_streams()
	_setup_audio_players()
	
	# Connect to HabitManager for weather changes and settings sync
	if HabitManager:
		HabitManager.weather_changed.connect(set_weather_ambience)
		is_muted = HabitManager.audio_muted
		master_step = HabitManager.master_volume_step
		ambience_step = HabitManager.ambience_volume_step
		sfx_step = HabitManager.sfx_volume_step
		
	_apply_bus_volumes()
	
	# Start ambient track according to current selected weather
	if HabitManager:
		set_weather_ambience(HabitManager.selected_weather, false)

func _load_audio_streams() -> void:
	var files: Dictionary = {
		# Loops
		"rain_light": "res://assets/audio/loops/rain_light_loop_01.ogg",
		"wind_light": "res://assets/audio/loops/wind_light_loop_01.ogg",
		"fireflies": "res://assets/audio/loops/fireflies_loop_01.ogg",
		"embers": "res://assets/audio/loops/embers_loop_01.ogg",
		# One-shots
		"thunder_close": "res://assets/audio/oneshots/thunder_close_01.ogg",
		"wind_gust": "res://assets/audio/oneshots/wind_gust_01.ogg",
		"rain_splash": "res://assets/audio/oneshots/rain_splash_01.ogg",
		"water_ripple": "res://assets/audio/oneshots/water_ripple_01.ogg",
		"footsteps_grass": "res://assets/audio/oneshots/footsteps_grass_01.ogg",
		"footsteps_leaves": "res://assets/audio/oneshots/footsteps_leaves_01.ogg",
		"footsteps_snow": "res://assets/audio/oneshots/footsteps_snow_01.ogg",
		"footsteps_puddle": "res://assets/audio/oneshots/footsteps_puddle_01.ogg"
	}
	
	for key in files:
		var path: String = files[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				if stream is AudioStreamOggVorbis and key.ends_with("_loop_01") or key in ["rain_light", "wind_light", "fireflies", "embers"]:
					(stream as AudioStreamOggVorbis).loop = true
				_streams[key] = stream

func _setup_audio_players() -> void:
	# Ambience Dual Players
	_ambience_player_a = AudioStreamPlayer.new()
	_ambience_player_a.name = "AmbiencePlayerA"
	_ambience_player_a.bus = "Ambience"
	add_child(_ambience_player_a)
	
	_ambience_player_b = AudioStreamPlayer.new()
	_ambience_player_b.name = "AmbiencePlayerB"
	_ambience_player_b.bus = "Ambience"
	add_child(_ambience_player_b)
	
	_active_ambience_player = _ambience_player_a
	
	# SFX Pool
	for i in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
		
	# Footsteps Player
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.name = "FootstepPlayer"
	_footstep_player.bus = "Footsteps"
	add_child(_footstep_player)

# ----------------------------------------------------
# Ambience Weather Playback with Seamless Crossfading
# ----------------------------------------------------

func set_weather_ambience(weather_id: String, animate: bool = true) -> void:
	if not WEATHER_AUDIO_CONFIG.has(weather_id):
		weather_id = "clear"
		
	var config: Dictionary = WEATHER_AUDIO_CONFIG[weather_id]
	var stream_key: String = config["stream_key"]
	var target_db: float = config["base_db"]
	
	if not _streams.has(stream_key):
		return
		
	var stream: AudioStream = _streams[stream_key]
	
	if _current_weather_track == stream_key and _active_ambience_player.playing:
		# Just smoothly adjust volume if same loop track (e.g. between leaves and fog)
		if animate:
			var tw: Tween = create_tween()
			tw.tween_property(_active_ambience_player, "volume_db", target_db, 1.2).set_trans(Tween.TRANS_SINE)
		else:
			_active_ambience_player.volume_db = target_db
		return
		
	_current_weather_track = stream_key
	
	var outgoing_player: AudioStreamPlayer = _active_ambience_player
	var incoming_player: AudioStreamPlayer = _ambience_player_b if outgoing_player == _ambience_player_a else _ambience_player_a
	_active_ambience_player = incoming_player
	
	incoming_player.stream = stream
	
	if not animate:
		if _crossfade_tween and _crossfade_tween.is_valid():
			_crossfade_tween.kill()
		outgoing_player.stop()
		outgoing_player.volume_db = -80.0
		incoming_player.volume_db = target_db
		incoming_player.play()
		return
		
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween().set_parallel(true)
	
	# Fade out current active player
	if outgoing_player.playing:
		_crossfade_tween.tween_property(outgoing_player, "volume_db", -80.0, 1.2).set_trans(Tween.TRANS_SINE)
		_crossfade_tween.chain().tween_callback(outgoing_player.stop)
		
	# Fade in incoming player
	incoming_player.volume_db = -80.0
	incoming_player.play()
	_crossfade_tween.tween_property(incoming_player, "volume_db", target_db, 1.2).set_trans(Tween.TRANS_SINE)

# ----------------------------------------------------
# One-Shot SFX Polyphonic Playback
# ----------------------------------------------------

func play_sfx(key: String, pitch_range: Vector2 = Vector2(0.96, 1.04), volume_offset_db: float = 0.0) -> void:
	if not _streams.has(key):
		return
		
	# Grab next available or round-robin player from pool
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_pool[_sfx_pool_index]
		_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
		
	player.stream = _streams[key]
	player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	player.volume_db = volume_offset_db
	player.play()

# ----------------------------------------------------
# Dynamic Footstep Synthesis
# ----------------------------------------------------

func play_footstep(surface: String) -> void:
	var stream_key: String = "footsteps_" + surface
	if not _streams.has(stream_key):
		stream_key = "footsteps_grass"
		
	if not _streams.has(stream_key):
		return
		
	_footstep_player.stream = _streams[stream_key]
	_footstep_player.pitch_scale = randf_range(0.93, 1.07)
	_footstep_player.volume_db = randf_range(-3.0, 0.0)
	_footstep_player.play()

# ----------------------------------------------------
# Audio Settings & Bus Volume Control
# ----------------------------------------------------

func set_muted(muted: bool) -> void:
	is_muted = muted
	_apply_bus_volumes()
	_notify_settings_changed()

func toggle_mute() -> void:
	set_muted(not is_muted)

func set_master_step(step: int) -> void:
	master_step = clampi(step, 0, 4)
	_apply_bus_volumes()
	_notify_settings_changed()

func cycle_master_step() -> void:
	var next_step: int = (master_step - 1)
	if next_step < 0:
		next_step = 4
	set_master_step(next_step)

func set_ambience_step(step: int) -> void:
	ambience_step = clampi(step, 0, 4)
	_apply_bus_volumes()
	_notify_settings_changed()

func cycle_ambience_step() -> void:
	var next_step: int = (ambience_step - 1)
	if next_step < 0:
		next_step = 4
	set_ambience_step(next_step)

func set_sfx_step(step: int) -> void:
	sfx_step = clampi(step, 0, 4)
	_apply_bus_volumes()
	_notify_settings_changed()

func cycle_sfx_step() -> void:
	var next_step: int = (sfx_step - 1)
	if next_step < 0:
		next_step = 4
	set_sfx_step(next_step)

func _step_to_db(step: int) -> float:
	match step:
		4: return 0.0       # 100%
		3: return -2.5      # 75%
		2: return -6.0      # 50%
		1: return -12.0     # 25%
		_: return -80.0     # 0% (Silent)

func _apply_bus_volumes() -> void:
	if AudioServer.get_bus_count() == 0:
		return
		
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, is_muted or master_step == 0)
		AudioServer.set_bus_volume_db(master_idx, _step_to_db(master_step))
		
	var amb_idx: int = AudioServer.get_bus_index("Ambience")
	if amb_idx != -1:
		AudioServer.set_bus_mute(amb_idx, ambience_step == 0)
		AudioServer.set_bus_volume_db(amb_idx, _step_to_db(ambience_step))
		
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, sfx_step == 0)
		AudioServer.set_bus_volume_db(sfx_idx, _step_to_db(sfx_step))
		
	var foot_idx: int = AudioServer.get_bus_index("Footsteps")
	if foot_idx != -1:
		AudioServer.set_bus_mute(foot_idx, sfx_step == 0)
		AudioServer.set_bus_volume_db(foot_idx, _step_to_db(sfx_step))

func _notify_settings_changed() -> void:
	if HabitManager:
		HabitManager.audio_muted = is_muted
		HabitManager.master_volume_step = master_step
		HabitManager.ambience_volume_step = ambience_step
		HabitManager.sfx_volume_step = sfx_step
		HabitManager.save_data()
	audio_settings_changed.emit(is_muted, master_step, ambience_step, sfx_step)
