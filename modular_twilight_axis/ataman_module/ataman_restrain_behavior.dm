/datum/ai_behavior/ataman_restrain
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_restrain/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_restrain/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target))
		finish_action(controller, FALSE, target_key)
		return
	if(!pawn.Adjacent(target) || !target.pulledby || (target.cmode && (target.mobility_flags & MOBILITY_STAND)))
		finish_action(controller, FALSE, target_key)
		return
	if(!ataman_free_hands_for_grabbing(controller))
		finish_action(controller, FALSE, target_key)
		return

	ataman_ai_log(pawn, "RESTRAIN: attempting to bind [target]")
	var/obj/item/rope/binding = new(pawn)
	if(!pawn.put_in_hands(binding))
		qdel(binding)
		finish_action(controller, FALSE, target_key)
		return
	binding.try_cuff_arms(target, pawn)
	if(QDELETED(pawn) || QDELETED(target) || QDELETED(controller) || controller.pawn != pawn)
		return
	if(!target.handcuffed && !QDELETED(binding))
		binding.try_cuff_legs(target, pawn)
	if(!target.handcuffed && !target.legcuffed && !QDELETED(binding))
		qdel(binding)
	ataman_ai_log(pawn, "RESTRAIN: result on [target] - handcuffed=[target.handcuffed ? "yes" : "no"] legcuffed=[target.legcuffed ? "yes" : "no"]")
	finish_action(controller, target.handcuffed || target.legcuffed, target_key)
