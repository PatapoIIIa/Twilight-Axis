// ---- Necromantic Monolith: central routing brain ----
// The monolith directs each minion every Life() tick via the thin component relay.

/obj/structure/necromantic_monolith/proc/validate_cached_routes()
	if(!length(cached_routes))
		return
	var/list/valid_routes = list()
	for(var/list/route as anything in cached_routes)
		if(is_necromonolith_route_passable(route))
			valid_routes += list(route)
		else
			log_necromonolith_debug("route invalidated: [describe_necromonolith_route(route)]")
	if(!length(valid_routes))
		log_necromonolith_debug("all routes invalidated, forcing full refresh")
		cached_routes = list()
		throne_ref = null
		refresh_necromonolith_routes()
	else if(length(valid_routes) < length(cached_routes))
		cached_routes = valid_routes
		next_route_pick = min(next_route_pick, length(cached_routes))

/obj/structure/necromantic_monolith/proc/refresh_necromonolith_routes()
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	if(resolved_throne && !QDELETED(resolved_throne) && length(cached_routes))
		return TRUE

	var/mob/living/caster = owner_ref?.resolve()
	var/list/setup = prepare_necromonolith_routes(get_turf(src), caster)
	if(!setup)
		return FALSE

	throne_ref = WEAKREF(setup["throne"])
	cached_routes = normalize_necromonolith_routes(setup["routes"], get_turf(src))
	next_route_pick = 1
	resolved_throne = throne_ref?.resolve()
	log_necromonolith_debug("refreshed routes monolith=[necromonolith_debug_coords(src)] throne=[necromonolith_debug_coords(resolved_throne)] routes=[describe_necromonolith_routes(cached_routes)]")
	return length(cached_routes) > 0

/obj/structure/necromantic_monolith/proc/take_next_necromonolith_route_slot()
	if(!length(cached_routes))
		return 0
	if(next_route_pick < 1 || next_route_pick > length(cached_routes))
		next_route_pick = 1
	. = next_route_pick
	next_route_pick++
	if(next_route_pick > length(cached_routes))
		next_route_pick = 1

/obj/structure/necromantic_monolith/proc/get_minion_route(route_slot)
	if(!length(cached_routes) || route_slot < 1 || route_slot > length(cached_routes))
		return list()
	return cached_routes[route_slot]

// ---- Per-minion direction ----

/obj/structure/necromantic_monolith/proc/direct_minion(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, datum/weakref/minion_ref)
	if(QDELETED(src) || !skeleton || QDELETED(skeleton) || skeleton.stat == DEAD)
		return
	if(!skeleton.ai_controller?.blackboard)
		return

	var/list/state = minion_states[minion_ref]
	if(!state)
		return

	var/route_slot = state["route_slot"]
	var/list/route = get_minion_route(route_slot)

	// If skeleton is chasing a target, handle chase timeout
	var/atom/current_target = skeleton.ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(current_target)
		handle_minion_chase(skeleton, state, current_target)
		return

	// No target — clear chase state and advance along route
	state["chase_ref"] = null
	state["chase_started_at"] = 0

	var/route_index = state["route_index"]
	while(route_index <= length(route))
		var/turf/next_turf = route[route_index]
		if(!next_turf || QDELETED(next_turf))
			route_index++
			continue
		if(get_turf(skeleton) == next_turf)
			route_index++
			continue
		state["route_index"] = route_index
		var/turf/current_destination = skeleton.ai_controller.blackboard[BB_TRAVEL_DESTINATION]
		if(current_destination == next_turf)
			return
		skeleton.ai_controller.set_blackboard_key(BB_TRAVEL_DESTINATION, next_turf)
		return
	state["route_index"] = route_index

	// Route exhausted — head to final goal
	var/turf/goal = length(route) ? route[length(route)] : null
	if(goal && get_turf(skeleton) != goal)
		if(skeleton.ai_controller.blackboard[BB_TRAVEL_DESTINATION] != goal)
			skeleton.ai_controller.set_blackboard_key(BB_TRAVEL_DESTINATION, goal)

// ---- Chase management ----

/obj/structure/necromantic_monolith/proc/handle_minion_chase(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, atom/current_target)
	var/reengage_after = state["reengage_after"]
	if(reengage_after && world.time < reengage_after)
		force_minion_return(skeleton, state, "reengage cooldown")
		return

	if(!current_target || QDELETED(current_target))
		force_minion_return(skeleton, state, "invalid target")
		return

	var/datum/weakref/tracked_ref = state["chase_ref"]
	var/atom/tracked_target = tracked_ref?.resolve()
	if(current_target != tracked_target)
		state["chase_ref"] = WEAKREF(current_target)
		state["chase_started_at"] = world.time
		log_necromonolith_debug("[skeleton.type] at [necromonolith_debug_coords(skeleton)] acquired chase target=[necromonolith_debug_coords(current_target)] route_slot=[state["route_slot"]]")
		return

	var/chase_started_at = state["chase_started_at"]
	if(!chase_started_at)
		state["chase_started_at"] = world.time
		return

	if(world.time < chase_started_at + NECROMONOLITH_CHASE_TIMEOUT)
		return

	state["reengage_after"] = world.time + NECROMONOLITH_REENGAGE_COOLDOWN
	force_minion_return(skeleton, state, "chase timeout vs [necromonolith_debug_coords(current_target)]")

/obj/structure/necromantic_monolith/proc/force_minion_return(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, reason)
	if(skeleton.ai_controller)
		skeleton.ai_controller.CancelActions()
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
		skeleton.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
	skeleton.LoseTarget()
	state["chase_ref"] = null
	state["chase_started_at"] = 0
	log_necromonolith_debug("[skeleton.type] at [necromonolith_debug_coords(skeleton)] forced back to route ([reason]); next waypoint index=[state["route_index"]]")

/obj/structure/necromantic_monolith/proc/can_minion_engage(mob/living/skeleton, atom/the_target)
	for(var/datum/weakref/minion_ref as anything in active_minions)
		if(minion_ref.resolve() != skeleton)
			continue
		var/list/state = minion_states[minion_ref]
		if(!state)
			return TRUE
		var/reengage_after = state["reengage_after"]
		if(reengage_after && world.time < reengage_after)
			return FALSE
		return TRUE
	return TRUE
