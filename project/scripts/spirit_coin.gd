# scripts/spirit_coin.gd
# Collectible spirit coin floating in elevated swamp perches.
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

@export var mana_value: float = 5.0

var _is_collected: bool = false
var _base_y: float = 0.0
var _anim_offset: float = 0.0

func _ready() -> void:
	_base_y = position.y
	_anim_offset = randf() * 10.0
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _is_collected:
		return
	var t: float = Time.get_ticks_msec() / 1000.0 + _anim_offset
	# 4 frames of 10x10 spinning coin
	sprite.frame = int(t * 8.0) % 4
	# Gentle hover bobbing
	position.y = _base_y + sin(t * 3.5) * 3.0
	light.energy = 0.8 + sin(t * 5.0) * 0.2

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body is CharacterBody2D or body.name == "Player":
		_is_collected = true
		set_deferred("monitoring", false)
		HabitManager.add_mana(mana_value)
		_play_collect_effects()

func _play_collect_effects() -> void:
	# Create floating feedback text
	var label = Label.new()
	label.text = "+%d FOCUS" % int(mana_value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("ffe066"))
	label.add_theme_font_size_override("font_size", 9)
	label.position = Vector2(-25, -20)
	add_child(label)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tw.tween_property(light, "energy", 2.0, 0.1)
	tw.chain().tween_property(light, "energy", 0.0, 0.15)
	tw.tween_property(label, "position:y", -36.0, 0.4).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(queue_free)
