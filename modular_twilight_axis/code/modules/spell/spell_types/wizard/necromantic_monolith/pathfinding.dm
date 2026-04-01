// ---- Necromantic Monolith: pathfinding, throne selection & route utilities ----

// ---- Placement validation ----

/proc/can_place_necromonolith_on(turf/target_turf, mob/living/user)
	if(!target_turf || !isopenturf(target_turf))
		return "The monolith needs open ground."
	if(!target_turf.can_traverse_safely(user))
		return "That ground rejects the rite."
	if(locate(/obj/structure/necromantic_monolith) in target_turf)
		return "A monolith is already rooted there."
	for(var/atom/movable/blocker in target_turf)
		if(blocker == user)
			continue
		if(blocker.density)
			return "Something blocks the monolith from taking shape there."
	return null

// ---- Route preparation ----

/proc/prepare_necromonolith_routes(turf/origin, mob/living/caster)
	var/list/candidate_thrones = rank_necromonolith_candidate_thrones(origin)
	if(!length(candidate_thrones))
		log_necromonolith_debug("no throne candidates found from origin=[necromonolith_debug_coords(origin)]")
		return null

	for(var/atom/movable/target_throne as anything in candidate_thrones)
		var/list/goal_turfs = get_necromonolith_goal_turfs(target_throne)
		if(!length(goal_turfs))
			continue

		var/list/routes = calculate_necromonolith_routes(origin, goal_turfs)
		if(!length(routes))
			continue

		log_necromonolith_debug("route prep origin=[necromonolith_debug_coords(origin)] throne=[necromonolith_debug_coords(target_throne)] routes=[describe_necromonolith_routes(routes)]")
		return list(
			"throne" = target_throne,
			"routes" = routes,
		)

	log_necromonolith_debug("failed to prepare routes from origin=[necromonolith_debug_coords(origin)] across [length(candidate_thrones)] throne candidates")
	return null

/proc/find_necromonolith_target_throne(turf/reference_turf)
	var/list/candidate_thrones = rank_necromonolith_candidate_thrones(reference_turf)
	if(length(candidate_thrones))
		return candidate_thrones[1]
	return null

// ---- Throne candidate caching (once per round) ----

/proc/get_necromonolith_throne_candidates()
	if(length(global.necromonolith_throne_cache))
		var/list/valid = list()
		for(var/atom/movable/throne as anything in global.necromonolith_throne_cache)
			if(!QDELETED(throne))
				valid += throne
		global.necromonolith_throne_cache = valid
		return valid

	var/list/candidates = list()
	for(var/obj/structure/roguethrone/throne in world)
		if(!QDELETED(throne))
			candidates += throne
	for(var/obj/structure/chair/wood/rogue/throne/throne_chair in world)
		if(!QDELETED(throne_chair))
			candidates += throne_chair
	global.necromonolith_throne_cache = candidates
	log_necromonolith_debug("throne cache built: [length(candidates)] candidates")
	return candidates

/proc/rank_necromonolith_candidate_thrones(turf/reference_turf)
	var/obj/structure/roguethrone/king_throne = GLOB.king_throne
	var/mob/living/ruler = SSticker.rulermob
	var/area/ruler_area = get_area(ruler)
	var/list/scored_thrones = list()

	var/list/candidates = get_necromonolith_throne_candidates()
	for(var/atom/movable/throne as anything in candidates)
		if(QDELETED(throne))
			continue
		var/base_score
		if(istype(throne, /obj/structure/roguethrone))
			base_score = (throne == king_throne) ? 200000 : 100000
		else
			base_score = (throne == king_throne) ? 2000 : 1000
		scored_thrones[throne] = score_necromonolith_throne(throne, reference_turf, ruler, ruler_area, base_score)

	var/list/ranked_thrones = list()
	while(length(scored_thrones))
		var/atom/movable/best_throne
		var/best_score = -1.0e31
		for(var/atom/movable/throne as anything in scored_thrones)
			var/score = scored_thrones[throne]
			if(score <= best_score)
				continue
			best_score = score
			best_throne = throne
		if(!best_throne)
			break
		ranked_thrones += best_throne
		scored_thrones -= best_throne
	return ranked_thrones

/proc/score_necromonolith_throne(atom/movable/throne, turf/reference_turf, mob/living/ruler, area/ruler_area, base_score)
	var/score = base_score
	if(ruler)
		if(throne.z == ruler.z)
			score += 250
		score -= get_dist(ruler, throne)
	if(ruler_area && get_area(throne) == ruler_area)
		score += 1500
	if(reference_turf)
		if(throne.z == reference_turf.z)
			score += 50
		score -= (get_dist(reference_turf, throne) * 0.1)
	return score

// ---- Goal turfs ----

/proc/get_necromonolith_goal_turfs(atom/movable/throne)
	var/list/goal_turfs = list()
	var/turf/throne_turf = get_turf(throne)
	if(!throne_turf)
		return goal_turfs

	if(is_necromonolith_turf_clear(throne_turf))
		goal_turfs += throne_turf

	for(var/turf/candidate in orange(1, throne_turf))
		if(candidate.z != throne_turf.z)
			continue
		if(!is_necromonolith_turf_clear(candidate))
			continue
		goal_turfs += candidate

	return goal_turfs

// ---- Route calculation ----

/proc/calculate_necromonolith_routes(turf/origin, list/goal_turfs)
	var/list/routes = list()
	var/list/primary_route = select_best_necromonolith_route(origin, goal_turfs)
	if(!length(primary_route))
		return routes

	routes += list(primary_route)
	var/list/goal_routes = collect_necromonolith_goal_routes(origin, goal_turfs)
	for(var/list/goal_route as anything in goal_routes)
		if(necromonolith_route_exists(goal_route, routes))
			continue
		routes += list(goal_route)
		if(length(routes) >= NECROMONOLITH_DESIRED_ROUTES)
			return routes

	var/list/seed_routes = list(primary_route)
	var/list/fractions = list(0.15, 0.3, 0.45, 0.6, 0.75, 0.9)

	var/seed_index = 1
	while(length(routes) < NECROMONOLITH_DESIRED_ROUTES && seed_index <= length(seed_routes))
		var/list/seed_route = seed_routes[seed_index]
		for(var/fraction in fractions)
			var/turf/exclusion = pick_necromonolith_exclusion(seed_route, fraction)
			if(!exclusion)
				continue
			var/list/alternate_route = select_best_necromonolith_route(origin, goal_turfs, exclusion)
			if(!length(alternate_route) || necromonolith_route_exists(alternate_route, routes))
				continue
			routes += list(alternate_route)
			seed_routes += list(alternate_route)
			if(length(routes) >= NECROMONOLITH_DESIRED_ROUTES)
				break
		seed_index++

	while(length(routes) < NECROMONOLITH_DESIRED_ROUTES)
		routes += list(primary_route.Copy())

	return routes

/proc/collect_necromonolith_goal_routes(turf/origin, list/goal_turfs)
	var/list/routes = list()
	for(var/turf/goal_turf as anything in goal_turfs)
		if(!goal_turf)
			continue
		var/list/path = get_path_to(origin, goal_turf, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d), 0, NECROMONOLITH_ROUTE_DEPTH, 0, adjacent = TYPE_PROC_REF(/turf, reachableTurftest3d_necromonolith))
		if(!length(path) || necromonolith_route_exists(path, routes))
			continue
		routes += list(path)
	return routes

/proc/select_best_necromonolith_route(turf/origin, list/goal_turfs, turf/exclusion)
	var/list/best_route = list()
	for(var/turf/goal_turf as anything in goal_turfs)
		if(!goal_turf)
			continue
		var/list/path = get_path_to(origin, goal_turf, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d), 0, NECROMONOLITH_ROUTE_DEPTH, 0, adjacent = TYPE_PROC_REF(/turf, reachableTurftest3d_necromonolith), exclude = exclusion)
		if(!length(path))
			continue
		if(!length(best_route) || length(path) < length(best_route))
			best_route = path
	return best_route

/proc/pick_necromonolith_exclusion(list/route, fraction)
	if(length(route) < 6)
		return null
	var/index = clamp(round(length(route) * fraction), 2, length(route) - 1)
	return route[index]

// ---- Route comparison ----

/proc/necromonolith_route_exists(list/candidate_route, list/routes)
	for(var/list/existing_route as anything in routes)
		if(necromonolith_routes_match(candidate_route, existing_route))
			return TRUE
	return FALSE

/proc/necromonolith_routes_match(list/left_route, list/right_route)
	if(length(left_route) != length(right_route))
		return FALSE
	for(var/i in 1 to length(left_route))
		if(left_route[i] != right_route[i])
			return FALSE
	return TRUE

// ---- Route normalization ----

/proc/normalize_necromonolith_routes(list/routes, turf/origin)
	var/list/normalized = list()
	for(var/list/route as anything in routes)
		var/list/clean_route = sanitize_necromonolith_route(route, origin)
		if(!length(clean_route))
			continue
		if(necromonolith_route_exists(clean_route, normalized))
			continue
		normalized += list(clean_route)
	return normalized

/proc/sanitize_necromonolith_route(list/route, turf/origin)
	var/list/clean_route = list()
	for(var/turf/step as anything in route)
		if(!step || QDELETED(step))
			continue
		if(!length(clean_route) && origin && step == origin)
			continue
		clean_route += step
	return clean_route

// ---- Route validation ----

/proc/is_necromonolith_route_passable(list/route)
	if(!length(route))
		return FALSE
	var/route_len = length(route)
	var/samples = min(route_len, 10)
	var/blocked_count = 0
	for(var/i in 1 to samples)
		var/index = max(1, round((i / samples) * route_len))
		var/turf/check_turf = route[index]
		if(!check_turf || QDELETED(check_turf))
			blocked_count++
			continue
		if(check_turf.density)
			blocked_count++
			continue
		var/hard_blocked = FALSE
		for(var/atom/movable/blocker in check_turf)
			if(!blocker.density)
				continue
			if(istype(blocker, /obj/structure/mineral_door))
				continue
			if(istype(blocker, /obj/structure/roguewindow))
				continue
			if(istype(blocker, /obj/structure/barricade))
				continue
			hard_blocked = TRUE
			break
		if(hard_blocked)
			blocked_count++
	return blocked_count <= 2

// ---- Necromonolith adjacency (ignores doors/grates for pathing) ----

/turf/proc/reachableTurftest3d_necromonolith(caller, turf/T, ID, recursive_call = 0)
	if(!T || T.density)
		return FALSE
	if(!T.can_traverse_safely(caller))
		return FALSE
	var/z_distance = abs(T.z - z)
	if(!z_distance)
		return !necromonolith_link_blocked(T, caller, ID)
	if(z_distance != 1)
		return FALSE
	var/obj/structure/stairs/source_stairs = locate(/obj/structure/stairs) in src
	if(T.z < z)
		if(source_stairs?.get_target_loc(GLOB.reverse_dir[source_stairs.dir]) == T)
			return TRUE
	else
		if(source_stairs?.get_target_loc(source_stairs.dir) == T)
			return TRUE
	return FALSE

/proc/necromonolith_link_blocked(turf/T, turf/source, ID)
	var/adir = get_dir(source, T)
	var/rdir = GLOB.reverse_dir[adir]
	for(var/obj/O in T)
		if(istype(O, /obj/structure/mineral_door))
			continue
		if(istype(O, /obj/structure/roguewindow))
			continue
		if(istype(O, /obj/structure/barricade))
			continue
		if(!O.CanAStarPass(ID, rdir, source))
			return TRUE
	return FALSE

/// Check if a dense object on a turf is a breakable obstacle (door/window/barricade)
/proc/is_necromonolith_breakable_obstacle(turf/T)
	for(var/obj/O in T)
		if(!O.density)
			continue
		if(istype(O, /obj/structure/mineral_door))
			return TRUE
		if(istype(O, /obj/structure/roguewindow))
			return TRUE
		if(istype(O, /obj/structure/barricade))
			return TRUE
	return FALSE

// ---- Spawn turfs ----

/proc/get_necromonolith_spawn_turfs(atom/source)
	var/list/spawn_turfs = list()
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return spawn_turfs

	if(is_necromonolith_turf_clear(source_turf, source))
		spawn_turfs += source_turf
	for(var/turf/candidate in orange(1, source_turf))
		if(!is_necromonolith_turf_clear(candidate))
			continue
		spawn_turfs += candidate
	return spawn_turfs

/proc/is_necromonolith_turf_clear(turf/target_turf, atom/ignore)
	if(!target_turf || !isopenturf(target_turf))
		return FALSE
	for(var/atom/movable/blocker in target_turf)
		if(blocker == ignore)
			continue
		if(blocker.density)
			return FALSE
	return TRUE
