# scripts/slip_modal.gd
# Non-judgmental accountability dialog with shield resilience.
extends CanvasLayer

signal slip_recorded(shielded: bool)

@onready var desc_label: Label = $Modal/Panel/Content/Description
@onready var confirm_button: Button = $Modal/Panel/Content/ButtonBox/ConfirmButton
@onready var cancel_button: Button = $Modal/Panel/Content/ButtonBox/CancelButton

func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)

func open() -> void:
	visible = true
	if HabitManager.shields > 0:
		desc_label.text = "You have %d Aegis Shield(s) available.\n\nYour shield will absorb this setback. Your clean streak will NOT be wiped out to zero. A brief Blight Storm will pass through the outer valley, but your sanctuary core remains intact.\n\nTreat this as feedback, not defeat." % HabitManager.shields
	else:
		desc_label.text = "You currently have no shields remaining.\n\nYour active streak timer will reset, but your awakened shrines and historical record remain. You will immediately be granted 1 fresh shield to support your new foundation.\n\nRise and begin anew."

func _on_confirm() -> void:
	visible = false
	var shielded: bool = HabitManager.record_relapse()
	slip_recorded.emit(shielded)

func _on_cancel() -> void:
	visible = false
