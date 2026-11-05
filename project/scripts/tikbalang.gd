# scripts/tikbalang.gd
# Mythical Tikbalang forest guardian / boss enemy.
# Features multi-animation AI (idle, walk, run, dash, kick combo),
# overhead health bar, dynamic melee combat, and defeat rewards.
extends CharacterBody2D

signal defeated(position: Vector2)

@export var max_health: float = 150.0
@export var walk_speed: float = 45.0
@export var run_speed: float = 80.0
@export var dash_speed: float = 175.0
@export var detection_radius: float = 240.0
@export var melee_range: float = 60.0
@export var attack_damage: float = 14.0 # Damage per kick strike
@export var gravity: float = 650.0

enum State {
	IDLE,
	WALK,
	RUN,
	DASH,
	ATTACK,
	HURT,
	DEAD
}

var current_state: State = State.IDLE
var current_health: float = 150.0
var spawn_position: Vector2 = Vector2.ZERO

var _target_player: CharacterBody2D = null
var _attack_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_timer: float = 0.0
var _last_hit_frame: int = -1
var _is_facing_left: bool = false

# Kick strike frame indices within the 100-frame kick combo sequence
const KICK_FRAMES: Array[int] = [4, 14, 42, 52, 62, 72, 83, 93]

# Shared SpriteFrames resource across all Tikbalang instances
static var _shared_sprite_frames: SpriteFrames = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: Node2D = $HealthBar
@onready var aura_light: PointLight2D = $AuraLight
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	current_health = max_health
	_setup_sprite_frames()
	
	if health_bar:
		health_bar.setup(max_health)
	
	sprite.play("idle")
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target_player = players[0]

func _setup_sprite_frames() -> void:
	if _shared_sprite_frames == null:
		var sf: SpriteFrames = SpriteFrames.new()
		var add_anim = func(anim_name: String, folder: String, frame_count: int, fps: float, loop: bool):
			sf.add_animation(anim_name)
			sf.set_animation_speed(anim_name, fps)
			sf.set_animation_loop(anim_name, loop)
			for i in range(1, frame_count + 1):
				var file_num: String = "%02d" % i
				var path: String = "res://assets/characters/enemies/tikbalang/frames/%s/%s.png" % [folder, file_num]
				var tex: Texture2D = load(path)
				if tex:
					sf.add_frame(anim_name, tex)
		
		add_anim.call("idle", "idle", 42, 14.0, true)
		add_anim.call("walk", "walk", 32, 16.0, true)
		add_anim.call("run", "run", 28, 18.0, true)
		add_anim.call("dash", "dash", 12, 18.0, false)
		add_anim.call("attack", "attack", 100, 25.0, false)
		
		_shared_sprite_frames = sf
	
	sprite.sprite_frames = _shared_sprite_frames

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Timers
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
		
	# Locate player if needed
	if not _target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target_player = players[0]
			
	if not _target_player:
		move_and_slide()
		return
		
	var dist_x: float = _target_player.global_position.x - global_position.x
	var dist_total: float = global_position.distance_to(_target_player.global_position)
	
	# Determine facing direction
	if abs(dist_x) > 5.0 and current_state != State.ATTACK and current_state != State.DASH:
		_is_facing_left = (dist_x < 0.0)
		sprite.flip_h = _is_facing_left
	
	# State Machine Logic
	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if sprite.animation != "idle":
				sprite.play("idle")
				
			if dist_total <= detection_radius:
				if dist_total <= melee_range and _attack_cooldown <= 0.0:
					_start_attack()
				else:
					current_state = State.RUN
					
		State.RUN, State.WALK:
			if dist_total <= melee_range and _attack_cooldown <= 0.0:
				_start_attack()
			elif dist_total > detection_radius * 1.4:
				# Player fled beyond engagement range
				current_state = State.IDLE
				sprite.play("idle")
			else:
				# Trigger dash if gap is medium-far and off cooldown
				if dist_total > 110.0 and dist_total <= 220.0 and _dash_cooldown <= 0.0:
					_start_dash(signf(dist_x))
				else:
					var speed_to_use: float = run_speed if dist_total > 90.0 else walk_speed
					velocity.x = signf(dist_x) * speed_to_use
					var desired_anim: String = "run" if dist_total > 90.0 else "walk"
					if sprite.animation != desired_anim:
						sprite.play(desired_anim)
						
		State.DASH:
			_dash_timer -= delta
			if _dash_timer <= 0.0:
				current_state = State.RUN
			else:
				if dist_total <= melee_range and _attack_cooldown <= 0.0:
					_start_attack()
					
		State.ATTACK:
			# Decelerate during kick combo
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
	
	move_and_slide()
	
	# Subtle eerie violet breathing pulse on aura light
	var t: float = Time.get_ticks_msec() / 1000.0
	aura_light.energy = 0.9 + sin(t * 2.2) * 0.25

func _start_dash(dir: float) -> void:
	current_state = State.DASH
	_dash_timer = 0.42
	_dash_cooldown = 4.5
	velocity.x = dir * dash_speed
	sprite.play("dash")
	if AudioManager:
		AudioManager.play_sfx("wind_gust", Vector2(1.2, 1.4), -4.0)

func _start_attack() -> void:
	current_state = State.ATTACK
	_attack_cooldown = 2.2
	_last_hit_frame = -1
	velocity.x = 0.0
	sprite.play("attack")
	if AudioManager:
		AudioManager.play_sfx("wind_gust", Vector2(0.9, 1.1), -2.0)

func _on_frame_changed() -> void:
	if current_state != State.ATTACK or sprite.animation != "attack":
		return
		
	var f: int = sprite.frame
	if f in KICK_FRAMES and f != _last_hit_frame:
		_last_hit_frame = f
		_check_kick_impact()

func _check_kick_impact() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		return
		
	var dist: float = global_position.distance_to(_target_player.global_position)
	var x_diff: float = _target_player.global_position.x - global_position.x
	var in_front: bool = (_is_facing_left and x_diff < 15.0) or (not _is_facing_left and x_diff > -15.0)
	
	if dist <= (melee_range + 22.0) and in_front:
		if _target_player.has_method("take_damage"):
			_target_player.take_damage(attack_damage, global_position)
		if AudioManager:
			AudioManager.play_sfx("thunder_close", Vector2(1.4, 1.6), -12.0)

func _on_animation_finished() -> void:
	if current_state == State.ATTACK or current_state == State.DASH:
		current_state = State.IDLE
		sprite.play("idle")

func take_damage(amount: float, from_pos: Vector2) -> void:
	if current_state == State.DEAD:
		return
		
	current_health = maxf(0.0, current_health - amount)
	if health_bar:
		health_bar.update_health(current_health)
		
	# White-red hurt flash
	var orig_color: Color = sprite.modulate
	sprite.modulate = Color(2.5, 0.4, 0.4, 1.0)
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Audio impact
	if AudioManager:
		AudioManager.play_sfx("thunder_close", Vector2(1.5, 1.8), -8.0)
		
	# Knockback impulse
	var knock_dir: float = signf(global_position.x - from_pos.x)
	if knock_dir == 0.0:
		knock_dir = 1.0
	velocity.x = knock_dir * 90.0
	
	if current_health <= 0.0:
		_die()
	else:
		if current_state == State.IDLE:
			current_state = State.RUN

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	
	# Award +100 Coins to player
	HabitManager.add_mana(100.0)
	
	# Trigger sound
	if AudioManager:
		AudioManager.play_sfx("water_ripple", Vector2(1.5, 1.7), 2.0)
		
	defeated.emit(global_position)
	
	# Death tween: expand light, flash white, fade to alpha 0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(aura_light, "energy", 3.0, 0.3)
	tw.chain().tween_property(aura_light, "energy", 0.0, 0.9)
	
	await tw.finished
	queue_free()

func reset_to_spawn() -> void:
	current_health = max_health
	current_state = State.IDLE
	global_position = spawn_position
	velocity = Vector2.ZERO
	_attack_cooldown = 1.0
	_dash_cooldown = 0.0
	collision_shape.set_deferred("disabled", false)
	sprite.modulate = Color.WHITE
	sprite.play("idle")
	if health_bar:
		health_bar.update_health(current_health, false)
