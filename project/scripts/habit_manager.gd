# scripts/habit_manager.gd
# Autoload singleton handling habit tracking, offline elapsed time,
# grace shields, and local persistence across Web and Desktop.
extends Node

signal streak_updated(days: float, hours: int, minutes: int, seconds: int)
signal shield_changed(current_shields: int)
signal mana_changed(current_mana: float)
signal relapse_handled(was_shielded: bool)
signal trial_rewarded(focus_crystals: int)

const SAVE_KEY: String = "sanctuary_habit_save_v1"
const LOCAL_FILE: String = "user://habit_save.json"

const SECONDS_PER_DAY: float = 86400.0
const SECONDS_PER_HOUR: float = 3600.0
const MANA_PER_HOUR: float = 10.0 # Focus mana earned per clean hour

# Habit state
var start_epoch: int = 0
var last_checkin_epoch: int = 0
var shields: int = 1 # Starts with 1 grace shield
var max_shields: int = 3
var focus_mana: float = 0.0
var successful_trials: int = 0
var total_clean_days_record: float = 0.0

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
	# Passive continuous mana accumulation
	focus_mana += (MANA_PER_HOUR / 3600.0) * delta
	
	var now: int = int(Time.get_unix_time_from_system())
	var total_sec: int = max(0, now - start_epoch)
	var days: float = float(total_sec) / SECONDS_PER_DAY
	var hours: int = int(total_sec / 3600) % 24
	var mins: int = int(total_sec / 60) % 60
	var secs: int = total_sec % 60
	
	if days > total_clean_days_record:
		total_clean_days_record = days
		
	streak_updated.emit(days, hours, mins, secs)

func _process_offline_time(current_time: int) -> void:
	var offline_seconds: int = max(0, current_time - last_checkin_epoch)
	if offline_seconds > 0:
		var earned_mana: float = (float(offline_seconds) / SECONDS_PER_HOUR) * MANA_PER_HOUR
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
		"total_clean_days_record": total_clean_days_record
	}

func from_dict(data: Dictionary) -> void:
	start_epoch = data.get("start_epoch", int(Time.get_unix_time_from_system()))
	last_checkin_epoch = data.get("last_checkin_epoch", start_epoch)
	shields = data.get("shields", 1)
	focus_mana = data.get("focus_mana", 0.0)
	successful_trials = data.get("successful_trials", 0)
	total_clean_days_record = data.get("total_clean_days_record", 0.0)

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
