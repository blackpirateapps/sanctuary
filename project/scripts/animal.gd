# scripts/animal.gd
# Modular animal controller supporting both static 32x32 sprites
# and multi-frame animated creatures. Features organic wandering,
# hopping, perching, reactive fleeing, and peaceful [E] petting interactions.
extends Node2D

enum MovementMode {
	IDLE_STATIONARY,
	GROUND_HOP,
	GROUND_WALK,
	PERCHED,
	FLY_HOVER
}

const ANIMAL_PRESETS: Dictionary = {
	"rabbit": {
		"display_name": "Forest Hare",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/rabbit.png",
		"speed": 22.0,
		"hop_h": 3.5,
		"hop_freq": 7.0,
		"can_flee": false,
		"flee_dist": 0.0,
		"can_pet": false,
		"is_background": true,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"deer": {
		"display_name": "Sanctuary Stag",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/deer.png",
		"speed": 18.0,
		"hop_h": 2.0,
		"hop_freq": 4.5,
		"can_flee": false,
		"flee_dist": 0.0,
		"can_pet": false,
		"is_background": true,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"doe": {
		"display_name": "Gentle Doe",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/doe.png",
		"speed": 16.0,
		"hop_h": 2.0,
		"hop_freq": 4.5,
		"can_flee": false,
		"flee_dist": 0.0,
		"can_pet": false,
		"is_background": true,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"sparrow": {
		"display_name": "Forest Songbird",
		"mode": MovementMode.PERCHED,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/sparrow.png",
		"speed": 0.0,
		"can_flee": true,
		"flee_dist": 45.0,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"owl": {
		"display_name": "Watcher Owl",
		"mode": MovementMode.PERCHED,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/owl.png",
		"speed": 0.0,
		"can_flee": false,
		"flee_dist": 40.0,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*The owl blinks sagely in approval (+2 Focus Mana)*",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"fox": {
		"display_name": "Amber Fox",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/fox.png",
		"speed": 28.0,
		"hop_h": 3.0,
		"hop_freq": 6.0,
		"can_flee": false,
		"flee_dist": 0.0,
		"can_pet": false,
		"is_background": true,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"frog": {
		"display_name": "Mire Frog",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/frog.png",
		"speed": 18.0,
		"hop_h": 2.5,
		"hop_freq": 5.0,
		"can_flee": true,
		"flee_dist": 40.0,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*The tiny frog lets out a cheerful croak (+2 Focus Mana)*",
		"offset": Vector2(0, -16),
		"scale": Vector2(0.6, 0.6)
	},
	"hedgehog": {
		"display_name": "Thorny Hedgehog",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/hedgehog.png",
		"speed": 14.0,
		"hop_h": 1.5,
		"hop_freq": 4.0,
		"can_flee": true,
		"flee_dist": 40.0,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*The hedgehog carefully uncurls to greet you (+2 Focus Mana)*",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"snail": {
		"display_name": "Moss Snail",
		"mode": MovementMode.GROUND_HOP,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/snail.png",
		"speed": 6.0,
		"hop_h": 0.5,
		"hop_freq": 2.0,
		"can_flee": false,
		"flee_dist": 30.0,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*A patient snail rests calmly (+2 Focus Mana)*",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"raven": {
		"display_name": "Void Raven",
		"mode": MovementMode.PERCHED,
		"is_animated": false,
		"texture": "res://assets/animals/tiny/raven.png",
		"speed": 0.0,
		"can_flee": true,
		"flee_dist": 40.0,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -16),
		"scale": Vector2.ONE
	},
	"bee": {
		"display_name": "Amber Honeybee",
		"mode": MovementMode.FLY_HOVER,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/bee/Bee_1.png",
			"res://assets/animals/cute/bee/Bee_2.png",
			"res://assets/animals/cute/bee/Bee_3.png"
		],
		"fps": 8.0,
		"speed": 22.0,
		"can_flee": false,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -20),
		"scale": Vector2(0.45, 0.45)
	},
	"dragonfly": {
		"display_name": "Emerald Dragonfly",
		"mode": MovementMode.FLY_HOVER,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/dragonfly/Dragonfly_1.png",
			"res://assets/animals/cute/dragonfly/Dragonfly_2.png",
			"res://assets/animals/cute/dragonfly/Dragonfly_3.png",
			"res://assets/animals/cute/dragonfly/Dragonfly_4.png"
		],
		"fps": 10.0,
		"speed": 28.0,
		"can_flee": false,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -24),
		"scale": Vector2(0.35, 0.35)
	},
	"bat": {
		"display_name": "Shadow Bat",
		"mode": MovementMode.FLY_HOVER,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/bat/Bat_1.png",
			"res://assets/animals/cute/bat/Bat_2.png",
			"res://assets/animals/cute/bat/Bat_3.png"
		],
		"fps": 7.0,
		"speed": 25.0,
		"can_flee": false,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -24),
		"scale": Vector2(0.55, 0.55)
	},
	"white_bat": {
		"display_name": "Spectral Bat",
		"mode": MovementMode.FLY_HOVER,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/white_bat/WhiteBat_1.png",
			"res://assets/animals/cute/white_bat/WhiteBat_2.png",
			"res://assets/animals/cute/white_bat/WhiteBat_3.png"
		],
		"fps": 7.0,
		"speed": 26.0,
		"can_flee": false,
		"can_pet": false,
		"is_background": false,
		"pet_msg": "",
		"offset": Vector2(0, -24),
		"scale": Vector2(0.55, 0.55)
	},
	"bear": {
		"display_name": "Guardian Bear",
		"mode": MovementMode.GROUND_WALK,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/bear/Bear_1.png",
			"res://assets/animals/cute/bear/Bear_2.png",
			"res://assets/animals/cute/bear/Bear_3.png"
		],
		"fps": 4.0,
		"speed": 20.0,
		"can_flee": false,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*The Ancient Guardian Bear rumbles with steadfast fortitude (+2 Focus Mana)*",
		"offset": Vector2(0, -28),
		"scale": Vector2(0.7, 0.7)
	},
	"baby_dragon": {
		"display_name": "Celestial Drake",
		"mode": MovementMode.FLY_HOVER,
		"is_animated": true,
		"frames": [
			"res://assets/animals/cute/baby_dragon/BabyDragon_1.png",
			"res://assets/animals/cute/baby_dragon/BabyDragon_2.png",
			"res://assets/animals/cute/baby_dragon/BabyDragon_3.png"
		],
		"fps": 6.0,
		"speed": 22.0,
		"can_flee": false,
		"can_pet": true,
		"is_background": false,
		"pet_msg": "*The Celestial Drake coils gently around you, honoring your mastery (+2 Focus Mana)*",
		"offset": Vector2(0, -30),
		"scale": Vector2(0.6, 0.6)
	}
}

@export var animal_id: String = ""
@export var display_name: String = ""
@export var movement_mode: MovementMode = MovementMode.GROUND_HOP
@export var is_animated_pack: bool = false
@export var is_background: bool = false
@export var base_scale: Vector2 = Vector2.ONE

# Textures / Frame paths
@export var static_texture: Texture2D
@export var animation_frames: Array[Texture2D] = []
@export var animation_fps: float = 5.0

# Wander / Patrol settings
@export var wander_min_x: float = 0.0
@export var wander_max_x: float = 0.0
@export var move_speed: float = 24.0
@export var hop_height: float = 3.5
@export var hop_frequency: float = 7.0

# Reactive behavior
@export var can_flee: bool = false
@export var flee_distance: float = 50.0
@export var flee_speed_mult: float = 2.2

# Interaction settings
@export var can_pet: bool = true
@export var pet_message: String = ""
@export var pet_cooldown_time: float = 15.0

# Habit Milestone Unlock (0 = always active, 1..6 = milestone tier required)
@export var unlock_tier: int = 0
@export var is_spirit: bool = false
@export var spirit_color: Color = Color(1.0, 0.88, 0.5, 1.0)

# Nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var love_particles: CPUParticles2D = $LoveParticles
@onready var spirit_light: PointLight2D = $SpiritLight

# Internal State
var _base_y: float = 0.0
var _perch_origin: Vector2 = Vector2.ZERO
var _target_x: float = 0.0
var _state_timer: float = 0.0
var _walk_cycle_t: float = 0.0
var _pet_cooldown: float = 0.0
var _is_fleeing: bool = false
var _flee_timer: float = 0.0
var _is_idling: bool = true
var _player: CharacterBody2D = null

func _ready() -> void:
	_apply_preset()
	
	_base_y = position.y
	_perch_origin = position
	_target_x = position.x
	
	if is_background:
		z_index = -1
		can_pet = false
		can_flee = false
	
	if wander_min_x == 0.0 and wander_max_x == 0.0:
		wander_min_x = position.x - 40.0
		wander_max_x = position.x + 40.0
		
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Apply configured base scale to visual nodes
	sprite.scale = base_scale
	anim_sprite.scale = base_scale
	
	# Setup visual representation
	if is_animated_pack and animation_frames.size() > 0:
		sprite.visible = false
		anim_sprite.visible = true
		_setup_animated_sprite()
	else:
		anim_sprite.visible = false
		sprite.visible = true
		if static_texture != null:
			sprite.texture = static_texture
			
	# Spirit visual rig
	if is_spirit:
		spirit_light.visible = true
		spirit_light.color = spirit_color
	else:
		spirit_light.visible = false
		
	# Cache player reference
	_player = get_tree().root.find_child("Player", true, false) as CharacterBody2D
	
	# Initial milestone check
	_check_milestone_active()
	
	# Connect to HabitManager streak changes if milestone locked
	if unlock_tier > 0:
		HabitManager.streak_updated.connect(func(_d, _h, _m, _s): _check_milestone_active())

func _apply_preset() -> void:
	if animal_id.is_empty() or not ANIMAL_PRESETS.has(animal_id):
		return
		
	var p: Dictionary = ANIMAL_PRESETS[animal_id]
	if display_name.is_empty():
		display_name = p.get("display_name", "Creature")
	if not p.is_empty():
		movement_mode = p.get("mode", movement_mode)
		is_animated_pack = p.get("is_animated", is_animated_pack)
		
		if p.has("scale"):
			base_scale = p["scale"]
		if p.has("is_background"):
			is_background = p["is_background"]
		if is_background:
			z_index = -1
			can_pet = false
			can_flee = false
			
		if p.has("speed"):
			move_speed = p["speed"]
		if p.has("hop_h"):
			hop_height = p["hop_h"]
		if p.has("hop_freq"):
			hop_frequency = p["hop_freq"]
		if p.has("can_flee"):
			can_flee = p["can_flee"]
		if p.has("flee_dist"):
			flee_distance = p["flee_dist"]
		if p.has("can_pet"):
			can_pet = p["can_pet"]
		if pet_message.is_empty() and p.has("pet_msg"):
			pet_message = p["pet_msg"]
			
		var offset: Vector2 = p.get("offset", Vector2(0, -16))
		$Sprite2D.position = offset
		$AnimatedSprite2D.position = offset
		$SpiritLight.position = offset + Vector2(0, 2)
		$LoveParticles.position = offset + Vector2(0, 2)
		$PromptLabel.position = Vector2(-75, offset.y - 22)
		$FeedbackLabel.position = Vector2(-140, offset.y - 34)
		
		if is_animated_pack:
			if animation_frames.size() == 0 and p.has("frames"):
				for path in p["frames"]:
					var tex = load(path) as Texture2D
					if tex != null:
						animation_frames.append(tex)
			if p.has("fps"):
				animation_fps = p["fps"]
		else:
			if static_texture == null and p.has("texture"):
				static_texture = load(p["texture"]) as Texture2D

func _setup_animated_sprite() -> void:
	var frames = SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", animation_fps)
	for tex in animation_frames:
		if tex != null:
			frames.add_frame("default", tex)
	anim_sprite.sprite_frames = frames
	anim_sprite.play("default")

func _check_milestone_active() -> void:
	if unlock_tier <= 0:
		visible = true
		return
		
	var current_tier_idx = HabitManager.get_current_tier_index()
	visible = (current_tier_idx >= unlock_tier)

func _process(delta: float) -> void:
	if not visible:
		return
		
	var t: float = Time.get_ticks_msec() / 1000.0
	
	# Update cooldowns
	if _pet_cooldown > 0.0:
		_pet_cooldown -= delta
		
	if _flee_timer > 0.0:
		_flee_timer -= delta
		if _flee_timer <= 0.0:
			_is_fleeing = false
			if movement_mode == MovementMode.PERCHED:
				var tw = create_tween()
				tw.tween_property(self, "position", _perch_origin, 0.8).set_trans(Tween.TRANS_QUAD)
				
	# Spirit light breathing oscillation
	if is_spirit and spirit_light.visible:
		spirit_light.energy = 0.85 + sin(t * 2.8) * 0.25
		
	# Check player distance for interactions & fleeing
	if _player != null:
		var dist_to_player: float = global_position.distance_to(_player.global_position)
		
		# Reactive flee trigger
		if can_flee and not _is_fleeing and dist_to_player < flee_distance:
			if abs(_player.velocity.x) > 50.0:
				_trigger_flee()
				
		# Petting interaction prompt
		var can_interact_now = can_pet and not _is_fleeing and _pet_cooldown <= 0.0 and dist_to_player < 36.0
		prompt_label.visible = can_interact_now
		if can_interact_now:
			if is_spirit:
				prompt_label.text = "[E] Commune with Spirit"
			else:
				prompt_label.text = "[E] Pet " + display_name
				
			if Input.is_key_pressed(KEY_E):
				_perform_pet()
	else:
		prompt_label.visible = false
		
	# Handle movement modes
	match movement_mode:
		MovementMode.IDLE_STATIONARY:
			_process_idle(delta, t)
		MovementMode.GROUND_HOP:
			_process_ground_hop(delta, t)
		MovementMode.GROUND_WALK:
			_process_ground_walk(delta, t)
		MovementMode.PERCHED:
			_process_perched(delta, t)
		MovementMode.FLY_HOVER:
			_process_fly_hover(delta, t)

func _process_idle(delta: float, t: float) -> void:
	var breath_y = base_scale.y * (1.0 + sin(t * 3.0) * 0.03)
	var active_node = anim_sprite if is_animated_pack else sprite
	active_node.scale.y = breath_y
	active_node.scale.x = base_scale.x
	
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state_timer = randf_range(3.0, 7.0)
		if randf() < 0.4:
			active_node.flip_h = not active_node.flip_h

func _process_ground_hop(delta: float, t: float) -> void:
	var active_node = anim_sprite if is_animated_pack else sprite
	
	if _is_fleeing:
		var flee_dir: float = sign(position.x - _player.position.x)
		if flee_dir == 0.0:
			flee_dir = 1.0
		position.x += flee_dir * move_speed * flee_speed_mult * delta
		position.x = clampf(position.x, wander_min_x - 30.0, wander_max_x + 30.0)
		# Default facing is LEFT, so moving right (flee_dir > 0) requires flip_h = true
		active_node.flip_h = (flee_dir > 0.0)
		
		# Rapid fleeing hops
		_walk_cycle_t += delta * hop_frequency * 1.5
		position.y = _base_y - abs(sin(_walk_cycle_t)) * (hop_height * 1.5)
		return
		
	if _is_idling:
		_process_idle(delta, t)
		position.y = _base_y
		_state_timer -= delta
		if _state_timer <= 0.0:
			_is_idling = false
			_target_x = randf_range(wander_min_x, wander_max_x)
			_state_timer = randf_range(2.0, 5.0)
	else:
		var dir: float = sign(_target_x - position.x)
		if abs(_target_x - position.x) < 2.0 or _state_timer <= 0.0:
			_is_idling = true
			_state_timer = randf_range(2.0, 6.0)
			position.y = _base_y
			active_node.scale = base_scale
		else:
			_state_timer -= delta
			position.x += dir * move_speed * delta
			# Default facing is LEFT, so moving right (dir > 0) requires flip_h = true
			active_node.flip_h = (dir > 0.0)
			
			_walk_cycle_t += delta * hop_frequency
			position.y = _base_y - abs(sin(_walk_cycle_t)) * hop_height

func _process_ground_walk(delta: float, t: float) -> void:
	var active_node = anim_sprite if is_animated_pack else sprite
	
	if _is_idling:
		_process_idle(delta, t)
		position.y = _base_y
		if is_animated_pack and anim_sprite.is_playing():
			anim_sprite.frame = 0
			anim_sprite.pause()
		_state_timer -= delta
		if _state_timer <= 0.0:
			_is_idling = false
			_target_x = randf_range(wander_min_x, wander_max_x)
			_state_timer = randf_range(3.0, 7.0)
			if is_animated_pack:
				anim_sprite.play("default")
	else:
		var dir: float = sign(_target_x - position.x)
		if abs(_target_x - position.x) < 2.0 or _state_timer <= 0.0:
			_is_idling = true
			_state_timer = randf_range(2.0, 5.0)
		else:
			_state_timer -= delta
			position.x += dir * move_speed * delta
			# Default facing is LEFT, so moving right (dir > 0) requires flip_h = true
			active_node.flip_h = (dir > 0.0)
			if is_animated_pack and not anim_sprite.is_playing():
				anim_sprite.play("default")

func _process_perched(delta: float, t: float) -> void:
	var active_node = anim_sprite if is_animated_pack else sprite
	
	if not _is_fleeing:
		var breath_y = base_scale.y * (1.0 + sin(t * 2.5) * 0.03)
		active_node.scale.y = breath_y
		active_node.scale.x = base_scale.x
		
		_state_timer -= delta
		if _state_timer <= 0.0:
			_state_timer = randf_range(2.5, 6.0)
			if randf() < 0.5:
				active_node.flip_h = not active_node.flip_h
				
			if randf() < 0.35:
				var tw = create_tween()
				tw.tween_property(self, "position:y", _perch_origin.y - 3.0, 0.12).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(self, "position:y", _perch_origin.y, 0.12).set_trans(Tween.TRANS_BOUNCE)

func _process_fly_hover(delta: float, t: float) -> void:
	var active_node = anim_sprite if is_animated_pack else sprite
	
	if abs(_target_x - position.x) < 3.0 or _state_timer <= 0.0:
		_target_x = randf_range(wander_min_x, wander_max_x)
		_state_timer = randf_range(3.0, 8.0)
		
	var dir: float = sign(_target_x - position.x)
	position.x += dir * move_speed * 0.65 * delta
	# Default facing is LEFT, so moving right (dir > 0) requires flip_h = true
	active_node.flip_h = (dir > 0.0)
	
	position.y = _base_y + sin(t * 3.5 + position.x * 0.05) * 4.0

func _trigger_flee() -> void:
	_is_fleeing = true
	_flee_timer = 2.5
	prompt_label.visible = false
	
	if movement_mode == MovementMode.PERCHED:
		var tw = create_tween()
		var flee_offset_x = 20.0 if randf() > 0.5 else -20.0
		tw.tween_property(self, "position", _perch_origin + Vector2(flee_offset_x, -35.0), 0.4).set_trans(Tween.TRANS_QUAD)
	elif movement_mode == MovementMode.GROUND_HOP or movement_mode == MovementMode.GROUND_WALK:
		_is_idling = false

func _perform_pet() -> void:
	if not can_pet or is_background:
		return
		
	_pet_cooldown = pet_cooldown_time
	prompt_label.visible = false
	
	love_particles.restart()
	love_particles.emitting = true
	
	var tw = create_tween()
	tw.tween_property(self, "position:y", position.y - 6.0, 0.15).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:y", position.y, 0.2).set_trans(Tween.TRANS_BOUNCE)
	
	HabitManager.add_mana(2.0)
	
	feedback_label.text = pet_message
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	
	var label_tw = create_tween()
	label_tw.tween_interval(2.2)
	label_tw.tween_property(feedback_label, "modulate:a", 0.0, 0.5)
	label_tw.tween_callback(func(): feedback_label.visible = false)
