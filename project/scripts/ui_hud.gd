# scripts/ui_hud.gd
# HUD layer displaying habit streak, valley corruption,
# grace shields, focus mana, and quick actions.
extends CanvasLayer

signal urge_beacon_pressed
signal slip_button_pressed
signal chronicle_button_pressed
signal settings_button_pressed

@onready var streak_label: Label = $TopBar/StreakContainer/StreakValue
@onready var corruption_bar: ProgressBar = $TopBar/CorruptionContainer/VBox/BlightBar
@onready var corruption_label: Label = $TopBar/CorruptionContainer/VBox/BlightLabel
@onready var shields_label: Label = $TopBar/ResilienceContainer/HBox/ShieldBox/ShieldsValue
@onready var mana_label: Label = $TopBar/ResilienceContainer/HBox/FocusBox/ManaValue
@onready var urge_button: Button = $BottomBar/UrgeBeaconButton
@onready var chronicle_button: Button = $BottomBar/ChronicleButton
@onready var settings_button: Button = $BottomBar/SettingsButton
@onready var slip_button: Button = $TopBar/SlipButton
@onready var banner_container: PanelContainer = get_node_or_null("BannerContainer")
@onready var banner_label: Label = get_node_or_null("BannerContainer/BannerLabel")

var _banner_tween: Tween

func show_banner(message: String, is_danger: bool = false) -> void:
	if not banner_container or not banner_label:
		return
	banner_label.text = message
	if is_danger:
		banner_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	else:
		banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))
		
	banner_container.visible = true
	banner_container.modulate.a = 0.0
	
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
		
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_container, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(2.2)
	_banner_tween.tween_property(banner_container, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(func(): banner_container.visible = false)


func _ready() -> void:
	HabitManager.streak_updated.connect(_on_streak_updated)
	HabitManager.shield_changed.connect(_on_shield_changed)
	HabitManager.mana_changed.connect(_on_mana_changed)
	SanctuaryState.corruption_changed.connect(_on_corruption_changed)
	
	urge_button.pressed.connect(func(): urge_beacon_pressed.emit())
	slip_button.pressed.connect(func(): slip_button_pressed.emit())
	chronicle_button.pressed.connect(func(): chronicle_button_pressed.emit())
	settings_button.pressed.connect(func(): settings_button_pressed.emit())
	
	# Initial populate
	_on_shield_changed(HabitManager.shields)
	_on_mana_changed(HabitManager.focus_mana)
	_on_corruption_changed(SanctuaryState.corruption_percent)

func _on_streak_updated(days: float, hours: int, mins: int, secs: int) -> void:
	var total_days_int: int = int(days)
	streak_label.text = "%02dd : %02dh : %02dm : %02ds" % [total_days_int, hours, mins, secs]

func _on_shield_changed(new_count: int) -> void:
	if new_count == 0:
		shields_label.text = "0/%d" % HabitManager.max_shields
		shields_label.modulate = Color("ff6b6b")
	else:
		shields_label.text = "%d/%d" % [new_count, HabitManager.max_shields]
		shields_label.modulate = Color("ffffff")

func _on_mana_changed(new_mana: float) -> void:
	mana_label.text = "%.2f" % new_mana

func _on_corruption_changed(pct: float) -> void:
	corruption_bar.value = pct
	corruption_label.text = "VALLEY BLIGHT: %0.1f%%" % pct

func _input(event: InputEvent) -> void:
	# Key B triggers Urge Beacon; Key C opens Chronicles; Key O opens Settings
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			urge_beacon_pressed.emit()
		elif event.keycode == KEY_C:
			chronicle_button_pressed.emit()
		elif event.keycode == KEY_O:
			settings_button_pressed.emit()
