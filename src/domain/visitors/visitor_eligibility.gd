## visitor_eligibility.gd
## Stateless deterministic domain evaluator for visitor eligibility rules.
##
## Evaluates whether a VisitorDefinition's requirements are satisfied by a
## given GardenSnapshot, independent of random selection or presentation scenes.
##
## Architectural rules:
## - Belongs to the domain visitors layer (src/domain/visitors/).
## - Stateless pure rule evaluator: extends RefCounted.
## - Does not depend on SceneTree, Node, Autoload, GameClock, RandomSource, or filesystem.
## - Pure queries: no state mutation, no RNG consumption, no push_error on ineligible inputs.
class_name VisitorEligibility
extends RefCounted


## Returns true if [param visitor] is valid and all of its requirements are satisfied
## by [param snapshot].
static func is_eligible(visitor: VisitorDefinition, snapshot: GardenSnapshot) -> bool:
	if visitor == null or snapshot == null:
		return false

	if not visitor.is_valid():
		return false

	if snapshot.get_total_plant_count() < visitor.min_total_plants:
		return false

	if snapshot.get_mature_plant_count() < visitor.min_mature_plants:
		return false

	for key: Variant in visitor.required_trait_counts.keys():
		var trait_id: String = key as String
		var required_count: int = visitor.required_trait_counts[key] as int
		if snapshot.get_trait_count(trait_id) < required_count:
			return false

	for required_plant_id: String in visitor.required_plant_ids:
		if snapshot.get_plant_count_for_definition(required_plant_id) < 1:
			return false

	for required_decor_id: String in visitor.required_decoration_ids:
		if snapshot.get_decoration_count_for_definition(required_decor_id) < 1:
			return false

	if not visitor.allowed_time_periods.is_empty():
		if not visitor.allowed_time_periods.has(snapshot.get_time_period()):
			return false

	if not visitor.allowed_weather_states.is_empty():
		if not visitor.allowed_weather_states.has(snapshot.get_weather_state()):
			return false

	return true


## Returns a new Array[VisitorDefinition] containing all visitors from [param visitors]
## that are eligible for [param snapshot], preserving caller order.
static func filter_eligible_visitors(
	visitors: Array[VisitorDefinition],
	snapshot: GardenSnapshot
) -> Array[VisitorDefinition]:
	var eligible: Array[VisitorDefinition] = []
	if snapshot == null or visitors.is_empty():
		return eligible

	for visitor: VisitorDefinition in visitors:
		if is_eligible(visitor, snapshot):
			eligible.append(visitor)

	return eligible
