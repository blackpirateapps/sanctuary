# scripts/main.gd
# Main sanctuary game controller tying together parallax rendering,
# normal-mapped 2D lighting, habit progression, and urge defense trials.
extends Node2D

@onready var dir_light: DirectionalLight2D = $WorldEnvironment/DirectionalLight2D
@onready var shrine_light: PointLight2D = $Shrine/PointLight2D
@onready var ui_hud: CanvasLayer = $UIHUD
@onready var urge_trial: CanvasLayer = $UrgeTrial
@onready var slip_modal: CanvasLayer = $SlipModal
@onready var chronicles_modal: CanvasLayer = $ChroniclesModal
@onready var player: CharacterBody2D = $Player
@onready var shrine: Node2D = $Shrine

var shrine_purified: bool = false

func _ready() -> void:
	# Connect UI signals
	ui_hud.urge_beacon_pressed.connect(_on_urge_beacon_pressed)
	ui_hud.slip_button_pressed.connect(func(): slip_modal.open())
	ui_hud.chronicle_button_pressed.connect(func(): chronicles_modal.open())
	
	urge_trial.trial_finished.connect(_on_urge_trial_finished)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	_update_ambient_lighting()

func _process(_delta: float) -> void:
	# Subtle celestial pulsing on the sacred shrine
	var t: float = Time.get_ticks_msec() / 1000.0
	shrine_light.energy = 1.0 + sin(t * 2.0) * 0.25
	
	# Check distance between player and shrine for purification interaction
	var dist: float = player.global_position.distance_to(shrine.global_position)
	if dist < 60.0 and Input.is_key_pressed(KEY_E):
		_attempt_shrine_purification()

func _update_ambient_lighting() -> void:
	var col: Color = SanctuaryState.get_ambient_color()
	dir_light.color = col

func _on_corruption_changed(_pct: float) -> void:
	_update_ambient_lighting()

func _on_urge_beacon_pressed() -> void:
	get_tree().paused = false # Keep scene running or pause background
	urge_trial.start_trial()

func _on_urge_trial_finished(success: bool) -> void:
	if success:
		# Award immediate restoration bloom
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 3.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)

func _attempt_shrine_purification() -> void:
	if HabitManager.spend_mana(30.0):
		# Flash shrine light
		var tw = create_tween()
		tw.tween_property(shrine_light, "energy", 3.0, 0.3)
		tw.tween_property(shrine_light, "energy", 1.2, 0.5)
		SanctuaryState.corruption_percent = clampf(SanctuaryState.corruption_percent - 5.0, 0.0, 100.0)
		SanctuaryState.corruption_changed.emit(SanctuaryState.corruption_percent)
