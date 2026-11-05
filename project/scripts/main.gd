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
@onready var player: CharacterBody2D = $Player
@onready var shrine: Node2D = $Shrine

# Monolith landmark in the swamp
@onready var monolith: Node2D = $Monolith
@onready var monolith_light: PointLight2D = $Monolith/VoidLight
@onready var monolith_prompt: Label = $Monolith/MonolithPrompt
@onready var monolith_rune: Sprite2D = $Monolith/VoidRune

# Parallax sprite groups for dynamic crossfade
@onready var swamp_sprites: Array[Sprite2D] = [
	$ParallaxBackground/Swamp2_Distant/Sprite2D,
	$ParallaxBackground/Swamp3_Mid/Sprite2D,
	$ParallaxBackground/Swamp4_Trees/Sprite2D,
	$ParallaxBackground/Swamp5_Mist/Sprite2D
]

var _channel_cooldown: float = 0.0

func _ready() -> void:
	# Connect UI signals
	ui_hud.urge_beacon_pressed.connect(_on_urge_beacon_pressed)
	ui_hud.slip_button_pressed.connect(func(): slip_modal.open())
	ui_hud.chronicle_button_pressed.connect(func(): chronicles_modal.open())
	
	urge_trial.trial_finished.connect(_on_urge_trial_finished)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	_update_ambient_lighting()
	_update_scenery_transition()

func _process(delta: float) -> void:
	if _channel_cooldown > 0.0:
		_channel_cooldown -= delta
		
	var t: float = Time.get_ticks_msec() / 1000.0
	
	# Subtle celestial pulsing on the sacred shrine crystal
	shrine_light.energy = 1.2 + sin(t * 2.5) * 0.3
	
	# Eerie deep void oscillation on the swamp monolith
	monolith_light.energy = 1.4 + sin(t * 1.8 + 1.2) * 0.4
	# Cycle the monolith rune frame
	monolith_rune.frame = int(t * 3.5) % 4
	
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

	# Dynamic scenery crossfade based on player position
	_update_scenery_transition()

func _update_scenery_transition() -> void:
	var player_x: float = player.global_position.x
	var raw_t: float = (player_x - TRANSITION_START_X) / (TRANSITION_END_X - TRANSITION_START_X)
	var t: float = clampf(raw_t, 0.0, 1.0)
	# Smoothstep interpolation
	var blend: float = t * t * (3.0 - 2.0 * t)
	
	# Crossfade parallax backgrounds
	# Forest Sky sits directly over Swamp Sky: fading Forest Sky reveals the Swamp Sky underneath
	$ParallaxBackground/Layer1_Sky/Sprite2D.modulate.a = 1.0 - blend
	$ParallaxBackground/Layer2_Distant/Sprite2D.modulate.a = 1.0 - blend
	$ParallaxBackground/Layer3_Mid/Sprite2D.modulate.a = 1.0 - blend
	$ParallaxBackground/Layer4_Mist/Sprite2D.modulate.a = 1.0 - blend
	
	for s in swamp_sprites:
		s.modulate.a = blend
		
	# Blend ambient directional light between sanctuary state color and murky swamp tint
	var base_color: Color = SanctuaryState.get_ambient_color()
	var swamp_undertone: Color = Color("121a22")
	dir_light.color = base_color.lerp(swamp_undertone, blend * 0.7)

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
