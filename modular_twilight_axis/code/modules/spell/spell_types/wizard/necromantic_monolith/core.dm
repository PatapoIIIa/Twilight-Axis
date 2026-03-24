// ---- Necromantic Monolith: core structure ----

/obj/structure/necromantic_monolith
	name = "necromantic monolith"
	desc = "A hateful shard of dark progress. It pulses with fixed roads leading to the throne."
	icon = 'icons/roguetown/items/gems.dmi'
	icon_state = "necro_crystal"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	max_integrity = 250
	var/datum/weakref/owner_ref
	var/owner_name
	var/owner_faction_tag
	var/datum/weakref/throne_ref
	var/list/cached_routes = list()
	var/list/active_minions = list()
	var/spawn_timer_id
	var/next_route_pick = 1
	var/spawn_cycle_count = 0
	var/waves_since_rest = 0
	/// Per-minion routing state: weakref -> list("route_index", "route_slot", "chase_ref", "chase_started_at", "reengage_after")
	var/list/minion_states = list()
	/// SSdotr virtualization controller
	var/datum/dotr_controller/necromonolith/dotr_ctrl

/obj/structure/necromantic_monolith/Initialize(mapload, mob/living/caster, atom/movable/preferred_throne, list/precomputed_routes)
	. = ..()
	if(caster)
		owner_ref = WEAKREF(caster)
		owner_name = caster.real_name ? caster.real_name : caster.name
		if(caster.mind?.current)
			owner_faction_tag = "[caster.mind.current.real_name]_faction"
	if(preferred_throne && !QDELETED(preferred_throne))
		throne_ref = WEAKREF(preferred_throne)
	cached_routes = normalize_necromonolith_routes(precomputed_routes, get_turf(src))
	if(!length(cached_routes) && !refresh_necromonolith_routes())
		return INITIALIZE_HINT_QDEL
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	log_necromonolith_debug("initialized monolith=[necromonolith_debug_coords(src)] throne=[necromonolith_debug_coords(resolved_throne)] routes=[describe_necromonolith_routes(cached_routes)]")
	set_light(3, 2, 1, l_color = "#6f2036")
	queue_next_spawn_cycle()
	// Register with SSdotr for mob virtualization
	dotr_ctrl = new /datum/dotr_controller/necromonolith(src)
	SSdotr.register_controller(dotr_ctrl)

/obj/structure/necromantic_monolith/Destroy()
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
	// Unregister from SSdotr before collapsing minions
	if(dotr_ctrl)
		SSdotr.unregister_controller(dotr_ctrl)
		QDEL_NULL(dotr_ctrl)
	collapse_necromonolith_minions()
	throne_ref = null
	cached_routes = null
	active_minions = null
	minion_states = null
	return ..()

/obj/structure/necromantic_monolith/examine(mob/user)
	. = ..()
	if(length(cached_routes))
		. += span_notice("It currently holds [length(cached_routes)] cached route[length(cached_routes) == 1 ? "" : "s"] to the throne.")
	var/atom/movable/resolved_throne = throne_ref?.resolve()
	if(resolved_throne && !QDELETED(resolved_throne))
		. += span_notice("Its necromantic pull is fixed toward [resolved_throne].")

// ---- Spawn cycle ----

/obj/structure/necromantic_monolith/proc/queue_next_spawn_cycle()
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(process_spawn_cycle)), NECROMONOLITH_SPAWN_INTERVAL, TIMER_STOPPABLE)

/obj/structure/necromantic_monolith/proc/process_spawn_cycle()
	spawn_timer_id = null
	if(QDELETED(src))
		return
	cleanup_necromonolith_minions()
	spawn_cycle_count++

	if(spawn_cycle_count % NECROMONOLITH_ROUTE_VALIDATE_EVERY == 0)
		validate_cached_routes()

	if(waves_since_rest >= NECROMONOLITH_WAVES_PER_REST)
		waves_since_rest = 0
		log_necromonolith_debug("monolith=[necromonolith_debug_coords(src)] resting for one cycle")
		queue_next_spawn_cycle()
		return

	if(refresh_necromonolith_routes())
		spawn_necromonolith_wave()
		waves_since_rest++
	else
		log_necromonolith_debug("spawn cycle aborted, no valid throne route from monolith=[necromonolith_debug_coords(src)]")
	queue_next_spawn_cycle()
