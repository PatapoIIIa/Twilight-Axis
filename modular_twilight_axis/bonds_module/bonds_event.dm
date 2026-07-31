/datum/bond_event
	abstract_type = /datum/bond_event
	var/category = BOND_CATEGORY_VIOLENCE
	var/warmth_transient = 0
	var/weight_transient = 0
	var/warmth_commit = 0
	var/weight_commit = 0
	var/timeout = 0
	var/tag_applied = BOND_TAG_NONE
	var/scored_propagation = TRUE
	var/history_label = "Событие"
	var/datum/social_bond/bond
	var/timer_id
	var/started_at = 0
	var/applied_scale = 1

/datum/bond_event/Destroy(force)
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	bond = null
	return ..()

/datum/bond_event/proc/start()
	started_at = world.time
	if(timeout <= 0)
		return
	timer_id = addtimer(CALLBACK(src, PROC_REF(expire)), timeout, TIMER_STOPPABLE)

/datum/bond_event/proc/refresh()
	started_at = world.time
	if(timeout <= 0)
		return
	if(timer_id)
		deltimer(timer_id)
	timer_id = addtimer(CALLBACK(src, PROC_REF(expire)), timeout, TIMER_STOPPABLE)

/datum/bond_event/proc/expire()
	timer_id = null
	var/datum/social_bond/owner_bond = bond
	bond = null
	if(owner_bond)
		owner_bond.detach_event(src)
	qdel(src)

/datum/bond_event/proc/build_story(datum/social_bond/context)
	return "[context.display_name()]."

/datum/bond_event/proc/can_apply(datum/mind/subject, datum/mind/object)
	return TRUE
