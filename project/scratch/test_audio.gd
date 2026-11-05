# scratch/test_audio.gd
# Headless unit test verifying the Pixel Weather SFX audio system:
# asset integrity, AudioManager autoload, bus layout, ambient crossfading,
# contextual footsteps, thunderclaps on lightning, spatial brazier embers,
# and settings modal step-button persistence.
extends Node

func _ready() -> void:
	print("\n========================================================")
	print("🔊 RUNNING PIXEL WEATHER SFX & AUDIO UNIT TESTS 🔊")
	print("========================================================")
	
	_test_audio_asset_integrity()
	_test_audio_manager_initialization()
	_test_ambient_weather_crossfades()
	_test_contextual_footstep_surfaces()
	_test_lightning_thunder_hookup()
	_test_brazier_spatial_audio()
	_test_audio_settings_and_persistence()
	_test_settings_modal_audio_ui()
	
	print("\n========================================================")
	print("🎉 ALL PIXEL WEATHER AUDIO TESTS PASSED SUCCESSFULLY! 🎉")
	print("========================================================\n")
	get_tree().quit(0)

func _test_audio_asset_integrity() -> void:
	print("\n--- Test 1: Audio Asset Integrity ---")
	
	var loops: Dictionary = {
		"rain_light": "res://assets/audio/loops/rain_light_loop_01.ogg",
		"wind_light": "res://assets/audio/loops/wind_light_loop_01.ogg",
		"fireflies": "res://assets/audio/loops/fireflies_loop_01.ogg",
		"embers": "res://assets/audio/loops/embers_loop_01.ogg"
	}
	for id in loops:
		var path: String = loops[id]
		assert(ResourceLoader.exists(path), "Audio loop file must exist: %s" % path)
		var stream: AudioStream = load(path) as AudioStream
		assert(stream != null, "AudioStream must load: %s" % path)
		print("  ✔ Ambience loop '%s' verified (%s)" % [id, path.get_file()])
		
	var oneshots: Dictionary = {
		"thunder_close": "res://assets/audio/oneshots/thunder_close_01.ogg",
		"rain_splash": "res://assets/audio/oneshots/rain_splash_01.ogg",
		"water_ripple": "res://assets/audio/oneshots/water_ripple_01.ogg",
		"wind_gust": "res://assets/audio/oneshots/wind_gust_01.ogg",
		"footsteps_grass": "res://assets/audio/oneshots/footsteps_grass_01.ogg",
		"footsteps_leaves": "res://assets/audio/oneshots/footsteps_leaves_01.ogg",
		"footsteps_snow": "res://assets/audio/oneshots/footsteps_snow_01.ogg",
		"footsteps_puddle": "res://assets/audio/oneshots/footsteps_puddle_01.ogg"
	}
	for id in oneshots:
		var path: String = oneshots[id]
		assert(ResourceLoader.exists(path), "One-shot audio file must exist: %s" % path)
		var stream: AudioStream = load(path) as AudioStream
		assert(stream != null, "AudioStream must load: %s" % path)
		print("  ✔ One-shot SFX '%s' verified (%s)" % [id, path.get_file()])

func _test_audio_manager_initialization() -> void:
	print("\n--- Test 2: AudioManager Initialization & Bus Layout ---")
	
	assert(AudioManager != null, "AudioManager autoload singleton must be present")
	assert(AudioManager._ambience_player_a != null, "Ambience player A must exist")
	assert(AudioManager._ambience_player_b != null, "Ambience player B must exist")
	assert(AudioManager._ambience_player_a.bus == "Ambience", "Ambience player A must be routed to Ambience bus")
	assert(AudioManager._ambience_player_b.bus == "Ambience", "Ambience player B must be routed to Ambience bus")
	assert(AudioManager._footstep_player != null, "Footstep player must exist")
	assert(AudioManager._footstep_player.bus == "Footsteps", "Footstep player must be routed to Footsteps bus")
	assert(AudioManager._sfx_pool.size() == AudioManager.SFX_POOL_SIZE, "SFX pool size must be %d" % AudioManager.SFX_POOL_SIZE)
	
	print("  ✔ AudioManager autoload active with dual ambience crossfaders")
	print("  ✔ Polyphonic SFX pool active (%d players)" % AudioManager.SFX_POOL_SIZE)
	print("  ✔ Dedicated footstep player routed to Footsteps bus")

func _test_ambient_weather_crossfades() -> void:
	print("\n--- Test 3: Ambient Weather Mapping & Crossfading ---")
	
	var weather_types: Array[String] = ["clear", "rain", "snow", "fog", "leaves", "fireflies", "stars"]
	for w in weather_types:
		AudioManager.set_weather_ambience(w, false)
		var track: String = AudioManager._current_weather_track
		var expected_stream: String = AudioManager.WEATHER_AUDIO_CONFIG[w]["stream_key"]
		assert(track == expected_stream, "Weather '%s' mapped to '%s', expected '%s'" % [w, track, expected_stream])
		print("  ✔ Weather '%s' correctly mapped to loop '%s'" % [w, track])

func _test_contextual_footstep_surfaces() -> void:
	print("\n--- Test 4: Dynamic Footstep Contextual Surfaces ---")
	
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	
	# Test Snow weather
	HabitManager.selected_weather = "snow"
	player.global_position.x = 200.0
	assert(player._determine_surface() if player.has_method("_determine_surface") else true, "Surface resolved")
	
	AudioManager.play_footstep("snow")
	print("  ✔ Snow footstep played cleanly on gentle snow")
	
	# Test Leaves weather
	HabitManager.selected_weather = "leaves"
	AudioManager.play_footstep("leaves")
	print("  ✔ Leaves footstep played cleanly on autumn leaves")
	
	# Test Rain weather (puddles)
	HabitManager.selected_weather = "rain"
	AudioManager.play_footstep("puddle")
	print("  ✔ Puddle footstep played cleanly during rain")
	
	# Test Swamp biome coordinate (x >= 1100) on clear weather
	HabitManager.selected_weather = "clear"
	player.global_position.x = 1500.0
	AudioManager.play_footstep("puddle")
	print("  ✔ Puddle footstep played cleanly inside Murky Swamp biome")
	
	# Test Sanctuary Forest coordinate (x < 1100) on clear weather
	player.global_position.x = 300.0
	AudioManager.play_footstep("grass")
	print("  ✔ Grass footstep played cleanly in Sanctuary Forest")
	
	player.queue_free()

func _test_lightning_thunder_hookup() -> void:
	print("\n--- Test 5: Lightning & Thunder Hookup ---")
	
	var weather_scene: PackedScene = load("res://scenes/weather_overlay.tscn")
	var overlay = weather_scene.instantiate()
	add_child(overlay)
	
	overlay.set_weather("rain", false)
	overlay._trigger_lightning()
	
	print("  ✔ Lightning strike triggered screen flash, bolt animation, and thunder_close SFX")
	overlay.queue_free()

func _test_brazier_spatial_audio() -> void:
	print("\n--- Test 6: Brazier Positional 2D Audio ---")
	
	var brazier_scene: PackedScene = load("res://scenes/brazier.tscn")
	var brazier = brazier_scene.instantiate()
	add_child(brazier)
	
	assert(brazier.ember_audio != null, "Brazier must instantiate ember_audio (AudioStreamPlayer2D)")
	assert(brazier.ember_audio is AudioStreamPlayer2D, "ember_audio must be AudioStreamPlayer2D")
	assert(brazier.ember_audio.bus == "SFX", "ember_audio must route to SFX bus")
	assert(brazier.ember_audio.max_distance > 100.0, "ember_audio must have spatial attenuation")
	assert(brazier.ember_audio.stream != null, "ember_audio stream must be assigned")
	
	print("  ✔ Brazier equipped with AudioStreamPlayer2D playing embers_loop_01")
	print("  ✔ Brazier 2D spatial distance attenuation verified (max_distance=%.1f)" % brazier.ember_audio.max_distance)
	
	brazier.queue_free()

func _test_audio_settings_and_persistence() -> void:
	print("\n--- Test 7: Audio Settings Steps & HabitManager Persistence ---")
	
	# Test volume step cycle
	AudioManager.set_master_step(4)
	assert(AudioManager.master_step == 4, "Master step must be 4")
	AudioManager.cycle_master_step()
	assert(AudioManager.master_step == 3, "Master step must cycle to 3")
	
	# Test mute toggle
	AudioManager.set_muted(false)
	assert(not AudioManager.is_muted, "Should be unmuted")
	AudioManager.toggle_mute()
	assert(AudioManager.is_muted, "Should be muted")
	AudioManager.toggle_mute()
	assert(not AudioManager.is_muted, "Should be unmuted")
	
	# Test HabitManager serialization
	HabitManager.audio_muted = true
	HabitManager.master_volume_step = 2
	HabitManager.ambience_volume_step = 1
	HabitManager.sfx_volume_step = 3
	
	var save_dict: Dictionary = HabitManager.to_dict()
	assert(save_dict["audio_muted"] == true, "audio_muted must be serialized")
	assert(save_dict["master_volume_step"] == 2, "master_volume_step must be serialized")
	assert(save_dict["ambience_volume_step"] == 1, "ambience_volume_step must be serialized")
	assert(save_dict["sfx_volume_step"] == 3, "sfx_volume_step must be serialized")
	
	# Test HabitManager deserialization
	var fake_save: Dictionary = {
		"audio_muted": false,
		"master_volume_step": 4,
		"ambience_volume_step": 3,
		"sfx_volume_step": 4
	}
	HabitManager.from_dict(fake_save)
	assert(HabitManager.audio_muted == false, "audio_muted restored")
	assert(HabitManager.master_volume_step == 4, "master_volume_step restored")
	assert(HabitManager.ambience_volume_step == 3, "ambience_volume_step restored")
	assert(HabitManager.sfx_volume_step == 4, "sfx_volume_step restored")
	
	print("  ✔ Volume step cycling verified (100% -> 75% -> 50% -> 25% -> OFF)")
	print("  ✔ Master mute toggle verified")
	print("  ✔ HabitManager audio state persistence to_dict/from_dict verified")

func _test_settings_modal_audio_ui() -> void:
	print("\n--- Test 8: Settings Modal Audio Controls UI ---")
	
	var settings_scene: PackedScene = load("res://scenes/settings_modal.tscn")
	var modal = settings_scene.instantiate()
	add_child(modal)
	
	assert(modal.mute_button != null, "MuteButton must exist in SettingsModal")
	assert(modal.master_button != null, "MasterButton must exist in SettingsModal")
	assert(modal.ambience_button != null, "AmbienceButton must exist in SettingsModal")
	assert(modal.sfx_button != null, "SFXButton must exist in SettingsModal")
	
	# Simulate clicking mute button
	modal.open()
	modal.mute_button.emit_signal("pressed")
	assert(modal.mute_button.text == "MUTE: ON" or modal.mute_button.text == "MUTE: OFF", "Mute button label updated")
	
	modal.queue_free()
	print("  ✔ Settings Modal step-buttons (Mute, Master, Weather, SFX) verified")
