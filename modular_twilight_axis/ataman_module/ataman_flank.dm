/proc/ataman_flank_angle_of(turf/origin, turf/point)
	if(!origin || !point)
		return null
	var/dx = point.x - origin.x
	var/dy = point.y - origin.y
	if(!dx && !dy)
		return null
	return (arctan(dx, dy) + 360) % 360

/proc/ataman_flank_angle_delta(first_angle, second_angle)
	if(isnull(first_angle) || isnull(second_angle))
		return null
	var/delta = abs(first_angle - second_angle) % 360
	return delta > 180 ? 360 - delta : delta

/proc/ataman_flank_pick_angle(list/angles)
	if(!length(angles))
		return null
	var/list/sorted = sortTim(angles.Copy(), cmp = /proc/cmp_numeric_asc)
	if(length(sorted) == 1)
		return (sorted[1] + 180) % 360
	var/largest_gap = 0
	var/gap_start = sorted[1]
	for(var/i in 1 to length(sorted))
		var/next_index = (i % length(sorted)) + 1
		var/gap = (sorted[next_index] - sorted[i] + 360) % 360
		if(gap > largest_gap)
			largest_gap = gap
			gap_start = sorted[i]
	if(!largest_gap)
		return (sorted[1] + 180) % 360
	if(largest_gap < ATAMAN_FLANK_MIN_SEPARATION)
		return null
	return (gap_start + round(largest_gap / 2)) % 360

/proc/ataman_flank_turf_for(turf/target_turf, angle, mob/living/pawn)
	if(!target_turf || isnull(angle))
		return null
	var/turf/best_turf
	var/best_delta = 361
	for(var/turf/candidate as anything in RANGE_TURFS(ATAMAN_FLANK_RADIUS, target_turf))
		if(candidate == target_turf || candidate.density)
			continue
		if(pawn && !candidate.can_traverse_safely(pawn))
			continue
		var/candidate_angle = ataman_flank_angle_of(target_turf, candidate)
		if(isnull(candidate_angle))
			continue
		var/delta = ataman_flank_angle_delta(candidate_angle, angle)
		if(delta < best_delta)
			best_delta = delta
			best_turf = candidate
	return best_turf

/proc/ataman_flank_clear(datum/ai_controller/controller)
	if(!controller)
		return
	controller.clear_blackboard_key(BB_ATAMAN_FLANK_ANGLE)
	controller.clear_blackboard_key(BB_ATAMAN_FLANK_TURF)

/datum/ai_planning_subtree/ataman_squad_flank

/datum/ai_planning_subtree/ataman_squad_flank/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/npc/ataman_bandit/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	var/mob/living/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!squad || !istype(target) || target.stat == DEAD || ataman_target_is_secured(target))
		ataman_flank_clear(controller)
		return
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		ataman_flank_clear(controller)
		return

	var/chosen_angle = ataman_flank_pick_angle(squad.get_flank_angles(pawn, target_turf))
	if(isnull(chosen_angle))
		ataman_flank_clear(controller)
		return

	var/cached_angle = controller.blackboard[BB_ATAMAN_FLANK_ANGLE]
	var/turf/flank_turf = controller.blackboard[BB_ATAMAN_FLANK_TURF]
	if(isnull(cached_angle) || !flank_turf || get_dist(flank_turf, target_turf) > ATAMAN_FLANK_RADIUS || ataman_flank_angle_delta(cached_angle, chosen_angle) > ATAMAN_FLANK_ANGLE_DRIFT)
		flank_turf = ataman_flank_turf_for(target_turf, chosen_angle, pawn)
		if(!flank_turf)
			ataman_flank_clear(controller)
			return
		controller.set_blackboard_key(BB_ATAMAN_FLANK_ANGLE, chosen_angle)
		controller.set_blackboard_key(BB_ATAMAN_FLANK_TURF, flank_turf)
		ataman_ai_log(pawn, "FLANK: taking the open side on [target] at [chosen_angle] degrees")

	if(get_dist(pawn, flank_turf) <= ATAMAN_FLANK_ENGAGE_DIST)
		return

	controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_ATAMAN_FLANK_TURF)
	return SUBTREE_RETURN_FINISH_PLANNING
