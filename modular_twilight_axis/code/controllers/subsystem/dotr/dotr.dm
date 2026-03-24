// ---- SSdotr: Defence of the Roguetown ----
// Manages mob virtualization. Spawners register as controllers, SSdotr handles the rest.

SUBSYSTEM_DEF(dotr)
	name = "Defence of the Roguetown"
	wait = DOTR_CHECK_INTERVAL
	priority = FIRE_PRIORITY_DEFAULT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/controllers = list()
	var/list/all_profiles = list()
	var/next_profile_id = 1
	var/next_controller_id = 1
	var/step_counter = 0
	/// Temporary per-tick cache: z-string -> list(turf)
	var/list/player_cache

// ---- Registration ----

/datum/controller/subsystem/dotr/proc/register_controller(datum/dotr_controller/ctrl)
	if(!ctrl || (ctrl in controllers))
		return
	ctrl.controller_id = next_controller_id++
	controllers += ctrl
	log_dotr_debug("registered controller=[ctrl.controller_id] type=[ctrl.type]")

/datum/controller/subsystem/dotr/proc/unregister_controller(datum/dotr_controller/ctrl)
	if(!ctrl)
		return
	var/removed = 0
	var/list/keep = list()
	for(var/datum/dotr_profile/P as anything in all_profiles)
		if(P.controller == ctrl)
			removed++
			qdel(P)
		else
			keep += P
	all_profiles = keep
	controllers -= ctrl
	log_dotr_debug("unregistered controller=[ctrl.controller_id], removed [removed] profiles")

/// Count virtual profiles belonging to a controller
/datum/controller/subsystem/dotr/proc/count_profiles(datum/dotr_controller/ctrl)
	var/n = 0
	for(var/datum/dotr_profile/P as anything in all_profiles)
		if(P.controller == ctrl)
			n++
	return n

// ---- Main loop ----

/datum/controller/subsystem/dotr/fire(resumed = 0)
	if(!length(controllers))
		return
	// Build player cache
	player_cache = list()
	for(var/client/C as anything in GLOB.clients)
		if(!C?.mob || !isliving(C.mob))
			continue
		var/mob/living/P = C.mob
		if(P.stat == DEAD)
			continue
		var/turf/T = get_turf(P)
		if(!T)
			continue
		var/zk = "[T.z]"
		if(!player_cache[zk])
			player_cache[zk] = list()
		player_cache[zk] += T

	// Devirtualize
	process_devirt()
	// Virtualize
	process_virt()
	// Virtual movement
	step_counter++
	if(step_counter >= DOTR_VIRTUAL_STEP_TICKS)
		step_counter = 0
		advance_profiles()
	// Wither + cleanup
	process_wither()
	cleanup_dead()
	player_cache = null

// ---- Devirtualization ----

/datum/controller/subsystem/dotr/proc/process_devirt()
	var/list/devirtualized = list()
	for(var/datum/dotr_profile/profile as anything in all_profiles)
		if(!profile.controller)
			devirtualized += profile
			continue
		if(world.time < profile.last_devirt_attempt + DOTR_DEVIRT_COOLDOWN)
			continue
		var/turf/vt = profile.get_virtual_turf()
		if(!vt)
			continue
		var/list/pts = player_cache ? player_cache["[vt.z]"] : null
		if(!length(pts))
			continue
		// Nearest player
		var/turf/nearest
		var/best = INFINITY
		for(var/turf/pt as anything in pts)
			var/d = get_dist(vt, pt)
			if(d < best)
				best = d
				nearest = pt
		if(best > DOTR_PLAYER_ZONE_RANGE)
			continue
		// Spawn gate
		if(count_physical_near(profile.controller, nearest) >= DOTR_MAX_PHYSICAL_PER_ZONE)
			profile.last_devirt_attempt = world.time
			log_dotr_debug("gate full near [nearest.x],[nearest.y],[nearest.z], deferring id=[profile.profile_id]")
			continue
		// Safe spawn turf
		var/turf/st = find_spawn_turf(vt, nearest)
		if(!st)
			profile.last_devirt_attempt = world.time
			continue
		// Materialize
		var/mob/living/M = profile.controller.materialize(profile, st)
		if(M && !QDELETED(M))
			log_dotr_debug("devirt id=[profile.profile_id] [profile.mob_type] at [st.x],[st.y],[st.z] hp=[profile.current_health]")
			devirtualized += profile
		else
			profile.last_devirt_attempt = world.time
	for(var/datum/dotr_profile/P as anything in devirtualized)
		all_profiles -= P
		qdel(P)

// ---- Virtualization ----

/datum/controller/subsystem/dotr/proc/process_virt()
	for(var/datum/dotr_controller/ctrl as anything in controllers)
		var/z = ctrl.get_z_level()
		if(!z)
			continue
		var/list/pts = player_cache ? player_cache["[z]"] : null
		for(var/mob/living/M as anything in ctrl.get_managed_mobs())
			if(!M || QDELETED(M) || M.stat == DEAD)
				continue
			// Near any player? Stay physical.
			var/dominated = FALSE
			var/turf/mt = get_turf(M)
			if(mt && length(pts))
				for(var/turf/pt as anything in pts)
					if(get_dist(mt, pt) <= DOTR_PLAYER_ZONE_RANGE)
						dominated = TRUE
						break
			if(dominated)
				continue
			if(!ctrl.can_virtualize(M))
				continue
			var/datum/dotr_profile/profile = ctrl.capture(M)
			if(!profile)
				continue
			profile.profile_id = next_profile_id++
			profile.virtualized_at = world.time
			profile.sync_position()
			all_profiles += profile
			log_dotr_debug("virt [profile.mob_type] id=[profile.profile_id] at [profile.turf_x],[profile.turf_y],[profile.turf_z]")

// ---- Virtual movement ----

/datum/controller/subsystem/dotr/proc/advance_profiles()
	// Group by controller + route_slot
	var/list/groups = list()
	for(var/datum/dotr_profile/P as anything in all_profiles)
		if(P.current_health <= 0)
			continue
		// Chasing — move independently
		var/atom/target = P.chase_target_ref?.resolve()
		if(target && !QDELETED(target))
			advance_chase(P, target)
			continue
		if(P.chase_target_ref)
			P.chase_target_ref = null
			P.chase_started_at = 0
		var/key = "[P.controller?.controller_id]-[P.route_slot]"
		if(!groups[key])
			groups[key] = list()
		groups[key] += P
	// Advance groups
	for(var/key in groups)
		var/list/grp = groups[key]
		var/datum/dotr_profile/rep = grp[1]
		var/list/routes = rep.controller?.get_routes()
		if(!length(routes) || rep.route_slot < 1 || rep.route_slot > length(routes))
			continue
		var/rlen = length(routes[rep.route_slot])
		if(!rlen)
			continue
		for(var/datum/dotr_profile/P as anything in grp)
			if(P.route_index < rlen)
				P.route_index++
				P.sync_position()

/datum/controller/subsystem/dotr/proc/advance_chase(datum/dotr_profile/P, atom/target)
	if(P.chase_started_at && world.time > P.chase_started_at + DOTR_VIRTUAL_CHASE_TIMEOUT)
		P.chase_target_ref = null
		P.chase_started_at = 0
		return
	var/turf/tt = get_turf(target)
	if(!tt)
		P.chase_target_ref = null
		P.chase_started_at = 0
		return
	P.chase_target_x = tt.x
	P.chase_target_y = tt.y
	P.chase_target_z = tt.z
	var/dx = P.chase_target_x - P.turf_x
	var/dy = P.chase_target_y - P.turf_y
	if(abs(dx) >= abs(dy))
		P.turf_x += (dx > 0) ? 1 : -1
	else
		P.turf_y += (dy > 0) ? 1 : -1
	P.turf_x = clamp(P.turf_x, 1, world.maxx)
	P.turf_y = clamp(P.turf_y, 1, world.maxy)

// ---- Wither ----

/datum/controller/subsystem/dotr/proc/process_wither()
	for(var/datum/dotr_profile/P as anything in all_profiles)
		if(P.is_withering)
			P.apply_wither_tick(DOTR_CHECK_INTERVAL * 0.1)

// ---- Cleanup ----

/datum/controller/subsystem/dotr/proc/cleanup_dead()
	var/list/keep = list()
	for(var/datum/dotr_profile/P as anything in all_profiles)
		if(P.current_health <= 0)
			P.controller?.on_profile_died(P)
			log_dotr_debug("profile id=[P.profile_id] died virtual")
			qdel(P)
		else
			keep += P
	all_profiles = keep

// ---- Virtual combat (stub — ready for multi-faction) ----

/datum/controller/subsystem/dotr/proc/process_combat()
	return // No hostile factions yet

// ---- Helpers ----

/datum/controller/subsystem/dotr/proc/count_physical_near(datum/dotr_controller/ctrl, turf/center)
	var/n = 0
	for(var/mob/living/M as anything in ctrl.get_managed_mobs())
		if(!M || QDELETED(M) || M.stat == DEAD)
			continue
		if(get_dist(get_turf(M), center) <= DOTR_PLAYER_ZONE_RANGE)
			n++
	return n

/datum/controller/subsystem/dotr/proc/find_spawn_turf(turf/virtual_turf, turf/player_turf)
	if(!virtual_turf || !player_turf)
		return null
	var/best_turf
	var/best_dist = INFINITY
	for(var/turf/T in range(DOTR_SPAWN_EDGE_RANGE, player_turf))
		if(get_dist(player_turf, T) < DOTR_SPAWN_EDGE_RANGE - 1)
			continue
		if(!isopenturf(T))
			continue
		var/blocked = FALSE
		for(var/atom/movable/AM in T)
			if(AM.density)
				blocked = TRUE
				break
		if(blocked)
			continue
		var/d = get_dist(T, virtual_turf)
		if(d < best_dist)
			best_dist = d
			best_turf = T
	if(best_turf)
		return best_turf
	// Fallback: virtual turf itself
	if(isopenturf(virtual_turf))
		for(var/atom/movable/AM in virtual_turf)
			if(AM.density)
				return null
		return virtual_turf
	return null
