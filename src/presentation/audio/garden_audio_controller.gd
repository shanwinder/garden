## garden_audio_controller.gd
## Lightweight presentation-layer coordinator for garden ambient loops and UI/gameplay SFX.
##
## Architectural rules (ARCHITECTURE.md §31):
## - Belongs to src/presentation/audio/.
## - Separates ambient soundscapes (day/night/rain) from one-shot UI/gameplay SFX.
## - Stores mute preference separately from authoritative GameState (JSON settings file).
## - Not an autoload or general-purpose global manager.
class_name GardenAudioController
extends Node

const DEFAULT_SETTINGS_PATH: String = "user://audio_settings.json"

const AMBIENT_CUE_PATHS: Dictionary = {
	"day": "res://assets/audio/ambient/ambient_day.wav",
	"night": "res://assets/audio/ambient/ambient_night.wav",
	"rain": "res://assets/audio/ambient/ambient_rain.wav",
}

const SFX_CUE_PATHS: Dictionary = {
	"ui_tap": "res://assets/audio/sfx/sfx_ui_tap.wav",
	"plant": "res://assets/audio/sfx/sfx_plant.wav",
	"harvest": "res://assets/audio/sfx/sfx_harvest.wav",
	"discover": "res://assets/audio/sfx/sfx_discover.wav",
	"place_decor": "res://assets/audio/sfx/sfx_place_decor.wav",
}

const AMBIENT_VOLUME_DB: float = -8.0
const SFX_VOLUME_DB: float = -4.0

var _ambient_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null
var _stream_cache: Dictionary = {}

var _settings_path: String = DEFAULT_SETTINGS_PATH
var _is_muted: bool = false
var _is_paused: bool = false
var _current_ambient_cue: String = ""
var _last_sfx_cue: String = ""


func _ready() -> void:
	_ensure_players()
	load_settings()
	_sync_ambient_playback()


func _exit_tree() -> void:
	if _ambient_player != null:
		_ambient_player.stop()
		_ambient_player.stream = null
	if _sfx_player != null:
		_sfx_player.stop()
		_sfx_player.stream = null
	_stream_cache.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		set_paused(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_paused(false)


func _ensure_players() -> void:
	if _ambient_player == null:
		_ambient_player = get_node_or_null("AmbientPlayer") as AudioStreamPlayer
	if _ambient_player == null:
		_ambient_player = AudioStreamPlayer.new()
		_ambient_player.name = "AmbientPlayer"
		_ambient_player.volume_db = AMBIENT_VOLUME_DB
		add_child(_ambient_player)

	if _sfx_player == null:
		_sfx_player = get_node_or_null("SfxPlayer") as AudioStreamPlayer
	if _sfx_player == null:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "SfxPlayer"
		_sfx_player.volume_db = SFX_VOLUME_DB
		add_child(_sfx_player)


## Configures the JSON settings path (primarily for isolated test execution).
func set_settings_path(path: String) -> void:
	_settings_path = path if not path.is_empty() else DEFAULT_SETTINGS_PATH


## Loads persisted mute preference safely; defaults to unmuted on missing or malformed file.
func load_settings() -> void:
	if not FileAccess.file_exists(_settings_path):
		return
	var text: String = FileAccess.get_file_as_string(_settings_path)
	if text.is_empty():
		return
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return
	if json.data is Dictionary:
		var dict: Dictionary = json.data as Dictionary
		_is_muted = bool(dict.get("muted", false))


## Persists current mute preference to the dedicated audio settings file.
func save_settings() -> bool:
	var dir_path: String = _settings_path.get_base_dir()
	if not dir_path.is_empty():
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file: FileAccess = FileAccess.open(_settings_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "muted": _is_muted}))
	file.close()
	return true


## Maps time_period and weather_state to the matching ambient cue ("day", "night", or "rain").
static func resolve_ambient_cue(time_period: String, weather_state: String) -> String:
	if weather_state == GardenWeather.RAIN:
		return "rain"
	if time_period == GardenTimePeriod.NIGHT or time_period == GardenTimePeriod.EVENING:
		return "night"
	return "day"


## Updates the ambient soundscape for the current garden atmosphere.
func update_atmosphere(time_period: String, weather_state: String) -> void:
	_ensure_players()
	var next_cue: String = resolve_ambient_cue(time_period, weather_state)
	var cue_changed: bool = (next_cue != _current_ambient_cue)
	_current_ambient_cue = next_cue
	if cue_changed:
		_ambient_player.stream = _load_cached_stream(str(AMBIENT_CUE_PATHS.get(next_cue, "")))
	_sync_ambient_playback(cue_changed)


## Plays a named one-shot UI or gameplay sound effect when unmuted and in tree.
func play_sfx(cue_id: String) -> void:
	_ensure_players()
	if not SFX_CUE_PATHS.has(cue_id):
		return
	_last_sfx_cue = cue_id
	if _is_muted or _is_paused or not is_inside_tree():
		return
	var stream: AudioStream = _load_cached_stream(str(SFX_CUE_PATHS[cue_id]))
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = SFX_VOLUME_DB
	if AudioServer.get_driver_name() != "Dummy":
		_sfx_player.play()


## Sets mute state, updates active playback, and optionally persists preference.
func set_muted(muted: bool, persist: bool = true) -> void:
	_ensure_players()
	_is_muted = muted
	_sync_ambient_playback()
	if persist:
		save_settings()


## Toggles mute state, persists preference, and returns the new muted state.
func toggle_muted() -> bool:
	set_muted(not _is_muted, true)
	return _is_muted


## Pauses or resumes audio playback (e.g. for Android background/foreground lifecycle).
func set_paused(paused: bool) -> void:
	_ensure_players()
	_is_paused = paused
	_sync_ambient_playback()


func _sync_ambient_playback(restart_if_needed: bool = false) -> void:
	if _ambient_player == null:
		return
	if _is_muted or _is_paused or not is_inside_tree():
		if _ambient_player.playing:
			_ambient_player.stop()
		return
	if _ambient_player.stream == null and not _current_ambient_cue.is_empty():
		_ambient_player.stream = _load_cached_stream(str(AMBIENT_CUE_PATHS.get(_current_ambient_cue, "")))
	if _ambient_player.stream != null and (restart_if_needed or not _ambient_player.playing):
		_ambient_player.volume_db = AMBIENT_VOLUME_DB
		if AudioServer.get_driver_name() != "Dummy":
			_ambient_player.play()


func _load_cached_stream(resource_path: String) -> AudioStream:
	if resource_path.is_empty():
		return null
	if _stream_cache.has(resource_path):
		return _stream_cache[resource_path] as AudioStream
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded: Resource = ResourceLoader.load(resource_path)
	if loaded is AudioStream:
		var stream: AudioStream = loaded as AudioStream
		_stream_cache[resource_path] = stream
		return stream
	return null


## Pure query for testing: returns true when audio is muted.
func is_muted() -> bool:
	return _is_muted


## Pure query for testing: returns true when audio is lifecycle-paused.
func is_paused() -> bool:
	return _is_paused


## Pure query for testing: returns active ambient cue ("day", "night", "rain", or "").
func get_current_ambient_cue() -> String:
	return _current_ambient_cue


## Pure query for testing: returns last requested SFX cue ID.
func get_last_sfx_cue() -> String:
	return _last_sfx_cue


## Pure query for testing: returns true when ambient AudioStreamPlayer is actively playing.
func is_ambient_playing() -> bool:
	return _ambient_player != null and _ambient_player.playing
