/datum/ai_planning_subtree/ataman_leash/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/turf/spawn_turf = controller.blackboard[BB_ATAMAN_SPAWN_TURF]
	if(!spawn_turf)
		return
	var/mob/living/pawn = controller.pawn
	if(get_dist(pawn, spawn_turf) <= ATAMAN_LEASH_RANGE)
		return
	var/atom/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(pawn.pulling == target)
		pawn.stop_pulling()
	pawn.cmode = FALSE
	controller.clear_blackboard_key(BB_ATAMAN_TARGET)
	controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
	controller.current_movement_target = null
	return SUBTREE_RETURN_FINISH_PLANNING
