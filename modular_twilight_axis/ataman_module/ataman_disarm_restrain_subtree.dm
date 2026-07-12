/datum/ai_planning_subtree/ataman_disarm_restrain/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(pawn) || !istype(target) || target.stat == DEAD)
		ataman_ai_log(pawn, "CAPTURE: target [target] gone/dead, clearing")
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(ataman_target_is_secured(target))
		ataman_ai_log(pawn, "CAPTURE: [target] is secured, standing down")
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
				ataman_ai_log(pawn, "CAPTURE: grabber -> disarm (target armed)")
				controller.queue_behavior(/datum/ai_behavior/ataman_disarm, BB_ATAMAN_TARGET)
			else
				ataman_ai_log(pawn, "CAPTURE: grabber -> hold (target unarmed)")
				controller.queue_behavior(/datum/ai_behavior/ataman_hold, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_BINDER)
			// Wait for the target to be grabbed and knocked down before moving in to bind them.
			// Not ready yet? No point standing around - fall through to the generic melee
			// subtree below and keep hitting them meanwhile.
			if(target_is_armed || !target.pulledby || (target.mobility_flags & MOBILITY_STAND))
				ataman_ai_log(pawn, "CAPTURE: binder not ready (armed=[target_is_armed ? "yes" : "no"] pulledby=[target.pulledby] standing=[(target.mobility_flags & MOBILITY_STAND) ? "yes" : "no"]) - falling back to attacking")
				return
			ataman_ai_log(pawn, "CAPTURE: binder -> restrain")
			controller.queue_behavior(/datum/ai_behavior/ataman_restrain, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_ENFORCER)
			if(!target_is_armed || target.pulledby || !(target.mobility_flags & MOBILITY_STAND))
				// Nothing role-specific to do right now (kick/bite/feint already had first
				// refusal in ataman_squad_tactics) - fall back to plain attacking so no one
				// is ever just standing around doing nothing.
				return

	return
