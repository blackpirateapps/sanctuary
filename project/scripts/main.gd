# scripts/main.gd
# Main sanctuary game controller tying together parallax rendering,
# normal-mapped 2D lighting, habit progression, and urge defense trials.
extends Node2D

@onready var dir_light: DirectionalLight2D = $WorldEnvironment/DirectionalLight2D
@onready var shrine_light: PointLight2D = $Shrine/PointLight2D
@onready var shrine_prompt: Label = $Shrine/ShrinePrompt
@onready var ui_hud: CanvasLayer = $UIHUD
@onready var urge_trial: CanvasLayer = $UrgeTrial
@onready var slip_modal: CanvasLayer = $SlipModal
@onready var chronicles_modal: CanvasLayer = $ChroniclesModal
@onready var player: CharacterBody2D = $Player
@onready var shrine: Node2D = $Shrine

var _channel_cooldown: float = 0.0

func _ready() -> void:
	# Connect UI signals
	ui_hud.urge_beacon_pressed.connect(_on_urge_beacon_pressed)
	ui_hud.slip_button_pressed.connect(func(): slip_modal.open())
	ui_hud.chronicle_button_pressed.connect(func(): chronicles_modal.open())
	
	urge_trial.trial_finished.connect(_on_urge_trial_finished)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	_update_ambient_lighting()

func _process(delta: float) -> void:
	if _channel_cooldown > 0.0:
		_channel_cooldown -= delta
		
	# Subtle celestial pulsing on the sacred shrine crystal
	var t: float = Time.get_ticks_msec() / 1000.0
	shrine_light.energy = 1.2 + sin(t * 2.5) * 0.3
	
	# Check distance between player and shrine for purification interaction
	var dist: float = player.global_position.distance_to(shrine.global_position)
	shrine_prompt.visible = (dist < 80.0)
	
	if dist < 80.0 and Input.is_key_pressed(KEY_E) and _channel_cooldown <= 0.0:
		_attempt_shrine_purification()
		_channel_cooldown = 0.8

func _update_ambient_lighting() -> void:
	var col: Color = SanctuaryState.get_ambient_color()
	dir_light.color = col

func _on_corruption_changed(_pct: float) -> void:
	_update_ambient_lighting()

func _on_urge_beacon_pressed() -> void:
	urge_trial.start_trial()

func _on_urge_trial_finished(success: bool) -> void:
	if success:
		# Award immediate restoration bloom
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 3.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)

func _attempt_shrine_purification() -> void:
	if HabitManager.spend_mana(30.0):
		# Radiant shockwave pulse on shrine
		var tw = create_tween()
		tw.tween_property(shrine_light, "energy", 3.2, 0.2).set_trans(Tween.TRANS_BACK)
		tw.tween_property(shrine_light, "energy", 1.2, 0.6).set_trans(Tween.TRANS_SINE)
		
		# Decrement blight by 5%
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 5.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)
	else:
		# Flash red prompt briefly to indicate not enough mana
		var orig_col: Color = shrine_prompt.get_theme_color("font_color")
		shrine_prompt.add_theme_color_override("font_color", Color("ff6b6b"))
		var tw = create_tween()
		tw.tween_interval(0.4)
		tw.tween_callback(func(): shrine_prompt.add_theme_color_override("font_color", orig_col))
