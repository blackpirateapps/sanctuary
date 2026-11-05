# scripts/health_bar.gd
# Overhead pixel-art health bar displaying discrete stages
# from the Starter Pack HP-Bar-Sprite set with smooth impact tweening.
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const TEX_100: Texture2D = preload("res://assets/ui/hp_bar/hp_100.png")
const TEX_75: Texture2D = preload("res://assets/ui/hp_bar/hp_75.png")
const TEX_65: Texture2D = preload("res://assets/ui/hp_bar/hp_65.png")
const TEX_50: Texture2D = preload("res://assets/ui/hp_bar/hp_50.png")
const TEX_35: Texture2D = preload("res://assets/ui/hp_bar/hp_35.png")
const TEX_10: Texture2D = preload("res://assets/ui/hp_bar/hp_10.png")
const TEX_0: Texture2D = preload("res://assets/ui/hp_bar/hp_0.png")

var max_hp: float = 100.0
var current_hp: float = 100.0

var _impact_tween: Tween

func _ready() -> void:
	_update_texture()

func setup(max_val: float) -> void:
	max_hp = maxf(1.0, max_val)
	current_hp = max_hp
	_update_texture()

func update_health(new_hp: float, play_impact: bool = true) -> void:
	var old_hp: float = current_hp
	current_hp = clampf(new_hp, 0.0, max_hp)
	_update_texture()
	
	if play_impact and current_hp < old_hp:
		_play_damage_feedback()

func _update_texture() -> void:
	if not sprite:
		return
	var pct: float = (current_hp / max_hp) * 100.0
	if pct >= 95.0:
		sprite.texture = TEX_100
	elif pct >= 70.0:
		sprite.texture = TEX_75
	elif pct >= 57.0:
		sprite.texture = TEX_65
	elif pct >= 42.0:
		sprite.texture = TEX_50
	elif pct >= 22.0:
		sprite.texture = TEX_35
	elif pct > 0.0:
		sprite.texture = TEX_10
	else:
		sprite.texture = TEX_0

func _play_damage_feedback() -> void:
	if _impact_tween and _impact_tween.is_valid():
		_impact_tween.kill()
	
	_impact_tween = create_tween()
	sprite.modulate = Color(2.0, 0.4, 0.4, 1.0)
	_impact_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_SINE)
