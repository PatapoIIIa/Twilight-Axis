/datum/controller/subsystem/bonds/proc/influence_state(datum/bond_actor/actor)
	if(!actor)
		return null
	var/list/state = influence_pools[actor]
	if(!state)
		state = list("left" = BOND_INFLUENCE_POOL, "refill" = world.time + BOND_INFLUENCE_REFILL, "banned_until" = 0)
		influence_pools[actor] = state
	return state

/datum/controller/subsystem/bonds/proc/spend_influence(datum/bond_actor/actor)
	var/list/state = influence_state(actor)
	if(!state)
		return FALSE

	if(world.time >= state["refill"])
		state["left"] = BOND_INFLUENCE_POOL
		state["refill"] = world.time + BOND_INFLUENCE_REFILL
		state["banned_until"] = 0

	if(state["banned_until"] && world.time < state["banned_until"])
		return FALSE

	if(state["left"] <= 0)
		state["banned_until"] = world.time + BOND_INFLUENCE_BAN
		bondlog("[actor.name_of()] exhausted their influence pool; muted for [BOND_INFLUENCE_BAN / 10]s", BONDLOG_INFO)
		return FALSE

	state["left"]--
	return TRUE

/datum/controller/subsystem/bonds/proc/influence_left(participant)
	var/list/state = influence_pools[resolve_actor(participant)]
	if(!state)
		return BOND_INFLUENCE_POOL
	return state["left"]

/datum/controller/subsystem/bonds/proc/influence_muted(participant)
	var/list/state = influence_pools[resolve_actor(participant)]
	if(!state)
		return FALSE
	return state["banned_until"] && world.time < state["banned_until"]
