/datum/ai_planning_subtree/ataman_disarm_restrain/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(pawn) || !istype(target) || target.stat == DEAD)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(ataman_target_is_secured(target))
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
		if(pawn.pulling == target)
			pawn.stop_pulling()
		pawn.cmode = FALSE
		return SUBTREE_RETURN_FINISH_PLANNING

	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, target)
	var/role = controller.blackboard[BB_ATAMAN_ROLE]
	var/target_is_armed = target.get_active_held_item() || target.get_inactive_held_item()

	switch(role)
		if(ATAMAN_ROLE_GRABBER)
			if(target_is_armed)
				controller.queue_behavior(/datum/ai_behavior/ataman_disarm, BB_ATAMAN_TARGET)
			else
				controller.queue_behavior(/datum/ai_behavior/ataman_hold, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_BINDER)
			if(target_is_armed || !target.pulledby || (target.cmode && (target.mobility_flags & MOBILITY_STAND)))
				return SUBTREE_RETURN_FINISH_PLANNING
			controller.queue_behavior(/datum/ai_behavior/ataman_restrain, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_ENFORCER)
			if(!target_is_armed || target.pulledby || !(target.mobility_flags & MOBILITY_STAND))
				return SUBTREE_RETURN_FINISH_PLANNING

	return
