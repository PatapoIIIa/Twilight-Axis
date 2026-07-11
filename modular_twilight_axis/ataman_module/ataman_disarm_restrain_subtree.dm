/datum/ai_planning_subtree/ataman_disarm_restrain/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/mob/living/carbon/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!istype(target) || target.stat == DEAD)
		return
	if(!pawn.Adjacent(target))
		return

	if(target.handcuffed)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(target.get_active_held_item() || target.get_inactive_held_item())
		controller.queue_behavior(/datum/ai_behavior/ataman_disarm, BB_BASIC_MOB_CURRENT_TARGET)
	else
		controller.queue_behavior(/datum/ai_behavior/ataman_restrain, BB_BASIC_MOB_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING
