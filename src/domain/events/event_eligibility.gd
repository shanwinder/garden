## event_eligibility.gd
## Stateless deterministic domain evaluator for ambient/special garden event eligibility rules.
##
## Evaluates whether an EventDefinition's requirements (traits, plant/decoration counts,
## required plant/decoration IDs, time-of-day periods, and weather states) are satisfied
## by a given GardenSnapshot, independent of random selection or presentation scenes.
##
## Architectural rules:
## - Belongs to the domain events layer (src/domain/events/).
## - Stateless pure rule evaluator: extends RefCounted.
## - Does not depend on SceneTree, Node, Autoload, GameClock, RandomSource, or filesystem.
## - Pure queries: no state mutation, no RNG consumption, no push_error on ineligible inputs.
class_name EventEligibility
extends RefCounted


## Returns true if [param event_def] is valid and all of its requirements are satisfied
## by [param snapshot].
static func is_eligible(event_def: EventDefinition, snapshot: GardenSnapshot) -> bool:
	if event_def == null or snapshot == null:
		return false

	if not event_def.is_valid():
		return false

	if snapshot.get_total_plant_count() < event_def.min_total_plants:
		return false

	if snapshot.get_mature_plant_count() < event_def.min_mature_plants:
		return false

	if snapshot.get_total_decoration_count() < event_def.min_total_decorations:
		return false

	for key: Variant in event_def.required_trait_counts.keys():
		var trait_id: String = key as String
		var required_count: int = event_def.required_trait_counts[key] as int
		if snapshot.get_trait_count(trait_id) < required_count:
			return false

	for required_plant_id: String in event_def.required_plant_ids:
		if snapshot.get_plant_count_for_definition(required_plant_id) < 1:
			return false

	for required_decor_id: String in event_def.required_decoration_ids:
		if snapshot.get_decoration_count_for_definition(required_decor_id) < 1:
			return false

	if not event_def.allowed_time_periods.is_empty():
		if not event_def.allowed_time_periods.has(snapshot.get_time_period()):
			return false

	if not event_def.allowed_weather_states.is_empty():
		if not event_def.allowed_weather_states.has(snapshot.get_weather_state()):
			return false

	return true


## Returns a new Array[EventDefinition] containing all events from [param events]
## that are eligible for [param snapshot], preserving caller order.
static func filter_eligible_events(
	events: Array[EventDefinition],
	snapshot: GardenSnapshot
) -> Array[EventDefinition]:
	var eligible: Array[EventDefinition] = []
	if snapshot == null or events.is_empty():
		return eligible

	for event_def: EventDefinition in events:
		if is_eligible(event_def, snapshot):
			eligible.append(event_def)

	return eligible
