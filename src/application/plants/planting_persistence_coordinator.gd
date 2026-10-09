## planting_persistence_coordinator.gd
## Application-layer coordinator for planting persistence integration checkpoints.
##
## Coordinates successful logical planting and one immediate persistence checkpoint.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application coordinator: extends RefCounted (not Node, Resource, Autoload, singleton).
## - Does NOT own a second GameState.
## - Does NOT implement planting validation again (delegates to GameSession.try_plant_now).
## - Does NOT generate runtime IDs itself.
## - Does NOT sample GameClock itself.
## - Does NOT consume RandomSource itself.
## - Does NOT serialize JSON or use FileAccess / DirAccess directly.
## - Does NOT introduce a second persistence repository.
## - Does NOT implement UI, pricing, or placement.
## - Receives all existing dependencies explicitly.
## - Returns strongly-typed PlantingCheckpointResult.
class_name PlantingPersistenceCoordinator
extends RefCounted


## Validates dependencies, performs logical planting via session.try_plant_now(),
## and if registered, triggers an immediate persistence checkpoint via repository.save().
static func try_plant_and_save(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	repository: LocalSaveRepository,
	definition_id: String
) -> PlantingCheckpointResult:
	# 1. Dependency presence validation
	if session == null or catalog == null or game_clock == null or random_source == null or repository == null:
		return PlantingCheckpointResult.not_ready()

	# 2. Authoritative GameState presence check
	if session.get_state() == null:
		return PlantingCheckpointResult.not_ready()

	# 3. Perform logical planting attempt (exactly once)
	var registration_result: PlantRegistrationResult = session.try_plant_now(
		catalog,
		game_clock,
		random_source,
		definition_id
	)

	# 4. If planting failed, do not attempt to save
	if not registration_result.is_registered():
		return PlantingCheckpointResult.planting_rejected(registration_result)

	# 5. Logical planting succeeded; attempt immediate persistence checkpoint (exactly once)
	var save_success: bool = repository.save(session.get_state())
	if save_success:
		return PlantingCheckpointResult.registered_saved(registration_result)
	else:
		return PlantingCheckpointResult.registered_save_failed(registration_result)
