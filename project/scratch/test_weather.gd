# scratch/test_weather.gd
# Headless unit test verifying the weather phenomenon overlay system,
# Cozy-Space settings modal, icons, behind-the-trees stars, scenery darkening,
# and biome transition random weather change with cooldown protection.
extends Node

func _ready() -> void:
	print("\n========================================================")
	print("🌦️ RUNNING WEATHER PHENOMENON & SETTINGS UNIT TESTS 🌦️")
	print("========================================================")
	
	_test_asset_integrity()
	_test_weather_overlay_presets()
	_test_weather_state_and_persistence()
	_test_settings_modal_integration()
	_test_rain_lightning_and_splashes()
	_test_starry_night_behind_trees()
	_test_scenery_darkening()
	_test_biome_transition_and_cooldown()
	
	print("\n========================================================")
	print("🎉 ALL WEATHER PHENOMENON TESTS PASSED SUCCESSFULLY! 🎉")
	print("========================================================\n")
	get_tree().quit(0)

func _test_asset_integrity() -> void:
	print("\n--- Test 1: Weather Asset & Icon Integrity ---")
	
	# Weather Icons
	var weather_icons: Dictionary = {
		"clear": "res://assets/weather/icons/clear_day.png",
		"rain": "res://assets/weather/icons/light_rain.png",
		"snow": "res://assets/weather/icons/light_snow.png",
		"fog": "res://assets/weather/icons/fog.png",
		"leaves": "res://assets/weather/icons/autumn_leaves.png",
		"fireflies": "res://assets/weather/icons/firefly.png",
		"stars": "res://assets/weather/icons/clear_night.png"
	}
	for id in weather_icons:
		var path: String = weather_icons[id]
		assert(ResourceLoader.exists(path), "Icon must exist: %s" % path)
		var tex: Texture2D = load(path) as Texture2D
		assert(tex != null, "Texture must load: %s" % path)
		print("  ✔ Weather icon '%s' verified (%s)" % [id, path.get_file()])
		
	# Cozy-Space UI Textures
	var ui_assets: Array[String] = [
		"res://assets/ui/settings/icon-gear.png",
		"res://assets/ui/settings/icon-cross.png",
		"res://assets/ui/settings/icon-check.png",
		"res://assets/ui/settings/panel-dark.png",
		"res://assets/ui/settings/button-teal-normal.png",
		"res://assets/ui/settings/button-amber-normal.png"
	]
	for path in ui_assets:
		assert(ResourceLoader.exists(path), "UI asset must exist: %s" % path)
		var tex: Texture2D = load(path) as Texture2D
		assert(tex != null, "UI asset texture must load: %s" % path)
		print("  ✔ Cozy-Space UI asset verified: %s" % path.get_file())

func _test_weather_overlay_presets() -> void:
	print("\n--- Test 2: Weather Overlay Scene & Presets Verification ---")
	var overlay_scene: PackedScene = load("res://scenes/weather_overlay.tscn")
	assert(overlay_scene != null, "weather_overlay.tscn must exist and load")
	var overlay: CanvasLayer = overlay_scene.instantiate()
	add_child(overlay)
	
	assert(overlay.has_node("WeatherRect"), "Must have WeatherRect node")
	assert(overlay.has_node("ScreenFlash"), "Must have ScreenFlash node")
	assert(overlay.has_node("LightningBolt"), "Must have LightningBolt node")
	assert(overlay.has_node("RainSplashes"), "Must have RainSplashes node")
	
	var expected_counts: Dictionary = {
		"rain": 16,
		"snow": 32,
		"fog": 32,
		"leaves": 32,
		"fireflies": 32,
		"stars": 32
	}
	
	for w_id in expected_counts:
		assert(overlay._presets.has(w_id), "Preset must exist: %s" % w_id)
		var frames: Array = overlay._presets[w_id]["frames"]
		var count: int = frames.size()
		var expected: int = expected_counts[w_id]
		assert(count == expected, "Preset '%s' expected %d frames, got %d" % [w_id, expected, count])
		print("  ✔ Preset '%s': %d/%d seamless frames loaded cleanly" % [w_id, count, expected])
		
	overlay.queue_free()

func _test_weather_state_and_persistence() -> void:
	print("\n--- Test 3: HabitManager Persistence & Signal Propagation ---")
	var signal_received: Array[String] = []
	var cb: Callable = func(id: String): signal_received.append(id)
	HabitManager.weather_changed.connect(cb)
	
	# Set weather to rain
	HabitManager.set_weather("rain")
	assert(HabitManager.selected_weather == "rain", "Selected weather should be 'rain'")
	assert(signal_received.has("rain"), "weather_changed signal must fire with 'rain'")
	
	# Verify to_dict and from_dict
	var save_dict: Dictionary = HabitManager.to_dict()
	assert(save_dict.has("selected_weather"), "Save dictionary must contain 'selected_weather'")
	assert(save_dict["selected_weather"] == "rain", "Save dictionary value must match")
	print("  ✔ HabitManager.to_dict() correctly serialized selected_weather='rain'")
	
	# Simulate loading
	var new_data: Dictionary = save_dict.duplicate()
	new_data["selected_weather"] = "snow"
	HabitManager.from_dict(new_data)
	assert(HabitManager.selected_weather == "snow", "HabitManager.from_dict() must restore weather")
	print("  ✔ HabitManager.from_dict() restored selected_weather='snow'")
	
	# Reset to clear
	HabitManager.set_weather("clear")
	HabitManager.weather_changed.disconnect(cb)

func _test_settings_modal_integration() -> void:
	print("\n--- Test 4: Settings Modal Grid & Buttons Verification ---")
	var modal_scene: PackedScene = load("res://scenes/settings_modal.tscn")
	assert(modal_scene != null, "settings_modal.tscn must exist and load")
	var modal: CanvasLayer = modal_scene.instantiate()
	add_child(modal)
	
	assert(modal.WEATHER_OPTIONS.size() == 7, "Must have exactly 7 weather options")
	var grid: GridContainer = modal.weather_grid
	assert(grid.get_child_count() == 7, "WeatherGrid must populate 7 cards")
	
	# Verify switching weather via card press
	modal._on_card_pressed("leaves")
	assert(HabitManager.selected_weather == "leaves", "Pressing leaves card should set weather")
	print("  ✔ Clicking 'leaves' card updated active weather to 'leaves'")
	
	modal.close()
	assert(modal.visible == false, "Closing modal sets visible = false")
	print("  ✔ Modal open/close state validated")
	
	modal.queue_free()

func _test_rain_lightning_and_splashes() -> void:
	print("\n--- Test 5: Rain Dynamics (Lightning & Splashes) ---")
	var overlay_scene: PackedScene = load("res://scenes/weather_overlay.tscn")
	var overlay: CanvasLayer = overlay_scene.instantiate()
	add_child(overlay)
	
	# When rain is active
	overlay.set_weather("rain", false)
	assert(overlay.current_weather == "rain", "Current weather should be rain")
	assert(overlay.rain_splashes.emitting == true, "Rain splashes must emit during rain")
	print("  ✔ Rain splashes active during rain")
	
	# Trigger lightning
	overlay._trigger_lightning()
	assert(overlay.lightning_bolt.visible == true, "Lightning bolt must be visible on strike")
	assert(overlay.screen_flash.color.a > 0.0, "Screen flash must illuminate on strike")
	print("  ✔ Lightning strike triggered screen flash and bolt sprite")
	
	# When switching to clear
	overlay.set_weather("clear", false)
	assert(overlay.rain_splashes.emitting == false, "Splashes must stop when clear")
	print("  ✔ Splashes deactivate when clearing weather")
	
	overlay.queue_free()

func _test_starry_night_behind_trees() -> void:
	print("\n--- Test 6: Starry Night Behind Trees Placement ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "main.tscn must exist and load")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Verify Sky_Stars is placed in ParallaxBackground
	assert(main.has_node("ParallaxBackground/Sky_Stars"), "ParallaxBackground must have Sky_Stars layer")
	var sky_stars = main.get_node("ParallaxBackground/Sky_Stars")
	var stars_rect = sky_stars.get_node("StarsRect")
	assert(stars_rect != null, "Sky_Stars must contain StarsRect")
	
	# Verify layer order: Sky_Stars index must be BEFORE Layer2_Distant (trees)
	var sky_stars_idx = sky_stars.get_index()
	var layer2_idx = main.get_node("ParallaxBackground/Layer2_Distant").get_index()
	assert(sky_stars_idx < layer2_idx, "Sky_Stars (index %d) must render BEHIND Layer2_Distant trees (index %d)" % [sky_stars_idx, layer2_idx])
	print("  ✔ Sky_Stars correctly positioned in ParallaxBackground behind distant & mid trees")
	
	# Set weather to stars
	HabitManager.set_weather("stars")
	var overlay = main.weather_overlay
	assert(overlay.current_weather == "stars", "Overlay current weather should be stars")
	assert(overlay.weather_rect.texture == null, "Foreground WeatherRect MUST be null during stars so it does not draw in front of trees")
	assert(stars_rect.modulate.a > 0.0 or overlay.background_stars_rect != null, "Background stars rect assigned and active")
	print("  ✔ Stars strictly render in the deep sky behind trees, never in foreground")
	
	# Clean up
	HabitManager.set_weather("clear")
	main.queue_free()

func _test_scenery_darkening() -> void:
	print("\n--- Test 7: Scenery Darkening during Starry Night ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Initially clear weather
	HabitManager.set_weather("clear")
	main._process(0.016)
	main._update_scenery_transition()
	var day_energy = main.dir_light.energy
	assert(day_energy >= 0.7, "Day directional light energy should be >= 0.7")
	
	# Switch to stars: simulate multiple process frames for smooth darkening transition
	HabitManager.set_weather("stars")
	for i in range(120): # ~2 seconds
		main._process(0.016)
	
	assert(main._night_blend >= 0.95, "_night_blend should reach ~1.0 during stars")
	assert(main.dir_light.energy < day_energy, "Directional light energy must decrease during starry night (was %f, now %f)" % [day_energy, main.dir_light.energy])
	print("  ✔ Ambient directional light dimmed: energy reduced from %.2f to %.2f" % [day_energy, main.dir_light.energy])
	print("  ✔ Night sky and tree silhouettes darkened via _night_blend = %.2f" % main._night_blend)
	
	# Switch back to clear
	HabitManager.set_weather("clear")
	for i in range(120):
		main._process(0.016)
	assert(main._night_blend <= 0.05, "_night_blend should return to 0.0 when clearing stars")
	print("  ✔ Scenery restored to daytime ambient on clear weather")
	
	main.queue_free()

func _test_biome_transition_and_cooldown() -> void:
	print("\n--- Test 8: Biome Transition & Cooldown Mechanics ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Verify biome detection boundaries
	assert(main._get_current_biome(200.0) == 0, "x=200 should be Biome 0 (Forest)")
	assert(main._get_current_biome(1500.0) == 1, "x=1500 should be Biome 1 (Swamp Outskirts)")
	assert(main._get_current_biome(3200.0) == 2, "x=3200 should be Biome 2 (Sunken Canopy)")
	assert(main._get_current_biome(4800.0) == 3, "x=4800 should be Biome 3 (Abyssal Heart)")
	print("  ✔ All 4 biome boundaries detected correctly")
	
	# Simulate player starting in Forest with initial cooldown expired
	main.player.global_position.x = 200.0
	main._current_biome_id = 0
	HabitManager.set_weather("clear")
	main._biome_weather_cooldown = 0.0 # Force cooldown expired after setting clear
	
	# Player crosses boundary into Swamp Outskirts (x = 1150)
	main.player.global_position.x = 1150.0
	main._process(0.016)
	
	var weather_after_crossing = HabitManager.selected_weather
	assert(main._current_biome_id == 1, "Current biome should update to 1")
	assert(weather_after_crossing != "clear", "Weather should randomly change upon entering new biome (now '%s')" % weather_after_crossing)
	assert(main._biome_weather_cooldown > 30.0, "Cooldown should be set to ~35s after transition (is %.1fs)" % main._biome_weather_cooldown)
	print("  ✔ Weather changed from 'clear' to '%s' on entering Swamp Outskirts" % weather_after_crossing)
	print("  ✔ Biome cooldown set to %.1fs" % main._biome_weather_cooldown)
	
	# Now player immediately steps back into Forest (x = 1050) while cooldown is active
	main.player.global_position.x = 1050.0
	main._process(0.1) # 0.1s later
	
	assert(main._current_biome_id == 0, "Biome ID updated to Forest (0)")
	assert(HabitManager.selected_weather == weather_after_crossing, "Weather must NOT change because cooldown is active (cooldown=%.1fs)" % main._biome_weather_cooldown)
	print("  ✔ Back-and-forth oscillation protected: weather remained '%s'" % HabitManager.selected_weather)
	
	# Player steps forward again to x = 1150
	main.player.global_position.x = 1150.0
	main._process(0.1)
	assert(HabitManager.selected_weather == weather_after_crossing, "Weather still unchanged during active cooldown")
	print("  ✔ Rapid back-and-forth crossing prevents hard weather changes")
	
	HabitManager.set_weather("clear")
	main.queue_free()
