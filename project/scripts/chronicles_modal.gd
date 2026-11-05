# scripts/chronicles_modal.gd
# Reflection and milestone progress log.
extends CanvasLayer

@onready var record_label: Label = $Modal/Panel/Content/Stats/RecordValue
@onready var trials_label: Label = $Modal/Panel/Content/Stats/TrialsValue
@onready var milestone_list: VBoxContainer = $Modal/Panel/Content/ScrollContainer/MilestoneList
@onready var close_button: Button = $Modal/Panel/Content/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)

func open() -> void:
	visible = true
	record_label.text = "Record Streak: %0.1f days" % HabitManager.total_clean_days_record
	trials_label.text = "Urges Repelled: %d" % HabitManager.successful_trials
	
	for child in milestone_list.get_children():
		child.queue_free()
		
	var current_days: float = HabitManager.get_clean_days()
	for m in SanctuaryState.MILESTONES:
		var unlocked: bool = current_days >= m["days"]
		var row: HBoxContainer = HBoxContainer.new()
		var tag: Label = Label.new()
		tag.text = "[ACTIVE]" if unlocked else "[LOCKED]"
		tag.add_theme_font_size_override("font_size", 9)
		tag.add_theme_color_override("font_color", Color("94ffd1") if unlocked else Color("79748f"))
		
		var desc: Label = Label.new()
		desc.text = " %s (%s) - %s" % [m["title"], _format_milestone_time(m["days"]), m["desc"]]
		desc.add_theme_font_size_override("font_size", 9)
		if unlocked:
			desc.add_theme_color_override("font_color", Color("ffffff"))
		else:
			desc.add_theme_color_override("font_color", Color("79748f"))
		row.add_child(tag)
		row.add_child(desc)
		milestone_list.add_child(row)

func _format_milestone_time(days: float) -> String:
	if days < 1.0:
		return "%dh" % int(days * 24.0)
	return "%dd" % int(days)
