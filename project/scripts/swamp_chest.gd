# scripts/swamp_chest.gd
# Interactive ancient chest in the swamp awarding focus mana.
extends Node2D

signal chest_opened(reward: float)

@export var reward_mana: float = 35.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $PromptLabel
@onready var light: PointLight2D = $PointLight2D
@onready var particles: CPUParticles2D = $CPUParticles2D

var _is_opened: bool = false
var _player_nearby: bool = false

func _ready() -> void:
	prompt.visible = false
	$ProximityArea.body_entered.connect(_on_proximity_entered)
	$ProximityArea.body_exited.connect(_on_proximity_exited)

func _process(_delta: float) -> void:
	if not _is_opened and _player_nearby:
		if Input.is_key_pressed(KEY_E):
			open_chest()

func _on_proximity_entered(body: Node2D) -> void:
	if not _is_opened and (body is CharacterBody2D or body.name == "Player"):
		_player_nearby = true
		prompt.visible = true

func _on_proximity_exited(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player":
		_player_nearby = false
		prompt.visible = false

func open_chest() -> void:
	if _is_opened:
		return
	_is_opened = true
	prompt.visible = false
	HabitManager.add_mana(reward_mana)
	chest_opened.emit(reward_mana)
	
	# Animate chest opening sequence (4 frames)
	var tw = create_tween()
	tw.tween_property(sprite, "frame", 1, 0.08)
	tw.tween_property(sprite, "frame", 2, 0.08)
	tw.tween_property(sprite, "frame", 3, 0.1)
	
	# Light flare
	tw.parallel().tween_property(light, "energy", 2.2, 0.2).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(light, "color", Color(1.0, 0.85, 0.35, 1.0), 0.2)
	tw.tween_property(light, "energy", 1.2, 0.5)
	
	# Particle explosion
	particles.emitting = true
	
	# Floating notification text
	var label = Label.new()
	label.text = "+%d FOCUS MANA" % int(reward_mana)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("ffd166"))
	label.add_theme_font_size_override("font_size", 10)
	label.position = Vector2(-60, -45)
	add_child(label)
	
	var label_tw = create_tween()
	label_tw.tween_property(label, "position:y", -70.0, 0.7).set_trans(Tween.TRANS_QUAD)
	label_tw.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	label_tw.tween_callback(label.queue_free)
