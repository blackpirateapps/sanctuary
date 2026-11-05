# scripts/player.gd
# Player controller with Dead-Cells-inspired responsiveness,
# animation state transitions, and dynamic lantern lighting.
extends CharacterBody2D

@export var speed: float = 140.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 650.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lantern_light: PointLight2D = $LanternLight

var is_attacking: bool = false
var is_defending: bool = false

func _ready() -> void:
	_setup_sprite_frames()
	sprite.play("idle")

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
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle attack input (J or left-click)
	if Input.is_action_just_pressed("player_attack") or Input.is_key_pressed(KEY_J):
		if not is_attacking:
			_trigger_attack()

	# Handle defend / meditate input (K or right-click)
	if Input.is_action_just_pressed("player_defend") or Input.is_key_pressed(KEY_K):
		if not is_defending and not is_attacking:
			_trigger_defend()

	# Handle jump (W or Up or Space)
	if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and is_on_floor():
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

	# Subtle breathing pulse on lantern light
	var time_now: float = Time.get_ticks_msec() / 1000.0
	lantern_light.energy = 0.85 + sin(time_now * 3.0) * 0.15

func _trigger_attack() -> void:
	is_attacking = true
	sprite.play("attack")
	await sprite.animation_finished
	is_attacking = false
	sprite.play("idle")

func _trigger_defend() -> void:
	is_defending = true
	sprite.play("defend")
	await sprite.animation_finished
	is_defending = false
	sprite.play("idle")
