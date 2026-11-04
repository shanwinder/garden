## harvest_persistence_coordinator.gd
## Application-layer coordinator for harvest persistence integration checkpoints.
##
## Coordinates successful logical harvesting and one immediate persistence checkpoint.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application coordinator: extends RefCounted (not Node, Resource, Autoload, singleton).
## - Does NOT own a second GameState.
## - Does NOT implement harvest validation again (delegates to GameSession.try_harvest_now).
## - Does NOT sample GameClock itself.
## - Does NOT serialize JSON or use FileAccess / DirAccess directly.
## - Does NOT introduce a second persistence repository.
## - Receives all existing dependencies explicitly.
## - Returns strongly-typed HarvestCheckpointResult.
class_name HarvestPersistenceCoordinator
extends RefCounted


## Validates dependencies, performs logical harvesting via session.try_harvest_now(),
## and if harvested, triggers an immediate persistence checkpoint via repository.save().
static func try_harvest_and_save(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock,
	repository: LocalSaveRepository,
	runtime_instance_id: String
) -> HarvestCheckpointResult:
	# 1. Dependency presence validation
	if session == null or catalog == null or game_clock == null or repository == null:
		return HarvestCheckpointResult.not_ready()

	# 2. Authoritative GameState presence check
	if session.get_state() == null:
		return HarvestCheckpointResult.not_ready()

	# 3. Perform logical harvest attempt (exactly once)
	var harvest_result: PlantHarvestResult = session.try_harvest_now(
		catalog,
		game_clock,
		runtime_instance_id
	)

	# 4. If harvest failed, do not attempt to save
	if not harvest_result.is_harvested():
		return HarvestCheckpointResult.harvest_rejected(harvest_result)

	# 5. Logical harvest succeeded; attempt immediate persistence checkpoint (exactly once)
	var save_success: bool = repository.save(session.get_state())
	if save_success:
		return HarvestCheckpointResult.harvested_saved(harvest_result)
	else:
		return HarvestCheckpointResult.harvested_save_failed(harvest_result)
