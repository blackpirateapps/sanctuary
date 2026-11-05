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
var target_orbs: int = 15
var spawn_cooldown: float = 0.0

func _ready() -> void:
	visible = false
	action_button.pressed.connect(_on_action_button_pressed)

func start_trial() -> void:
	visible = true
	trial_timer = 25.0
	orbs_destroyed = 0
	current_phase = TrialPhase.COMBAT_FOCUS
	title_label.text = "⚔️ SANCTUARY UNDER SIEGE"
	subtitle_label.text = "Strike down the shadow incursions! Focus your intent."
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
	timer_label.text = "Time Remaining: %0.1fs | Shadow Nodes Purified: %d/%d" % [max(0.0, trial_timer), orbs_destroyed, target_orbs]
	
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		_spawn_shadow_node()
		spawn_cooldown = randf_range(0.6, 1.1)
		
	if orbs_destroyed >= target_orbs or trial_timer <= 0.0:
		_transition_to_breathing()

func _spawn_shadow_node() -> void:
	var btn: Button = Button.new()
	btn.text = "✦"
	btn.custom_minimum_size = Vector2(36, 36)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("f18eff"))
	
	# Random position within play area
	var area_size: Vector2 = orbs_container.size
	var x: float = randf_range(30.0, max(40.0, area_size.x - 50.0))
	var y: float = randf_range(30.0, max(40.0, area_size.y - 50.0))
	btn.position = Vector2(x, y)
	
	btn.pressed.connect(func():
		orbs_destroyed += 1
		# Pop animation
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.5, 1.5), 0.1)
		tw.tween_property(btn, "modulate:a", 0.0, 0.1)
		tw.tween_callback(btn.queue_free)
	)
	
	orbs_container.add_child(btn)
	
	# Auto vanish if not clicked in 3 seconds
	get_tree().create_timer(2.8).timeout.connect(func():
		if is_instance_valid(btn):
			btn.queue_free()
	)

func _transition_to_breathing() -> void:
	current_phase = TrialPhase.SOMATIC_BREATHING
	title_label.text = "🌬️ RESTORE EQUILIBRIUM"
	subtitle_label.text = "The wave has crested. Follow the light and breathe."
	timer_label.text = "Somatic Recalibration"
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
	title_label.text = "✨ SANCTUARY SECURED"
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
