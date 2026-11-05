# scripts/main.gd
# Main sanctuary game controller tying together parallax rendering,
# normal-mapped 2D lighting, habit progression, urge defense trials,
# and seamless multi-biome scenery transitions.
extends Node2D

const TRANSITION_START_X: float = 950.0
const TRANSITION_END_X: float = 1650.0

@onready var dir_light: DirectionalLight2D = $WorldEnvironment/DirectionalLight2D
@onready var shrine_light: PointLight2D = $Shrine/PointLight2D
@onready var shrine_prompt: Label = $Shrine/ShrinePrompt
@onready var ui_hud: CanvasLayer = $UIHUD
@onready var urge_trial: CanvasLayer = $UrgeTrial
@onready var slip_modal: CanvasLayer = $SlipModal
@onready var chronicles_modal: CanvasLayer = $ChroniclesModal
@onready var settings_modal: CanvasLayer = $SettingsModal
@onready var weather_overlay: CanvasLayer = $WeatherOverlay
@onready var player: CharacterBody2D = $Player
@onready var shrine: Node2D = $Shrine

# Monolith landmark in the swamp
@onready var monolith: Node2D = $Monolith
@onready var monolith_light: PointLight2D = $Monolith/VoidLight
@onready var monolith_prompt: Label = $Monolith/MonolithPrompt
@onready var monolith_rune: Sprite2D = $Monolith/VoidRune

# Abyssal Relic landmark in the deep swamp
@onready var abyssal_relic: Node2D = $AbyssalRelic
@onready var abyssal_light: PointLight2D = $AbyssalRelic/VoidLight
@onready var abyssal_prompt: Label = $AbyssalRelic/RelicPrompt
@onready var abyssal_rune: Sprite2D = $AbyssalRelic/VoidRune

# Waving flags
@onready var flags: Array[Sprite2D] = [
	$SwampProps/Flag1,
	$SwampProps/Flag2
]

# Parallax sprite groups for dynamic crossfade
@onready var swamp_sprites: Array[Sprite2D] = [
	$ParallaxBackground/Swamp2_Distant/Sprite2D,
	$ParallaxBackground/Swamp3_Mid/Sprite2D,
	$ParallaxBackground/Swamp4_Trees/Sprite2D,
	$ParallaxBackground/Swamp5_Mist/Sprite2D
]

const BIOME_WEATHER_COOLDOWN_TIME: float = 35.0
const ALL_WEATHERS: Array[String] = ["clear", "rain", "snow", "fog", "leaves", "fireflies", "stars"]

var _channel_cooldown: float = 0.0
var _current_biome_id: int = -1
var _biome_weather_cooldown: float = 0.0
var _night_blend: float = 0.0

func _ready() -> void:
	# Connect UI signals
	ui_hud.urge_beacon_pressed.connect(_on_urge_beacon_pressed)
	ui_hud.slip_button_pressed.connect(func(): slip_modal.open())
	ui_hud.chronicle_button_pressed.connect(func(): chronicles_modal.open())
	ui_hud.settings_button_pressed.connect(func(): settings_modal.open())
	
	urge_trial.trial_finished.connect(_on_urge_trial_finished)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	# Connect combat and death events
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
		
	# Connect enemy defeat signals
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(_on_enemy_defeated)
	
	# Initialize starting biome and initial grace cooldown
	_current_biome_id = _get_current_biome(player.global_position.x)
	_biome_weather_cooldown = 15.0
	
	# Setting weather manually grants grace period so walking doesn't instantly overwrite user selection
	HabitManager.weather_changed.connect(func(_w): _biome_weather_cooldown = max(_biome_weather_cooldown, 30.0))
	
	_update_ambient_lighting()
	_update_scenery_transition()

func _process(delta: float) -> void:
	if _channel_cooldown > 0.0:
		_channel_cooldown -= delta
		
	# Smoothly adjust night darkening factor when starry night is active
	var target_night: float = 1.0 if HabitManager.selected_weather == "stars" else 0.0
	_night_blend = move_toward(_night_blend, target_night, delta * 1.5)
	
	# Biome transition weather change with cooldown protection against back-and-forth oscillation
	if _biome_weather_cooldown > 0.0:
		_biome_weather_cooldown -= delta
		
	var biome_now: int = _get_current_biome(player.global_position.x)
	if _current_biome_id == -1:
		_current_biome_id = biome_now
	elif biome_now != _current_biome_id:
		_current_biome_id = biome_now
		if _biome_weather_cooldown <= 0.0:
			_trigger_biome_weather_change()
			_biome_weather_cooldown = BIOME_WEATHER_COOLDOWN_TIME
		
	var t: float = Time.get_ticks_msec() / 1000.0
	
	# Subtle celestial pulsing on the sacred shrine crystal
	shrine_light.energy = 1.2 + sin(t * 2.5) * 0.3
	
	# Eerie deep void oscillation on the swamp monolith
	monolith_light.energy = 1.4 + sin(t * 1.8 + 1.2) * 0.4
	# Cycle the monolith rune frame
	monolith_rune.frame = int(t * 3.5) % 4
	
	# Deep void oscillation on the abyssal relic
	abyssal_light.energy = 1.6 + sin(t * 2.2 + 0.8) * 0.4
	abyssal_rune.frame = int(t * 4.0) % 4
	
	# Cycle waving flags
	for f in flags:
		f.frame = int(t * 6.0) % 4
	
	# Check distance between player and sacred shrine
	var dist_shrine: float = player.global_position.distance_to(shrine.global_position)
	shrine_prompt.visible = (dist_shrine < 80.0)
	if dist_shrine < 80.0 and Input.is_key_pressed(KEY_E) and _channel_cooldown <= 0.0:
		_attempt_shrine_purification()
		_channel_cooldown = 0.8
		
	# Check distance between player and corrupted monolith
	var dist_monolith: float = player.global_position.distance_to(monolith.global_position)
	monolith_prompt.visible = (dist_monolith < 80.0)
	if dist_monolith < 80.0 and Input.is_key_pressed(KEY_B) and not urge_trial.visible:
		urge_trial.start_trial()

	# Check distance between player and abyssal relic
	var dist_relic: float = player.global_position.distance_to(abyssal_relic.global_position)
	abyssal_prompt.visible = (dist_relic < 80.0)
	if dist_relic < 80.0 and Input.is_key_pressed(KEY_E) and _channel_cooldown <= 0.0:
		_commune_with_abyssal_relic()
		_channel_cooldown = 1.5

	# Dynamic scenery crossfade based on player position
	_update_scenery_transition()

func _get_current_biome(x: float) -> int:
	if x < 1100.0:
		return 0 # Sanctuary Forest
	elif x < 2700.0:
		return 1 # Murky Outskirts
	elif x < 4200.0:
		return 2 # Sunken Canopy
	else:
		return 3 # Abyssal Heart

func _trigger_biome_weather_change() -> void:
	var pool: Array[String] = []
	for w in ALL_WEATHERS:
		if w != HabitManager.selected_weather:
			pool.append(w)
	if pool.size() > 0:
		var picked: String = pool[randi() % pool.size()]
		HabitManager.set_weather(picked)

func _update_scenery_transition() -> void:
	var player_x: float = player.global_position.x
	var raw_t: float = (player_x - TRANSITION_START_X) / (TRANSITION_END_X - TRANSITION_START_X)
	var t: float = clampf(raw_t, 0.0, 1.0)
	# Smoothstep interpolation
	var blend: float = t * t * (3.0 - 2.0 * t)
	
	# Starry night nocturnal darkening tints
	var night_sky_tint: Color = Color(0.12, 0.12, 0.22, 1.0) # Deep midnight indigo sky
	var sky_tint: Color = Color.WHITE.lerp(night_sky_tint, _night_blend)
	
	var night_tree_tint: Color = Color(0.28, 0.28, 0.40, 1.0) # Dark silhouettes for trees
	var tree_tint: Color = Color.WHITE.lerp(night_tree_tint, _night_blend)
	
	# Crossfade parallax backgrounds
	# Forest Sky sits directly over Swamp Sky: fading Forest Sky reveals the Swamp Sky underneath
	$ParallaxBackground/Swamp1_Sky/Sprite2D.modulate = Color(sky_tint.r, sky_tint.g, sky_tint.b, 1.0)
	$ParallaxBackground/Layer1_Sky/Sprite2D.modulate = Color(sky_tint.r, sky_tint.g, sky_tint.b, 1.0 - blend)
	
	$ParallaxBackground/Layer2_Distant/Sprite2D.modulate = Color(tree_tint.r, tree_tint.g, tree_tint.b, 1.0 - blend)
	$ParallaxBackground/Layer3_Mid/Sprite2D.modulate = Color(tree_tint.r, tree_tint.g, tree_tint.b, 1.0 - blend)
	$ParallaxBackground/Layer4_Mist/Sprite2D.modulate = Color(tree_tint.r, tree_tint.g, tree_tint.b, 1.0 - blend)
	
	for s in swamp_sprites:
		s.modulate = Color(tree_tint.r, tree_tint.g, tree_tint.b, blend)
		
	# Blend ambient directional light between sanctuary state color, murky swamp tint, and starry midnight
	var base_color: Color = SanctuaryState.get_ambient_color()
	var swamp_undertone: Color = Color("121a22")
	var day_color: Color = base_color.lerp(swamp_undertone, blend * 0.7)
	var night_undertone: Color = Color("060610") # Deep starry night ambient
	
	dir_light.color = day_color.lerp(night_undertone, _night_blend * 0.8)
	dir_light.energy = lerpf(0.75, 0.35, _night_blend)

func _update_ambient_lighting() -> void:
	_update_scenery_transition()

func _on_corruption_changed(_pct: float) -> void:
	_update_ambient_lighting()

func _on_urge_beacon_pressed() -> void:
	urge_trial.start_trial()

func _on_urge_trial_finished(success: bool) -> void:
	if success:
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 3.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)

func _attempt_shrine_purification() -> void:
	if HabitManager.spend_mana(30.0):
		var tw = create_tween()
		tw.tween_property(shrine_light, "energy", 3.2, 0.2).set_trans(Tween.TRANS_BACK)
		tw.tween_property(shrine_light, "energy", 1.2, 0.6).set_trans(Tween.TRANS_SINE)
		
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 5.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)
	else:
		var orig_col: Color = shrine_prompt.get_theme_color("font_color")
		shrine_prompt.add_theme_color_override("font_color", Color("ff6b6b"))
		var tw = create_tween()
		tw.tween_interval(0.4)
		tw.tween_callback(func(): shrine_prompt.add_theme_color_override("font_color", orig_col))

func _commune_with_abyssal_relic() -> void:
	# Trigger player meditation stance
	player.call("_trigger_defend")
	
	# Celestial / void flare on relic
	var tw = create_tween()
	tw.tween_property(abyssal_light, "energy", 3.5, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_property(abyssal_light, "energy", 1.6, 0.8).set_trans(Tween.TRANS_SINE)
	
	# Cleanse blight by 5% and award 25 Focus Mana as a deep meditation reward
	SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 5.0, 0.0, 100.0)
	SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)
	HabitManager.add_mana(25.0)
	
	# Display floating message
	var orig_text: String = abyssal_prompt.text
	abyssal_prompt.text = "Clarity Restored! (+25 Focus, -5% Blight)"
	var prompt_tw = create_tween()
	prompt_tw.tween_interval(1.8)
	prompt_tw.tween_callback(func(): abyssal_prompt.text = orig_text)

func _on_player_died() -> void:
	var lost: float = HabitManager.deduct_coins_on_death(50.0)
	ui_hud.show_banner("Defeated! Lost %d Coins. Returned to Sanctuary." % int(lost), true)
	if AudioManager:
		AudioManager.play_sfx("thunder_close", Vector2(0.85, 0.95), -2.0)
		
	await get_tree().create_timer(0.6).timeout
	player.respawn(Vector2(120, 290))
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("reset_to_spawn"):
			enemy.reset_to_spawn()

func _on_enemy_defeated(_pos: Vector2) -> void:
	ui_hud.show_banner("Victory! Tikbalang Banished (+100 Coins)", false)
	SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 3.0, 0.0, 100.0)
	SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)

