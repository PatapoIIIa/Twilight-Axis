// ---- Necromantic Monolith: SSdort adapter ----
// Makes the monolith a user of SSdort, like skeletons are users of the monolith.

/datum/dort_controller/necromonolith
	var/obj/structure/necromantic_monolith/monolith

/datum/dort_controller/necromonolith/New(obj/structure/necromantic_monolith/M)
	..()
	if(!M || QDELETED(M))
		qdel(src)
		return
	monolith = M
	owner_ref = WEAKREF(M)
	faction_tag = M.owner_faction_tag

/datum/dort_controller/necromonolith/Destroy()
	monolith = null
	return ..()

/datum/dort_controller/necromonolith/get_managed_mobs()
	var/list/out = list()
	if(!monolith || QDELETED(monolith))
		return out
	for(var/datum/weakref/ref as anything in monolith.active_minions)
		var/mob/living/M = ref.resolve()
		if(M && !QDELETED(M) && M.stat != DEAD)
			out += M
	return out

/datum/dort_controller/necromonolith/can_virtualize(mob/living/the_mob)
	if(!the_mob || !monolith || QDELETED(monolith))
		return FALSE
	// In combat — no
	if(the_mob.ai_controller)
		if(the_mob.ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET])
			return FALSE
	// Near monolith — no
	if(get_dist(the_mob, monolith) <= safe_range)
		return FALSE
	return TRUE

/datum/dort_controller/necromonolith/capture(mob/living/the_mob)
	if(!monolith || QDELETED(monolith))
		return null
	var/mob/living/simple_animal/hostile/rogue/skeleton/S = the_mob
	if(!istype(S))
		return null
	// Find state
	var/datum/weakref/found_ref
	var/list/found_state
	for(var/datum/weakref/ref as anything in monolith.active_minions)
		if(ref.resolve() == S)
			found_ref = ref
			found_state = monolith.minion_states[ref]
			break
	if(!found_ref || !found_state)
		return null
	// Build profile
	var/datum/dort_profile/P = new()
	P.controller = src
	P.mob_type = S.type
	P.max_health = S.maxHealth
	P.current_health = S.health
	P.melee_damage_lower = S.melee_damage_lower
	P.melee_damage_upper = S.melee_damage_upper
	P.defprob = S.defprob
	P.is_ranged = S.ranged
	P.route_slot = found_state["route_slot"]
	P.route_index = found_state["route_index"]
	P.group_key = P.route_slot
	// Chase
	var/datum/weakref/chase_ref = found_state["chase_ref"]
	if(chase_ref)
		P.chase_target_ref = chase_ref
		P.chase_started_at = found_state["chase_started_at"]
		var/atom/ct = chase_ref.resolve()
		if(ct)
			var/turf/ctt = get_turf(ct)
			if(ctt)
				P.chase_target_x = ctt.x
				P.chase_target_y = ctt.y
				P.chase_target_z = ctt.z
	// Wither
	P.is_withering = S.start_take_damage
	// Position
	var/turf/mt = get_turf(S)
	if(mt)
		P.turf_x = mt.x
		P.turf_y = mt.y
		P.turf_z = mt.z
	// Remove physical mob
	monolith.unregister_minion(S)
	qdel(S)
	return P

/datum/dort_controller/necromonolith/materialize(datum/dort_profile/profile, turf/spawn_turf)
	if(!monolith || QDELETED(monolith) || !profile || !spawn_turf)
		return null
	var/mob/living/caster = monolith.owner_ref?.resolve()
	var/mob/living/simple_animal/hostile/rogue/skeleton/S = new profile.mob_type(spawn_turf, caster, TRUE, FALSE)
	if(QDELETED(S))
		return null
	monolith.apply_necromonolith_owner_data(S)
	monolith.register_minion(S, profile.route_slot)
	// Restore route position
	var/datum/weakref/new_ref = WEAKREF(S)
	var/list/state = monolith.minion_states[new_ref]
	if(state)
		state["route_index"] = profile.route_index
		if(profile.chase_target_ref)
			state["chase_ref"] = profile.chase_target_ref
			state["chase_started_at"] = profile.chase_started_at
	S.health = profile.current_health
	if(profile.is_withering)
		S.start_take_damage = TRUE
	new /obj/effect/temp_visual/bluespace_fissure(spawn_turf)
	return S

/datum/dort_controller/necromonolith/on_profile_died(datum/dort_profile/profile)
	log_dort_debug("necromonolith profile id=[profile.profile_id] [profile.mob_type] died virtual")

/datum/dort_controller/necromonolith/get_z_level()
	return (monolith && !QDELETED(monolith)) ? monolith.z : 0

/datum/dort_controller/necromonolith/get_routes()
	return (monolith && !QDELETED(monolith)) ? monolith.cached_routes : list()
