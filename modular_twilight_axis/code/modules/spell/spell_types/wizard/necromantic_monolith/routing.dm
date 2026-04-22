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
		cached_hold_turfs = list()
		next_hold_turf_refresh = 0
		throne_ref = null
		refresh_necromonolith_routes()
	else if(length(valid_routes) < length(cached_routes))
		cached_routes = valid_routes
		next_route_pick = min(next_route_pick, length(cached_routes))

/obj/structure/necromantic_monolith/proc/refresh_necromonolith_routes()
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	if(resolved_throne && !QDELETED(resolved_throne) && length(cached_routes))
		if(!length(cached_hold_turfs) || world.time >= next_hold_turf_refresh)
			refresh_necromonolith_hold_turfs()
		return TRUE

	var/mob/living/caster = owner_ref?.resolve()
	var/list/setup = prepare_necromonolith_routes(get_turf(src), caster)
	if(!setup)
		return FALSE

	throne_ref = WEAKREF(setup["throne"])
	cached_routes = normalize_necromonolith_routes(setup["routes"], get_turf(src))
	refresh_necromonolith_hold_turfs(force = TRUE)
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

	var/turf/current_turf = get_turf(skeleton)
	if(!current_turf)
		return

	var/list/route = get_active_minion_route(state)
	update_minion_route_progress(skeleton, state, current_turf)

	// If skeleton is chasing a target, handle chase timeout
	var/atom/current_target = skeleton.ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(current_target)
		handle_minion_chase(skeleton, state, route, current_target)
		return
	if(state["climbing_wall"])
		return

	// No target — clear chase state and advance along route
	state["chase_ref"] = null
	state["chase_started_at"] = 0

	if(try_start_minion_wall_climb(skeleton, minion_ref, state, route))
		return

	var/route_index = state["route_index"]
	var/route_length = length(route)
	while(route_index <= route_length)
		var/turf/next_turf = route[route_index]
		if(!next_turf || QDELETED(next_turf))
			route_index++
			continue
		if(current_turf == next_turf)
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
	var/turf/hold_turf = get_minion_hold_turf(skeleton, state, route, current_turf)
	if(hold_turf && current_turf != hold_turf)
		if(skeleton.ai_controller.blackboard[BB_TRAVEL_DESTINATION] != hold_turf)
			skeleton.ai_controller.set_blackboard_key(BB_TRAVEL_DESTINATION, hold_turf)
		return
	if(skeleton.ai_controller.blackboard[BB_TRAVEL_DESTINATION])
		skeleton.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)

// ---- Route state helpers ----

/obj/structure/necromantic_monolith/proc/get_active_minion_route(list/state)
	var/list/personal_route = state["personal_route"]
	if(length(personal_route))
		return personal_route
	return get_minion_route(state["route_slot"])

/obj/structure/necromantic_monolith/proc/update_minion_route_progress(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, turf/current_turf)
	if(!current_turf)
		current_turf = get_turf(skeleton)
	if(!current_turf)
		return
	var/datum/weakref/last_turf_ref = state["last_turf_ref"]
	if(last_turf_ref?.resolve() == current_turf)
		state["stuck_ticks"] = (state["stuck_ticks"] || 0) + 1
		return
	state["last_turf_ref"] = WEAKREF(current_turf)
	state["stuck_ticks"] = 0

/obj/structure/necromantic_monolith/proc/get_minion_hold_turf(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, list/route, turf/current_turf)
	if(!current_turf)
		current_turf = get_turf(skeleton)
	var/route_length = length(route)
	var/turf/assigned_turf = state["hold_turf"]
	if(assigned_turf && !QDELETED(assigned_turf))
		if(assigned_turf == current_turf || is_necromonolith_turf_clear(assigned_turf, skeleton))
			return assigned_turf

	var/list/candidates = get_necromonolith_extended_goal_turfs()
	var/candidate_count = length(candidates)
	if(!candidate_count)
		return route_length ? route[route_length] : null

	var/start_index = ((state["hold_offset"] || 1) - 1) % candidate_count + 1
	for(var/offset in 0 to candidate_count - 1)
		var/index = ((start_index + offset - 1) % candidate_count) + 1
		var/turf/candidate = candidates[index]
		if(!is_necromonolith_turf_clear(candidate, skeleton))
			continue
		state["hold_turf"] = candidate
		return candidate

	return route_length ? route[route_length] : null

/obj/structure/necromantic_monolith/proc/get_necromonolith_extended_goal_turfs()
	if(length(cached_hold_turfs) && world.time < next_hold_turf_refresh)
		return cached_hold_turfs
	return refresh_necromonolith_hold_turfs()

/obj/structure/necromantic_monolith/proc/refresh_necromonolith_hold_turfs(force = FALSE)
	if(!force && length(cached_hold_turfs) && world.time < next_hold_turf_refresh)
		return cached_hold_turfs
	next_hold_turf_refresh = world.time + NECROMONOLITH_HOLD_TURF_REFRESH
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	if(!resolved_throne || QDELETED(resolved_throne))
		cached_hold_turfs = list()
		return list()

	var/list/goal_turfs = get_necromonolith_goal_turfs(resolved_throne)
	if(length(goal_turfs) >= NECROMONOLITH_DESIRED_ROUTES)
		cached_hold_turfs = goal_turfs
		return goal_turfs

	var/turf/throne_turf = get_turf(resolved_throne)
	if(!throne_turf)
		cached_hold_turfs = goal_turfs
		return goal_turfs

	for(var/turf/candidate in orange(2, throne_turf))
		if(candidate.z != throne_turf.z)
			continue
		if(!is_necromonolith_turf_clear(candidate))
			continue
		if(candidate in goal_turfs)
			continue
		goal_turfs += candidate
	cached_hold_turfs = goal_turfs
	return goal_turfs

// ---- Chase management ----

/obj/structure/necromantic_monolith/proc/handle_minion_chase(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, list/route, atom/current_target)
	var/reengage_after = state["reengage_after"]
	if(reengage_after && world.time < reengage_after)
		force_minion_return(skeleton, state, "reengage cooldown", route)
		return

	if(!current_target || QDELETED(current_target))
		force_minion_return(skeleton, state, "invalid target", route)
		return

	var/datum/weakref/tracked_ref = state["chase_ref"]
	var/atom/tracked_target = tracked_ref?.resolve()
	if(current_target != tracked_target)
		state["chase_ref"] = WEAKREF(current_target)
		state["chase_started_at"] = world.time
		state["chase_anchor_index"] = clamp(state["route_index"] || 1, 1, max(length(route), 1))
		log_necromonolith_debug("[skeleton.type] at [necromonolith_debug_coords(skeleton)] acquired chase target=[necromonolith_debug_coords(current_target)] route_slot=[state["route_slot"]]")
		return

	var/chase_started_at = state["chase_started_at"]
	if(!chase_started_at)
		state["chase_started_at"] = world.time
		return

	if(world.time < chase_started_at + NECROMONOLITH_CHASE_TIMEOUT)
		var/chase_anchor_index = state["chase_anchor_index"] || state["route_index"] || 1
		if(get_dist_3d(skeleton, current_target) > NECROMONOLITH_CHASE_LEASH_DISTANCE)
			state["reengage_after"] = world.time + NECROMONOLITH_REENGAGE_COOLDOWN
			force_minion_return(skeleton, state, "target escaped leash", route)
			return
		if(necromonolith_route_window_distance(current_target, route, chase_anchor_index, NECROMONOLITH_ROUTE_WINDOW) > NECROMONOLITH_TARGET_ROUTE_LEASH_DISTANCE)
			state["reengage_after"] = world.time + NECROMONOLITH_REENGAGE_COOLDOWN
			force_minion_return(skeleton, state, "target left route", route)
			return
		return

	state["reengage_after"] = world.time + NECROMONOLITH_REENGAGE_COOLDOWN
	force_minion_return(skeleton, state, "chase timeout vs [necromonolith_debug_coords(current_target)]", route)

/obj/structure/necromantic_monolith/proc/force_minion_return(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state, reason, list/route)
	if(skeleton.ai_controller)
		skeleton.ai_controller.CancelActions()
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
		skeleton.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
		skeleton.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
	skeleton.LoseTarget()
	state["chase_ref"] = null
	state["chase_started_at"] = 0
	state["route_index"] = find_necromonolith_nearest_route_index(skeleton, route, state["route_index"] || 1)
	log_necromonolith_debug("[skeleton.type] at [necromonolith_debug_coords(skeleton)] forced back to route ([reason]); next waypoint index=[state["route_index"]]")

/obj/structure/necromantic_monolith/proc/can_minion_engage(datum/weakref/minion_ref)
	var/list/state = minion_states[minion_ref]
	if(!state)
		return TRUE
	var/reengage_after = state["reengage_after"]
	if(reengage_after && world.time < reengage_after)
		return FALSE
	return TRUE

// ---- Route distance & wall fallback ----

/proc/find_necromonolith_nearest_route_index(atom/source, list/route, preferred_index = 1)
	var/route_length = length(route)
	if(!source || !route_length)
		return max(preferred_index, 1)
	var/best_index = clamp(preferred_index || 1, 1, route_length)
	var/best_distance = INFINITY
	for(var/i in 1 to route_length)
		var/turf/route_turf = route[i]
		if(!route_turf || QDELETED(route_turf))
			continue
		var/distance = get_dist_3d(source, route_turf)
		if(distance >= best_distance)
			continue
		best_distance = distance
		best_index = i
	return best_index

/proc/necromonolith_route_window_distance(atom/source, list/route, center_index, window_size)
	var/route_length = length(route)
	if(!source || !route_length)
		return INFINITY
	var/start_index = max(1, center_index - window_size)
	var/end_index = min(route_length, center_index + window_size)
	var/best_distance = INFINITY
	for(var/i in start_index to end_index)
		var/turf/route_turf = route[i]
		if(!route_turf || QDELETED(route_turf))
			continue
		best_distance = min(best_distance, get_dist_3d(source, route_turf))
	return best_distance

/obj/structure/necromantic_monolith/proc/try_start_minion_wall_climb(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, datum/weakref/minion_ref, list/state, list/route)
	if((state["stuck_ticks"] || 0) < NECROMONOLITH_STUCK_WALL_CLIMB_TICKS)
		return FALSE
	if(state["wall_climb_cooldown"] && world.time < state["wall_climb_cooldown"])
		return FALSE
	if(skeleton.doing)
		return FALSE
	if(has_necromonolith_route_obstacle_to_break(skeleton))
		return FALSE

	var/turf/current_turf = get_turf(skeleton)
	if(!current_turf)
		return FALSE
	var/route_length = length(route)
	var/turf/route_goal = route_length ? route[route_length] : get_turf(throne_ref?.resolve())

	var/turf/closed/best_wall
	var/turf/best_landing
	var/best_distance = INFINITY
	for(var/direction in GLOB.cardinals)
		var/turf/closed/candidate_wall = get_step(current_turf, direction)
		if(!istype(candidate_wall, /turf/closed) || !candidate_wall.wallclimb)
			continue
		var/turf/candidate_landing = get_necromonolith_wall_climb_landing(skeleton, candidate_wall)
		if(!candidate_landing)
			continue
		var/distance = route_goal ? get_dist_3d(candidate_landing, route_goal) : 0
		if(distance >= best_distance)
			continue
		best_wall = candidate_wall
		best_landing = candidate_landing
		best_distance = distance

	if(!best_wall || !best_landing)
		return FALSE

	state["climbing_wall"] = TRUE
	state["wall_climb_cooldown"] = world.time + NECROMONOLITH_WALL_CLIMB_COOLDOWN
	if(skeleton.ai_controller)
		skeleton.ai_controller.CancelActions()
		skeleton.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
	INVOKE_ASYNC(src, PROC_REF(perform_minion_wall_climb), minion_ref, WEAKREF(best_wall), WEAKREF(best_landing))
	return TRUE

/proc/has_necromonolith_route_obstacle_to_break(mob/living/simple_animal/hostile/rogue/skeleton/skeleton)
	if(!skeleton?.ai_controller)
		return FALSE
	var/atom/destination = skeleton.ai_controller.blackboard[BB_TRAVEL_DESTINATION]
	if(!destination || QDELETED(destination))
		return FALSE
	var/turf/next_step = get_step_towards(skeleton, destination)
	if(!next_step || !next_step.is_blocked_turf(exclude_mobs = TRUE, source_atom = skeleton))
		return FALSE
	var/list/obstacle_whitelist = get_necromonolith_obstacle_whitelist()
	for(var/obj/object as anything in next_step)
		if(object.IsObscured())
			continue
		if(skeleton.see_invisible < object.invisibility)
			continue
		if(is_type_in_typecache(object, obstacle_whitelist))
			return TRUE
	return FALSE

/obj/structure/necromantic_monolith/proc/get_necromonolith_wall_climb_landing(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, turf/closed/wall)
	var/turf/current_turf = get_turf(skeleton)
	if(!current_turf || !wall || !wall.wallclimb)
		return null
	var/turf/above_current = get_step_multiz(current_turf, UP)
	if(!istype(above_current, /turf/open/transparent/openspace))
		return null
	if(!skeleton.can_zTravel(above_current, UP))
		return null

	var/turf/landing = get_step_multiz(wall, UP)
	if(!is_necromonolith_wall_landing_clear(landing, skeleton))
		return null
	return landing

/proc/is_necromonolith_wall_landing_clear(turf/landing, mob/living/simple_animal/hostile/rogue/skeleton/skeleton)
	if(!landing || landing.density)
		return FALSE
	if(istype(landing, /turf/closed) || istype(landing, /turf/open/transparent/openspace))
		return FALSE
	for(var/atom/movable/blocker in landing)
		if(blocker == skeleton)
			continue
		if(blocker.density)
			return FALSE
	return TRUE

/obj/structure/necromantic_monolith/proc/perform_minion_wall_climb(datum/weakref/minion_ref, datum/weakref/wall_ref, datum/weakref/landing_ref)
	var/mob/living/simple_animal/hostile/rogue/skeleton/skeleton = minion_ref?.resolve()
	var/turf/closed/wall = wall_ref?.resolve()
	var/turf/landing = landing_ref?.resolve()
	var/list/state = minion_states[minion_ref]
	if(!skeleton || QDELETED(skeleton) || skeleton.stat == DEAD || !state)
		return
	if(!wall || QDELETED(wall) || !landing || QDELETED(landing))
		state["climbing_wall"] = FALSE
		return

	skeleton.visible_message(span_warning("[skeleton] claws into [wall] and starts climbing."))
	if(!do_after(skeleton, NECROMONOLITH_WALL_CLIMB_TIME, target = wall))
		state["climbing_wall"] = FALSE
		return
	if(QDELETED(src) || QDELETED(skeleton) || skeleton.stat == DEAD)
		return
	if(!get_necromonolith_wall_climb_landing(skeleton, wall))
		state["climbing_wall"] = FALSE
		return

	skeleton.forceMove(landing)
	skeleton.visible_message(span_warning("[skeleton] pulls itself over [wall]."))
	state["climbing_wall"] = FALSE
	state["stuck_ticks"] = 0
	state["last_turf_ref"] = WEAKREF(get_turf(skeleton))
	rebuild_minion_personal_route(skeleton, state)

/obj/structure/necromantic_monolith/proc/rebuild_minion_personal_route(mob/living/simple_animal/hostile/rogue/skeleton/skeleton, list/state)
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	var/turf/current_turf = get_turf(skeleton)
	if(!resolved_throne || QDELETED(resolved_throne) || !current_turf)
		return

	var/list/goal_turfs = get_necromonolith_goal_turfs(resolved_throne, include_blocked = TRUE)
	var/list/routes = calculate_necromonolith_routes(current_turf, goal_turfs)
	if(!length(routes))
		state["route_index"] = find_necromonolith_nearest_route_index(skeleton, get_minion_route(state["route_slot"]), state["route_index"] || 1)
		return

	state["personal_route"] = sanitize_necromonolith_route(routes[1], current_turf)
	state["route_index"] = 1
	state["hold_turf"] = null
