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
	if(!istype(pawn) || !istype(target) || QDELETED(target))
		finish_action(controller, FALSE, target_key)
		return
	if(!pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return
	if(target.handcuffed)
		finish_action(controller, TRUE, target_key)
		return

	var/obj/item/rope/binding = new(pawn)
	pawn.put_in_hands(binding)
	binding.try_cuff_arms(target, pawn)
	if(QDELETED(pawn) || QDELETED(target) || QDELETED(controller) || controller.pawn != pawn)
		return
	if(!target.handcuffed && !QDELETED(binding))
		binding.try_cuff_legs(target, pawn)
	finish_action(controller, TRUE, target_key)
