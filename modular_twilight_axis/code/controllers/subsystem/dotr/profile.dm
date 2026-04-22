// ---- SSdotr: virtual mob profile ----
// Lightweight snapshot replacing a physical mob while virtualized.

/datum/dotr_profile
	/// Owning controller
	var/datum/dotr_controller/controller
	var/profile_id = 0

	/// Type path to recreate the mob
	var/mob_type
	/// Combat stats
	var/max_health = 100
	var/current_health = 100
	var/melee_damage_lower = 10
	var/melee_damage_upper = 25
	var/defprob = 50
	var/is_ranged = FALSE

	/// Route position
	var/route_slot = 1
	var/route_index = 1
	var/virtual_move_accumulator = 0
	var/virtual_step_delay = DOTR_DEFAULT_VIRTUAL_STEP_DELAY

	/// Virtual position (fallback when route invalid)
	var/turf_x = 0
	var/turf_y = 0
	var/turf_z = 0

	/// Chase state
	var/datum/weakref/chase_target_ref
	var/chase_target_x = 0
	var/chase_target_y = 0
	var/chase_target_z = 0
	var/chase_started_at = 0
	var/reengage_after = 0

	/// Deferred death
	var/is_withering = FALSE
	var/wither_accumulator = 0

	/// Group movement key (profiles with same key advance together)
	var/group_key

	/// Anti-flicker
	var/last_devirt_attempt = 0
	var/virtualized_at = 0

/datum/dotr_profile/Destroy()
	controller = null
	chase_target_ref = null
	return ..()

/// Get the turf this profile is virtually at
/datum/dotr_profile/proc/get_virtual_turf()
	if(controller)
		var/list/routes = controller.get_routes()
		if(length(routes) && route_slot >= 1 && route_slot <= length(routes))
			var/list/route = routes[route_slot]
			if(length(route) && route_index >= 1 && route_index <= length(route))
				var/turf/T = route[route_index]
				if(T && !QDELETED(T))
					return T
	return locate(turf_x, turf_y, turf_z)

/// Update stored x/y/z from current route position
/datum/dotr_profile/proc/sync_position()
	var/turf/T = get_virtual_turf()
	if(T)
		turf_x = T.x
		turf_y = T.y
		turf_z = T.z

/// Returns TRUE when the virtual marker may advance one tile this tick.
/datum/dotr_profile/proc/consume_virtual_step()
	var/step_delay = max(virtual_step_delay || DOTR_DEFAULT_VIRTUAL_STEP_DELAY, DOTR_CHECK_INTERVAL)
	virtual_move_accumulator += DOTR_CHECK_INTERVAL
	if(virtual_move_accumulator < step_delay)
		return FALSE
	virtual_move_accumulator = max(0, virtual_move_accumulator - step_delay)
	return TRUE

/// Tick wither damage. Returns TRUE if dead.
/datum/dotr_profile/proc/apply_wither_tick(delta_seconds)
	if(!is_withering)
		return FALSE
	wither_accumulator += DOTR_WITHER_DPS * delta_seconds
	if(wither_accumulator >= 1)
		var/dmg = round(wither_accumulator)
		current_health -= dmg
		wither_accumulator -= dmg
	return (current_health <= 0)
