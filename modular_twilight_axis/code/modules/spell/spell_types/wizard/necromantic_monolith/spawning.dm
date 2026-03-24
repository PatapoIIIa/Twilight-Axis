// ---- Necromantic Monolith: minion spawning, registration & cleanup ----

/obj/structure/necromantic_monolith/proc/spawn_necromonolith_wave()
	var/current_minions = cleanup_necromonolith_minions()
	if(current_minions >= NECROMONOLITH_MAX_MINIONS)
		return
	if(!length(cached_routes))
		return

	var/mob/living/caster = owner_ref?.resolve()
	var/to_spawn = min(rand(NECROMONOLITH_MIN_SPAWN, NECROMONOLITH_MAX_SPAWN), NECROMONOLITH_MAX_MINIONS - current_minions)
	var/list/spawn_points = get_necromonolith_spawn_turfs(src)
	if(!length(spawn_points))
		return

	var/list/spawn_types = list(
		/mob/living/simple_animal/hostile/rogue/skeleton/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/axe/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/spear/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/guard/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/bow/necromonolith,
	)

	var/list/available_points = spawn_points.Copy()
	for(var/i in 1 to to_spawn)
		if(!length(available_points))
			available_points = spawn_points.Copy()
		var/turf/spawn_turf = pick(available_points)
		available_points -= spawn_turf

		var/spawn_type = pick(spawn_types)
		var/mob/living/simple_animal/hostile/rogue/skeleton/new_minion = new spawn_type(spawn_turf, caster, TRUE, FALSE)
		if(QDELETED(new_minion))
			continue

		new /obj/effect/temp_visual/bluespace_fissure(spawn_turf)
		apply_necromonolith_owner_data(new_minion)
		var/route_slot = take_next_necromonolith_route_slot()
		register_minion(new_minion, route_slot)
		log_necromonolith_debug("spawned [new_minion.type] at [necromonolith_debug_coords(new_minion)] route_slot=[route_slot] route=[describe_necromonolith_route(cached_routes[route_slot])]")

/obj/structure/necromantic_monolith/proc/apply_necromonolith_owner_data(mob/living/simple_animal/hostile/rogue/skeleton/minion)
	if(!minion)
		return
	if(owner_name)
		minion.summoner = owner_name
	if(owner_faction_tag)
		minion.faction |= owner_faction_tag

// ---- Minion registration (central brain) ----

/obj/structure/necromantic_monolith/proc/register_minion(mob/living/simple_animal/hostile/rogue/skeleton/minion, route_slot)
	var/datum/weakref/minion_ref = WEAKREF(minion)
	active_minions += minion_ref

	// Create per-minion routing state owned by the monolith
	var/list/state = list()
	state["route_slot"] = route_slot
	state["route_index"] = 1
	state["chase_ref"] = null
	state["chase_started_at"] = 0
	state["reengage_after"] = 0
	minion_states[minion_ref] = state

	// Configure the skeleton for monolith service
	minion.loot = list()
	minion.remains_type = null
	minion.wander = FALSE
	QDEL_IN(minion, NECROMONOLITH_MINION_LIFETIME)

	if(!minion.ai_controller)
		minion.InitializeAIController()
	minion.ai_controller.CancelActions()
	minion.ai_controller.clear_blackboard_key(BB_FOLLOW_TARGET)
	minion.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	minion.ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
	minion.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	minion.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)

	// Attach thin component (signal relay only)
	minion.AddComponent(/datum/component/necromonolith_minion, src)

	var/list/route = get_minion_route(route_slot)
	var/turf/goal = length(route) ? route[length(route)] : null
	log_necromonolith_debug("registered [minion.type] at [necromonolith_debug_coords(minion)] route_slot=[route_slot] goal=[necromonolith_debug_coords(goal)]")

/obj/structure/necromantic_monolith/proc/unregister_minion(mob/living/minion)
	if(!minion)
		return
	for(var/datum/weakref/minion_ref as anything in active_minions)
		if(minion_ref.resolve() != minion)
			continue
		active_minions -= minion_ref
		minion_states -= minion_ref
		break

// ---- Minion cleanup ----

/obj/structure/necromantic_monolith/proc/cleanup_necromonolith_minions()
	var/list/valid_minions = list()
	var/list/valid_states = list()
	for(var/datum/weakref/minion_ref as anything in active_minions)
		var/mob/living/simple_animal/hostile/rogue/skeleton/minion = minion_ref.resolve()
		if(!minion || QDELETED(minion) || minion.stat == DEAD)
			continue
		valid_minions += minion_ref
		if(minion_states[minion_ref])
			valid_states[minion_ref] = minion_states[minion_ref]
	active_minions = valid_minions
	minion_states = valid_states
	// Include virtualized profiles in the total count
	var/virtual_count = 0
	if(dotr_ctrl)
		for(var/datum/dotr_profile/P as anything in SSdotr.all_profiles)
			if(P.controller == dotr_ctrl)
				virtual_count++
	return length(active_minions) + virtual_count

/obj/structure/necromantic_monolith/proc/collapse_necromonolith_minions()
	for(var/datum/weakref/minion_ref as anything in active_minions)
		var/mob/living/simple_animal/hostile/rogue/skeleton/minion = minion_ref.resolve()
		if(!minion || QDELETED(minion))
			continue
		minion.visible_message(span_danger("[minion] collapses into lifeless bone as the monolith breaks."))
		qdel(minion)
