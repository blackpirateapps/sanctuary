# scripts/player.gd
# Player controller with Dead-Cells-inspired responsiveness,
# animation state transitions, dynamic lantern lighting,
# combat hit detection, overhead health bar, and parry defense.
extends CharacterBody2D

signal health_changed(current: float, max_val: float)
signal player_died

@export var speed: float = 140.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 650.0
@export var max_health: float = 100.0
@export var attack_damage: float = 25.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lantern_light: PointLight2D = $LanternLight
@onready var health_bar: Node2D = get_node_or_null("HealthBar")

var current_health: float = 100.0
var is_attacking: bool = false
var is_defending: bool = false
var is_invulnerable: bool = false
var _is_dead: bool = false

var _footstep_timer: float = 0.0
const FOOTSTEP_CADENCE: float = 0.32

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_setup_sprite_frames()
	sprite.play("idle")
	
	if health_bar:
		health_bar.setup(max_health)

func _setup_sprite_frames() -> void:
	# Build SpriteFrames dynamically from the extracted frames
	var sf: SpriteFrames = SpriteFrames.new()
	
	# Helper to load frame sequence
	var add_anim = func(anim_name: String, folder: String, frame_count: int, fps: float, loop: bool):
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, fps)
		sf.set_animation_loop(anim_name, loop)
		for i in range(1, frame_count + 1):
			var file_num: String = "%02d" % i
			var path: String = "res://assets/characters/player/frames/%s/%s.png" % [folder, file_num]
			var tex: Texture2D = load(path)
			if tex:
				sf.add_frame(anim_name, tex)
				
	add_anim.call("idle", "Idle", 8, 8.0, true)
	add_anim.call("run", "Move", 8, 12.0, true)
	add_anim.call("attack", "Attack1", 6, 14.0, false)
	add_anim.call("defend", "Defend", 8, 10.0, false)
	
	sprite.sprite_frames = sf

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle attack input (J or left-click)
	if Input.is_action_just_pressed("player_attack") or Input.is_key_pressed(KEY_J):
		if not is_attacking and not is_defending:
			_trigger_attack()

	# Handle defend / meditate input (K or right-click)
	if Input.is_action_just_pressed("player_defend") or Input.is_key_pressed(KEY_K):
		if not is_defending and not is_attacking:
			_trigger_defend()

	# Handle jump (Space or W or Up)
	if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and is_on_floor():
		velocity.y = jump_velocity

	# Horizontal movement (A/D or Left/Right)
	var dir: float = 0.0
	if not is_attacking and not is_defending:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir += 1.0

	if dir != 0.0:
		velocity.x = dir * speed
		sprite.flip_h = dir < 0.0
		# Offset lantern slightly based on facing direction
		lantern_light.position.x = -8.0 if dir < 0.0 else 8.0
		if not is_attacking and not is_defending and sprite.animation != "run":
			sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		if not is_attacking and not is_defending and sprite.animation != "idle":
			sprite.play("idle")

	move_and_slide()

	_handle_footsteps(delta)

	# Subtle breathing pulse on lantern light
	var time_now: float = Time.get_ticks_msec() / 1000.0
	lantern_light.energy = 0.85 + sin(time_now * 3.0) * 0.15

func _trigger_attack() -> void:
	is_attacking = true
	sprite.play("attack")
	if AudioManager:
		AudioManager.play_sfx("wind_gust", Vector2(1.3, 1.5), -4.0)
	
	# Check melee hit detection halfway through attack swing
	await get_tree().create_timer(0.12).timeout
	if is_attacking and not _is_dead:
		_check_melee_hits()
		
	await sprite.animation_finished
	is_attacking = false
	if not _is_dead:
		sprite.play("idle")

func _check_melee_hits() -> void:
	var facing_dir: float = -1.0 if sprite.flip_h else 1.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var diff_x: float = enemy.global_position.x - global_position.x
			var dist: float = global_position.distance_to(enemy.global_position)
			# Enemy must be in front of player and within strike range
			if dist <= 55.0 and (signf(diff_x) == facing_dir or abs(diff_x) < 15.0):
				enemy.take_damage(attack_damage, global_position)

func _trigger_defend() -> void:
	is_defending = true
	sprite.play("defend")
	await sprite.animation_finished
	is_defending = false
	if not _is_dead:
		sprite.play("idle")

func take_damage(amount: float, from_pos: Vector2) -> void:
	if is_invulnerable or _is_dead:
		return
		
	var final_damage: float = amount
	if is_defending:
		# Parry / block reduces incoming damage by 75%
		final_damage = amount * 0.25
		if AudioManager:
			AudioManager.play_sfx("water_ripple", Vector2(1.6, 1.8), 2.0)
		var parry_tw = create_tween()
		sprite.modulate = Color(2.5, 2.2, 0.8, 1.0)
		parry_tw.tween_property(sprite, "modulate", Color.WHITE, 0.18)
	else:
		var hurt_tw = create_tween()
		sprite.modulate = Color(2.5, 0.3, 0.3, 1.0)
		hurt_tw.tween_property(sprite, "modulate", Color.WHITE, 0.22)
		
	current_health = maxf(0.0, current_health - final_damage)
	if health_bar:
		health_bar.update_health(current_health)
		
	health_changed.emit(current_health, max_health)
	
	# Knockback impulse
	var knock_dir: float = signf(global_position.x - from_pos.x)
	if knock_dir == 0.0:
		knock_dir = -1.0 if sprite.flip_h else 1.0
	velocity.x = knock_dir * 110.0
	velocity.y = -70.0
	
	_start_invulnerability(0.65)
	
	if current_health <= 0.0:
		_die()

func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	var blink_tw = create_tween().set_loops(int(duration / 0.12))
	blink_tw.tween_property(sprite, "modulate:a", 0.3, 0.06)
	blink_tw.tween_property(sprite, "modulate:a", 1.0, 0.06)
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
	sprite.modulate.a = 1.0

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	is_attacking = false
	is_defending = false
	velocity = Vector2.ZERO
	player_died.emit()

func respawn(spawn_pos: Vector2 = Vector2(120, 290)) -> void:
	_is_dead = false
	is_attacking = false
	is_defending = false
	is_invulnerable = false
	current_health = max_health
	global_position = spawn_pos
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	if health_bar:
		health_bar.update_health(current_health, false)
	sprite.play("idle")

func _handle_footsteps(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 10.0 and not is_attacking and not is_defending:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = FOOTSTEP_CADENCE
			_play_footstep()
	else:
		_footstep_timer = 0.08

func _determine_surface() -> String:
	var weather: String = HabitManager.selected_weather if HabitManager else "clear"
	if weather == "snow":
		return "snow"
	elif weather == "leaves":
		return "leaves"
	elif weather == "rain" or global_position.x >= 1100.0:
		return "puddle"
	return "grass"

func _play_footstep() -> void:
	var surface: String = _determine_surface()
	if AudioManager:
		AudioManager.play_footstep(surface)
