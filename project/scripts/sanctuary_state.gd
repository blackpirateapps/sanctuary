# scripts/sanctuary_state.gd
# Autoload singleton managing sanctuary corruption levels,
# unlocked milestones, and visual environmental state.
extends Node

signal corruption_changed(percentage: float)
signal milestone_unlocked(milestone_id: String, title: String)

# Milestones based on clean days
const MILESTONES: Array[Dictionary] = [
	{"id": "sprout", "days": 0.04, "title": "First Sprout", "desc": "Life stirs in the ashen soil."}, # ~1 hour for quick test
	{"id": "springs", "days": 1.0, "title": "Crystal Springs", "desc": "Clean water flows again."},
	{"id": "shrine", "days": 3.0, "title": "Guardian Altar", "desc": "The ancient stone hearth awakens."},
	{"id": "grove", "days": 7.0, "title": "Sacred Grove", "desc": "Canopy spreads, spirits return."},
	{"id": "monument", "days": 14.0, "title": "Ethereal Citadel", "desc": "Corrupt blight banished from the valley."},
	{"id": "transcendence", "days": 30.0, "title": "Eternal Sanctuary", "desc": "Mastery of self and spirit."}
]

var unlocked_milestones: Array[String] = []
var corruption_percent: float = 85.0 # Starts heavily corrupted

func _ready() -> void:
	# Recalculate corruption whenever streak updates
	HabitManager.streak_updated.connect(_on_streak_updated)
	HabitManager.relapse_handled.connect(_on_relapse_handled)

func _on_streak_updated(days: float, _hours: int, _mins: int, _secs: int) -> void:
	# Calculate target corruption: decreases with days
	# 0 days = ~85% corrupted, 14 days = ~10% corrupted, 30 days = 0%
	var target_corruption: float = clampf(85.0 - (days * 2.8), 0.0, 100.0)
	if abs(corruption_percent - target_corruption) > 0.05:
		corruption_percent = lerpf(corruption_percent, target_corruption, 0.05)
		corruption_changed.emit(corruption_percent)
		
	# Check for milestone unlocks
	for m in MILESTONES:
		if days >= m["days"] and not unlocked_milestones.has(m["id"]):
			unlocked_milestones.append(m["id"])
			milestone_unlocked.emit(m["id"], m["title"])

func _on_relapse_handled(was_shielded: bool) -> void:
	if was_shielded:
		# Minor blight increase (soft setback)
		corruption_percent = clampf(corruption_percent + 10.0, 0.0, 100.0)
	else:
		# Blight surge
		corruption_percent = clampf(corruption_percent + 35.0, 0.0, 100.0)
	corruption_changed.emit(corruption_percent)

# Helper to determine current ambient light color based on corruption
func get_ambient_color() -> Color:
	# 100% corrupted = deep necrotic purple
	# 0% corrupted = warm radiant dawn gold/emerald
	var corrupted_color: Color = Color("1e122b")
	var restored_color: Color = Color("385e4c")
	var t: float = 1.0 - (corruption_percent / 100.0)
	return corrupted_color.lerp(restored_color, t)
