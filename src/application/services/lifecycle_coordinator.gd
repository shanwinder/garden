## lifecycle_coordinator.gd
## Application-layer lifecycle coordinator for pause/resume persistence checkpoints.
##
## LifecycleCoordinator is the single authority for determining when mobile lifecycle
## transitions (application pause/resume) warrant persisting the authoritative
## GameSession to disk.
##
## Architectural rules:
## - Belongs to src/application/services/.
## - Extends RefCounted; no Node, Resource, singleton, Autoload, SceneTree, UI.
## - Coordinates the persistence checkpoint decision in one centralized place.
## - Depends on LocalSaveRepository injected at construction.
## - Receives the active GameSession explicitly during pause transitions.
## - Does NOT sample GameClock or persist lifecycle timestamps (Task 5.3B owns
##   persistence checkpoint coordination only).
## - Does NOT compute or apply offline progression on resume.
## - Suppresses duplicate pause notifications: at most one save attempt per pause transition.
## - Never writes to disk when session is null (e.g. startup blocked by INVALID_DATA or IO_ERROR).
## - Does NOT retry failed saves on duplicate pause notifications during the same paused period.
##   A subsequent resume followed by a new pause may attempt saving again.
class_name LifecycleCoordinator
extends RefCounted

## Typed outcome for application pause persistence checkpoint attempts.
enum PauseSaveOutcome {
	SAVED,
	SKIPPED_NO_ACTIVE_SESSION,
	FAILED,
	IGNORED_DUPLICATE_PAUSE,
}

## Typed outcome for application resume transition attempts.
enum ResumeOutcome {
	RESUMED,
	SKIPPED_NO_ACTIVE_SESSION,
	IGNORED_NOT_PAUSED,
}

const SAVED: PauseSaveOutcome = PauseSaveOutcome.SAVED
const SKIPPED_NO_ACTIVE_SESSION: PauseSaveOutcome = PauseSaveOutcome.SKIPPED_NO_ACTIVE_SESSION
const FAILED: PauseSaveOutcome = PauseSaveOutcome.FAILED
const IGNORED_DUPLICATE_PAUSE: PauseSaveOutcome = PauseSaveOutcome.IGNORED_DUPLICATE_PAUSE

const RESUMED: ResumeOutcome = ResumeOutcome.RESUMED
const RESUME_SKIPPED_NO_ACTIVE_SESSION: ResumeOutcome = ResumeOutcome.SKIPPED_NO_ACTIVE_SESSION
const IGNORED_NOT_PAUSED: ResumeOutcome = ResumeOutcome.IGNORED_NOT_PAUSED

var _save_repository: LocalSaveRepository
var _is_paused: bool = false
var _last_pause_outcome: Variant = null
var _last_resume_outcome: Variant = null


func _init(save_repository: LocalSaveRepository) -> void:
	assert(save_repository != null, "LifecycleCoordinator: save_repository must not be null")
	_save_repository = save_repository
	_is_paused = false
	_last_pause_outcome = null
	_last_resume_outcome = null


## Handles application pause transition.
##
## If the application is already paused, suppresses duplicate save attempts and
## returns IGNORED_DUPLICATE_PAUSE.
##
## If the application is transitioning from active to paused:
## - Marks lifecycle state as paused.
## - If [param session] is null (e.g. unbootstrapped or blocked by corrupt startup),
##   skips saving and returns SKIPPED_NO_ACTIVE_SESSION without touching disk.
## - If [param session] is present, calls save_repository.save(session.get_state())
##   exactly once and returns SAVED or FAILED accordingly.
func on_application_paused(session: GameSession) -> PauseSaveOutcome:
	if _is_paused:
		_last_pause_outcome = PauseSaveOutcome.IGNORED_DUPLICATE_PAUSE
		return PauseSaveOutcome.IGNORED_DUPLICATE_PAUSE

	_is_paused = true

	if session == null:
		_last_pause_outcome = PauseSaveOutcome.SKIPPED_NO_ACTIVE_SESSION
		return PauseSaveOutcome.SKIPPED_NO_ACTIVE_SESSION

	var save_success: bool = _save_repository.save(session.get_state())
	if save_success:
		_last_pause_outcome = PauseSaveOutcome.SAVED
		return PauseSaveOutcome.SAVED
	else:
		_last_pause_outcome = PauseSaveOutcome.FAILED
		return PauseSaveOutcome.FAILED


## Handles application resume transition.
##
## If the application is not currently paused, suppresses duplicate or spurious resume
## notifications and returns IGNORED_NOT_PAUSED.
##
## If the application is transitioning from paused to active:
## - Marks the lifecycle state as active again, allowing the next future pause
##   transition to attempt persistence.
## - If [param session] is null (e.g. unbootstrapped or blocked by corrupt startup),
##   returns ResumeOutcome.SKIPPED_NO_ACTIVE_SESSION.
## - If [param session] is present, returns ResumeOutcome.RESUMED so the composition
##   root may notify presentation to refresh derived state once.
##
## Performs NO disk reads or writes, NO state mutation, and NO direct wall-clock sampling.
## Calling resume repeatedly is safe and idempotent.
func on_application_resumed(session: GameSession = null) -> ResumeOutcome:
	if not _is_paused:
		_last_resume_outcome = ResumeOutcome.IGNORED_NOT_PAUSED
		return ResumeOutcome.IGNORED_NOT_PAUSED

	_is_paused = false

	if session == null:
		_last_resume_outcome = ResumeOutcome.SKIPPED_NO_ACTIVE_SESSION
		return ResumeOutcome.SKIPPED_NO_ACTIVE_SESSION

	_last_resume_outcome = ResumeOutcome.RESUMED
	return ResumeOutcome.RESUMED


## Returns true if the application is currently in a paused lifecycle state.
func is_application_paused() -> bool:
	return _is_paused


## Returns the repository instance used by this coordinator.
func get_save_repository() -> LocalSaveRepository:
	return _save_repository


## Returns the outcome of the most recent pause event, or null if no pause has occurred.
func get_last_pause_outcome() -> Variant:
	return _last_pause_outcome


## Returns the outcome of the most recent resume event, or null if no resume has occurred.
func get_last_resume_outcome() -> Variant:
	return _last_resume_outcome
