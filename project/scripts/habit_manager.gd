# scripts/habit_manager.gd
# Autoload singleton handling habit tracking, offline elapsed time,
# grace shields, and local persistence across Web and Desktop.
extends Node

signal streak_updated(days: float, hours: int, minutes: int, seconds: int)
signal shield_changed(current_shields: int)
signal mana_changed(current_mana: float)
signal relapse_handled(was_shielded: bool)
signal trial_rewarded(focus_crystals: int)
signal weather_changed(weather_id: String)

const SAVE_KEY: String = "sanctuary_habit_save_v1"
const LOCAL_FILE: String = "user://habit_save.json"

const SECONDS_PER_DAY: float = 86400.0
const SECONDS_PER_HOUR: float = 3600.0
const BASE_MANA_PER_HOUR: float = 10.0 # Base focus mana/coins earned per clean hour in Tier 1
const MANA_PER_HOUR: float = BASE_MANA_PER_HOUR # Backward compatibility alias

# Option B: Tiered Milestone Multipliers
# Accelerates coin generation as clean streak increases
const COIN_TIERS: Array[Dictionary] = [
	{"hours": 0.0, "mult": 1.0, "name": "Ember Foundation"},
	{"hours": 1.0, "mult": 1.5, "name": "First Sprout"},
	{"hours": 6.0, "mult": 2.5, "name": "Crystal Stream"},
	{"hours": 24.0, "mult": 4.0, "name": "Ancient Hearth"},
	{"hours": 72.0, "mult": 5.0, "name": "Grove Sanctuary"},
	{"hours": 168.0, "mult": 6.0, "name": "Eternal Citadel"}
]

const AUTOSAVE_INTERVAL: float = 15.0 # Periodic save to preserve continuous accumulation
var _autosave_timer: float = 0.0

# Habit state
var start_epoch: int = 0
var last_checkin_epoch: int = 0
var shields: int = 1 # Starts with 1 grace shield
var max_shields: int = 3
var focus_mana: float = 0.0
var successful_trials: int = 0
var total_clean_days_record: float = 0.0
var selected_weather: String = "clear"

# Audio state
var audio_muted: bool = false
var master_volume_step: int = 4
var ambience_volume_step: int = 3
var sfx_volume_step: int = 4

var _is_web: bool = false

func _ready() -> void:
	_is_web = OS.has_feature("web")
	load_data()
	
	# If brand new game, initialize start epoch to now
	var now: int = int(Time.get_unix_time_from_system())
	if start_epoch == 0:
		start_epoch = now
		last_checkin_epoch = now
		save_data()
	else:
		_process_offline_time(now)

func _process(delta: float) -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var total_sec: int = max(0, now - start_epoch)
	var days: float = float(total_sec) / SECONDS_PER_DAY
	var hours: int = int(total_sec / 3600) % 24
	var mins: int = int(total_sec / 60) % 60
	var secs: int = total_sec % 60
	
	if days > total_clean_days_record:
		total_clean_days_record = days
		
	streak_updated.emit(days, hours, mins, secs)

	# Continuous coin accumulation with tiered milestone multiplier
	var rate_per_sec: float = get_current_coin_rate_per_sec()
	focus_mana += rate_per_sec * delta
	mana_changed.emit(focus_mana)

	# Periodic autosave
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_data()

func get_coin_multiplier(clean_hours: float) -> float:
	var mult: float = 1.0
	for tier in COIN_TIERS:
		if clean_hours >= tier["hours"]:
			mult = tier["mult"]
		else:
			break
	return mult

func get_current_coin_tier_name() -> String:
	var hours: float = get_clean_hours()
	var tier_name: String = COIN_TIERS[0]["name"]
	for tier in COIN_TIERS:
		if hours >= tier["hours"]:
			tier_name = tier["name"]
		else:
			break
	return tier_name

func get_current_tier_index() -> int:
	var hours: float = get_clean_hours()
	var idx: int = 0
	for i in range(COIN_TIERS.size()):
		if hours >= COIN_TIERS[i]["hours"]:
			idx = i
		else:
			break
	return idx

func get_current_coin_rate_per_sec() -> float:
	var hours: float = get_clean_hours()
	return (BASE_MANA_PER_HOUR * get_coin_multiplier(hours)) / SECONDS_PER_HOUR

func calculate_offline_coins(start_streak_sec: float, end_streak_sec: float) -> float:
	if end_streak_sec <= start_streak_sec:
		return 0.0
	
	var total_earned: float = 0.0
	var num_tiers: int = COIN_TIERS.size()
	
	for i in range(num_tiers):
		var tier_start_sec: float = COIN_TIERS[i]["hours"] * SECONDS_PER_HOUR
		var tier_end_sec: float = (COIN_TIERS[i + 1]["hours"] * SECONDS_PER_HOUR) if (i + 1 < num_tiers) else INF
		
		# Calculate overlap between [start_streak_sec, end_streak_sec] and [tier_start_sec, tier_end_sec]
		var overlap_start: float = maxf(start_streak_sec, tier_start_sec)
		var overlap_end: float = minf(end_streak_sec, tier_end_sec)
		
		if overlap_end > overlap_start:
			var duration_in_tier: float = overlap_end - overlap_start
			var tier_rate_per_sec: float = (BASE_MANA_PER_HOUR * float(COIN_TIERS[i]["mult"])) / SECONDS_PER_HOUR
			total_earned += duration_in_tier * tier_rate_per_sec
			
	return total_earned

func _process_offline_time(current_time: int) -> void:
	if current_time > last_checkin_epoch:
		var start_streak_sec: float = maxf(0.0, float(last_checkin_epoch - start_epoch))
		var end_streak_sec: float = maxf(0.0, float(current_time - start_epoch))
		var earned_mana: float = calculate_offline_coins(start_streak_sec, end_streak_sec)
		if earned_mana > 0.0:
			focus_mana += earned_mana
		last_checkin_epoch = current_time
		mana_changed.emit(focus_mana)
		save_data()

func get_clean_days() -> float:
	var now: int = int(Time.get_unix_time_from_system())
	return float(max(0, now - start_epoch)) / SECONDS_PER_DAY

func get_clean_hours() -> float:
	var now: int = int(Time.get_unix_time_from_system())
	return float(max(0, now - start_epoch)) / SECONDS_PER_HOUR

func spend_mana(amount: float) -> bool:
	if focus_mana >= amount:
		focus_mana -= amount
		mana_changed.emit(focus_mana)
		save_data()
		return true
	return false

func add_mana(amount: float) -> void:
	focus_mana += amount
	mana_changed.emit(focus_mana)
	save_data()

func record_relapse() -> bool:
	var was_shielded: bool = false
	if shields > 0:
		# Shield absorbs the relapse!
		shields -= 1
		was_shielded = true
		shield_changed.emit(shields)
	else:
		# Reset streak start time
		start_epoch = int(Time.get_unix_time_from_system())
		# Award 1 fresh shield to help regain traction
		shields = 1
		shield_changed.emit(shields)
	
	last_checkin_epoch = int(Time.get_unix_time_from_system())
	relapse_handled.emit(was_shielded)
	save_data()
	return was_shielded

func complete_urge_trial(reward_mana: int = 50) -> void:
	successful_trials += 1
	add_mana(reward_mana)
	# Every 3 successful trials, earn an extra shield if not maxed
	if successful_trials % 3 == 0 and shields < max_shields:
		shields += 1
		shield_changed.emit(shields)
	trial_rewarded.emit(reward_mana)
	save_data()

# ----------------------------------------------------
# Persistence Logic (Web LocalStorage + Desktop File)
# ----------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"start_epoch": start_epoch,
		"last_checkin_epoch": int(Time.get_unix_time_from_system()),
		"shields": shields,
		"focus_mana": focus_mana,
		"successful_trials": successful_trials,
		"total_clean_days_record": total_clean_days_record,
		"selected_weather": selected_weather,
		"audio_muted": audio_muted,
		"master_volume_step": master_volume_step,
		"ambience_volume_step": ambience_volume_step,
		"sfx_volume_step": sfx_volume_step
	}

func from_dict(data: Dictionary) -> void:
	start_epoch = data.get("start_epoch", int(Time.get_unix_time_from_system()))
	last_checkin_epoch = data.get("last_checkin_epoch", start_epoch)
	shields = data.get("shields", 1)
	focus_mana = data.get("focus_mana", 0.0)
	successful_trials = data.get("successful_trials", 0)
	total_clean_days_record = data.get("total_clean_days_record", 0.0)
	selected_weather = data.get("selected_weather", "clear")
	audio_muted = data.get("audio_muted", false)
	master_volume_step = data.get("master_volume_step", 4)
	ambience_volume_step = data.get("ambience_volume_step", 3)
	sfx_volume_step = data.get("sfx_volume_step", 4)

func set_weather(weather_id: String) -> void:
	selected_weather = weather_id
	weather_changed.emit(selected_weather)
	save_data()

func save_data() -> void:
	var json_str: String = JSON.stringify(to_dict())
	if _is_web:
		var js: String = "localStorage.setItem('%s', '%s');" % [SAVE_KEY, json_str.c_escape()]
		JavaScriptBridge.eval(js)
	else:
		var file: FileAccess = FileAccess.open(LOCAL_FILE, FileAccess.WRITE)
		if file:
			file.store_string(json_str)
			file.close()

func load_data() -> void:
	var json_str: String = ""
	if _is_web:
		var js: String = "localStorage.getItem('%s') || '';" % SAVE_KEY
		var res = JavaScriptBridge.eval(js)
		if res is String:
			json_str = res
	else:
		if FileAccess.file_exists(LOCAL_FILE):
			var file: FileAccess = FileAccess.open(LOCAL_FILE, FileAccess.READ)
			if file:
				json_str = file.get_as_text()
				file.close()
				
	if json_str.length() > 0:
		var test_json = JSON.parse_string(json_str)
		if test_json is Dictionary:
			from_dict(test_json)
