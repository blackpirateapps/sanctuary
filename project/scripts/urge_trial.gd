# scripts/urge_trial.gd
# The Urge Interceptor: A two-stage interactive focus trial
# designed to replace craving dopamine with gameplay engagement
# followed by somatic physiological regulation.
extends CanvasLayer

signal trial_finished(success: bool)

@onready var title_label: Label = $Modal/Content/Title
@onready var subtitle_label: Label = $Modal/Content/Subtitle
@onready var timer_label: Label = $Modal/Content/TimerLabel
@onready var orbs_container: Control = $Modal/OrbsContainer
@onready var breathing_circle: Control = $Modal/BreathingCircle
@onready var breathing_label: Label = $Modal/BreathingCircle/BreathLabel
@onready var wizard_sprite: Sprite2D = $Modal/WizardSprite
@onready var action_button: Button = $Modal/Content/ActionButton

enum TrialPhase { INACTIVE, COMBAT_FOCUS, SOMATIC_BREATHING, VICTORY }
var current_phase: TrialPhase = TrialPhase.INACTIVE

var trial_timer: float = 30.0
var breath_timer: float = 0.0
var orbs_destroyed: int = 0
var target_orbs: int = 12
var spawn_cooldown: float = 0.0

var _rune_texture: Texture2D
var _impact_texture: Texture2D

func _ready() -> void:
	visible = false
	action_button.pressed.connect(_on_action_button_pressed)
	_rune_texture = load("res://assets/vfx/magic_particles/rune_circle_arcane_01.png")
	_impact_texture = load("res://assets/vfx/magic_particles/impact_star_arcane_01.png")

func start_trial() -> void:
	visible = true
	trial_timer = 20.0
	orbs_destroyed = 0
	current_phase = TrialPhase.COMBAT_FOCUS
	title_label.text = "SANCTUARY UNDER SIEGE"
	subtitle_label.text = "Strike down the void runes! Focus your intent."
	breathing_circle.visible = false
	wizard_sprite.visible = true
	action_button.text = "Yield Trial"
	
	# Clear existing orbs
	for child in orbs_container.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if not visible or current_phase == TrialPhase.INACTIVE:
		return
		
	if current_phase == TrialPhase.COMBAT_FOCUS:
		_process_combat_phase(delta)
	elif current_phase == TrialPhase.SOMATIC_BREATHING:
		_process_breathing_phase(delta)

func _process_combat_phase(delta: float) -> void:
	trial_timer -= delta
	timer_label.text = "Time: %0.1fs | Void Runes Cleansed: %d/%d" % [max(0.0, trial_timer), orbs_destroyed, target_orbs]
	
	# Animate wizard channeling
	var anim_frame: int = int((Time.get_ticks_msec() / 120.0)) % 8
	wizard_sprite.frame = anim_frame
	
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		_spawn_shadow_node()
		spawn_cooldown = randf_range(0.5, 0.9)
		
	if orbs_destroyed >= target_orbs or trial_timer <= 0.0:
		_transition_to_breathing()

func _spawn_shadow_node() -> void:
	var btn: TextureButton = TextureButton.new()
	btn.texture_normal = _rune_texture
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(44, 44)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.pivot_offset = Vector2(22, 22)
	btn.modulate = Color("e07dff")
	
	# Random position within play area
	var area_size: Vector2 = orbs_container.size
	var x: float = randf_range(20.0, max(30.0, area_size.x - 50.0))
	var y: float = randf_range(20.0, max(30.0, area_size.y - 50.0))
	btn.position = Vector2(x, y)
	
	# Pulse animation
	var pulse_tw = btn.create_tween().set_loops()
	pulse_tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
	pulse_tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.4).set_trans(Tween.TRANS_SINE)
	
	btn.pressed.connect(func():
		orbs_destroyed += 1
		pulse_tw.kill()
		# Change to impact starburst
		btn.texture_normal = _impact_texture
		btn.modulate = Color(2.0, 1.5, 2.5, 1.0) # Flash bright
		var pop_tw = btn.create_tween()
		pop_tw.tween_property(btn, "scale", Vector2(1.8, 1.8), 0.15)
		pop_tw.parallel().tween_property(btn, "modulate:a", 0.0, 0.15)
		pop_tw.tween_callback(btn.queue_free)
	)
	
	orbs_container.add_child(btn)
	
	# Auto vanish if not clicked in 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(btn):
			btn.queue_free()
	)

func _transition_to_breathing() -> void:
	current_phase = TrialPhase.SOMATIC_BREATHING
	title_label.text = "RESTORE EQUILIBRIUM"
	subtitle_label.text = "The wave has crested. Follow the light and breathe."
	timer_label.text = "Somatic Recalibration (Box Breathing)"
	wizard_sprite.visible = false
	breathing_circle.visible = true
	breath_timer = 16.0 # 4 cycles of 4s
	action_button.text = "Complete Integration"

func _process_breathing_phase(delta: float) -> void:
	breath_timer -= delta
	var cycle: float = fmod(16.0 - breath_timer, 8.0)
	var scale_factor: float
	
	if cycle < 4.0:
		# Inhale
		scale_factor = lerpf(0.6, 1.4, cycle / 4.0)
		breathing_label.text = "Breathe in deeply..."
	else:
		# Exhale
		scale_factor = lerpf(1.4, 0.6, (cycle - 4.0) / 4.0)
		breathing_label.text = "Slowly exhale and let go..."
		
	breathing_circle.scale = Vector2(scale_factor, scale_factor)
	
	if breath_timer <= 0.0:
		_complete_victory()

func _complete_victory() -> void:
	current_phase = TrialPhase.VICTORY
	title_label.text = "SANCTUARY SECURED"
	subtitle_label.text = "You resisted the temptation and transformed it into Focus Mana."
	timer_label.text = "+50 Focus Mana Awarded"
	breathing_circle.visible = false
	action_button.text = "Return to Sanctuary"
	HabitManager.complete_urge_trial(50)

func _on_action_button_pressed() -> void:
	if current_phase == TrialPhase.VICTORY or current_phase == TrialPhase.SOMATIC_BREATHING:
		visible = false
		current_phase = TrialPhase.INACTIVE
		trial_finished.emit(true)
	elif current_phase == TrialPhase.COMBAT_FOCUS:
		# Yielded
		visible = false
		current_phase = TrialPhase.INACTIVE
		trial_finished.emit(false)
