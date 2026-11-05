# scripts/settings_modal.gd
# In-game settings modal built with Cozy-Space UI pixel styling,
# allowing real-time selection of 7 atmospheric weather phenomena.
extends CanvasLayer

signal settings_closed

@onready var modal_root: Control = $Modal
@onready var close_button: Button = $Modal/Panel/VBox/Header/CloseButton
@onready var bottom_close_button: Button = $Modal/Panel/VBox/Footer/CloseButton
@onready var weather_grid: GridContainer = $Modal/Panel/VBox/WeatherSection/Scroll/WeatherGrid

const WEATHER_OPTIONS: Array[Dictionary] = [
	{
		"id": "clear",
		"name": "Clear Sky",
		"desc": "Tranquil clear dawn",
		"icon": "res://assets/weather/icons/clear_day.png"
	},
	{
		"id": "rain",
		"name": "Light Rain",
		"desc": "Soft rain & lightning",
		"icon": "res://assets/weather/icons/light_rain.png"
	},
	{
		"id": "snow",
		"name": "Gentle Snow",
		"desc": "Peaceful snowfall",
		"icon": "res://assets/weather/icons/light_snow.png"
	},
	{
		"id": "fog",
		"name": "Thin Fog",
		"desc": "Ethereal low canopy mist",
		"icon": "res://assets/weather/icons/fog.png"
	},
	{
		"id": "leaves",
		"name": "Autumn Leaves",
		"desc": "Drifting crimson foliage",
		"icon": "res://assets/weather/icons/autumn_leaves.png"
	},
	{
		"id": "fireflies",
		"name": "Fireflies",
		"desc": "Mystical glowing motes",
		"icon": "res://assets/weather/icons/firefly.png"
	},
	{
		"id": "stars",
		"name": "Starry Night",
		"desc": "Twinkling celestial sky",
		"icon": "res://assets/weather/icons/clear_night.png"
	}
]

var _button_map: Dictionary = {}

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)
	bottom_close_button.pressed.connect(close)
	
	_build_weather_grid()
	
	# Listen to external changes to keep active button synced
	HabitManager.weather_changed.connect(_on_weather_changed)

func open() -> void:
	visible = true
	_update_active_states(HabitManager.selected_weather)

func close() -> void:
	visible = false
	settings_closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_O:
			close()
			get_viewport().set_input_as_handled()

func _build_weather_grid() -> void:
	for child in weather_grid.get_children():
		child.queue_free()
	_button_map.clear()
	
	for opt in WEATHER_OPTIONS:
		var card: Button = Button.new()
		card.custom_minimum_size = Vector2(94, 68)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Custom VBox inside button for pixel icon and text
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Icon row with optional active check
		var icon_row: HBoxContainer = HBoxContainer.new()
		icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if ResourceLoader.exists(opt["icon"]):
			icon_rect.texture = load(opt["icon"])
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_row.add_child(icon_rect)
		
		var check_icon: TextureRect = TextureRect.new()
		check_icon.name = "CheckIcon"
		check_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		check_icon.custom_minimum_size = Vector2(16, 16)
		check_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if ResourceLoader.exists("res://assets/ui/settings/icon-check.png"):
			check_icon.texture = load("res://assets/ui/settings/icon-check.png")
		check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_icon.visible = false
		icon_row.add_child(check_icon)
		
		var name_label: Label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = opt["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var status_label: Label = Label.new()
		status_label.name = "StatusLabel"
		status_label.text = ""
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 8)
		status_label.add_theme_color_override("font_color", Color("ffd56b"))
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		vbox.add_child(icon_row)
		vbox.add_child(name_label)
		vbox.add_child(status_label)
		card.add_child(vbox)
		
		var weather_id: String = opt["id"]
		card.pressed.connect(func(): _on_card_pressed(weather_id))
		
		weather_grid.add_child(card)
		_button_map[weather_id] = card

	_apply_styles_to_cards()

func _apply_styles_to_cards() -> void:
	_update_active_states(HabitManager.selected_weather)

func _on_card_pressed(weather_id: String) -> void:
	HabitManager.set_weather(weather_id)
	_update_active_states(weather_id)

func _on_weather_changed(weather_id: String) -> void:
	if visible:
		_update_active_states(weather_id)

func _update_active_states(active_id: String) -> void:
	for opt in WEATHER_OPTIONS:
		var w_id: String = opt["id"]
		if not _button_map.has(w_id):
			continue
		var btn: Button = _button_map[w_id]
		var check: TextureRect = btn.find_child("CheckIcon", true, false)
		var status: Label = btn.find_child("StatusLabel", true, false)
		var name_lbl: Label = btn.find_child("NameLabel", true, false)
		
		var is_active: bool = (w_id == active_id)
		
		if is_active:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if check:
				check.visible = true
			if status:
				status.text = "ACTIVE"
				status.add_theme_color_override("font_color", Color("ffe066"))
			if name_lbl:
				name_lbl.add_theme_color_override("font_color", Color("ffffff"))
			_set_card_style(btn, true)
		else:
			btn.modulate = Color(0.85, 0.85, 0.88, 0.9)
			if check:
				check.visible = false
			if status:
				status.text = ""
			if name_lbl:
				name_lbl.add_theme_color_override("font_color", Color("c0bcc9"))
			_set_card_style(btn, false)

func _set_card_style(btn: Button, is_active: bool) -> void:
	var style_normal: StyleBoxTexture = StyleBoxTexture.new()
	var style_hover: StyleBoxTexture = StyleBoxTexture.new()
	var style_pressed: StyleBoxTexture = StyleBoxTexture.new()
	
	var prefix: String = "button-amber" if is_active else "button-teal"
	style_normal.texture = load("res://assets/ui/settings/%s-normal.png" % prefix)
	style_hover.texture = load("res://assets/ui/settings/%s-hover.png" % prefix)
	style_pressed.texture = load("res://assets/ui/settings/%s-pressed.png" % prefix)
	
	for s in [style_normal, style_hover, style_pressed]:
		s.texture_margin_left = 4.0
		s.texture_margin_top = 4.0
		s.texture_margin_right = 4.0
		s.texture_margin_bottom = 4.0
		s.content_margin_left = 4.0
		s.content_margin_top = 4.0
		s.content_margin_right = 4.0
		s.content_margin_bottom = 4.0
		
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_hover)
