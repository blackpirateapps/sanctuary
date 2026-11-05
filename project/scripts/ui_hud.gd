# scripts/ui_hud.gd
# HUD layer displaying habit streak, valley corruption,
# grace shields, focus mana, and quick actions.
extends CanvasLayer

signal urge_beacon_pressed
signal slip_button_pressed
signal chronicle_button_pressed

@onready var streak_label: Label = $TopBar/StreakContainer/StreakValue
@onready var corruption_bar: ProgressBar = $TopBar/CorruptionContainer/VBox/BlightBar
@onready var corruption_label: Label = $TopBar/CorruptionContainer/VBox/BlightLabel
@onready var shields_label: Label = $TopBar/ResilienceContainer/HBox/ShieldsValue
@onready var mana_label: Label = $TopBar/ResilienceContainer/HBox/ManaValue
@onready var urge_button: Button = $BottomBar/UrgeBeaconButton
@onready var chronicle_button: Button = $BottomBar/ChronicleButton
@onready var slip_button: Button = $TopBar/SlipButton

func _ready() -> void:
	HabitManager.streak_updated.connect(_on_streak_updated)
	HabitManager.shield_changed.connect(_on_shield_changed)
	HabitManager.mana_changed.connect(_on_mana_changed)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	urge_button.pressed.connect(func(): urge_beacon_pressed.emit())
	slip_button.pressed.connect(func(): slip_button_pressed.emit())
	chronicle_button.pressed.connect(func(): chronicle_button_pressed.emit())
	
	# Initial populate
	_on_shield_changed(HabitManager.shields)
	_on_mana_changed(HabitManager.focus_mana)
	_on_corruption_changed(SanctuaryState.corruption_percent)

func _on_streak_updated(days: float, hours: int, mins: int, secs: int) -> void:
	var total_days_int: int = int(days)
	streak_label.text = "%02dd : %02dh : %02dm : %02ds" % [total_days_int, hours, mins, secs]

func _on_shield_changed(new_count: int) -> void:
	var icons: String = ""
	for i in range(new_count):
		icons += "🛡️ "
	if new_count == 0:
		icons = "BROKEN"
	shields_label.text = icons

func _on_mana_changed(new_mana: float) -> void:
	mana_label.text = "✦ %d" % int(new_mana)

func _on_corruption_changed(pct: float) -> void:
	corruption_bar.value = pct
	corruption_label.text = "VALLEY BLIGHT: %0.1f%%" % pct

func _input(event: InputEvent) -> void:
	# Spacebar triggers urge beacon if not typing
	if event.is_action_pressed("ui_select") and not urge_button.has_focus():
		urge_beacon_pressed.emit()
