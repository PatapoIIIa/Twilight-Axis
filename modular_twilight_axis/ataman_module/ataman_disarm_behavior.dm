/proc/ataman_prepare_capture_hand(datum/ai_controller/controller, preserve_grab = FALSE)
	var/mob/living/carbon/human/pawn = controller?.pawn
	if(!istype(pawn))
		return FALSE
	var/obj/item/active = pawn.get_active_held_item()
	if(active?.wielded)
		active.ungrip(pawn)
		active = pawn.get_active_held_item()
	if(!active || (preserve_grab && istype(active, /obj/item/grabbing)))
		return TRUE
	var/datum/component/ai_inventory_manager/inventory = controller.get_inventory()
	if(!inventory?.stow_item(active))
		pawn.dropItemToGround(active)
	return !pawn.get_active_held_item()

/datum/ai_behavior/ataman_disarm
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_disarm/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_disarm/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target))
		finish_action(controller, FALSE, target_key)
		return
	if(!pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return

	// Casters get their mouth stopped before anything else - it silences their spells outright.
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(squad?.is_target_caster(target) && !ataman_target_mouth_secured(target))
		if(pawn.pulling == target)
			finish_action(controller, TRUE, target_key)
			return
		if(squad.claim_mouth_grab())
			if(!ataman_prepare_capture_hand(controller))
				finish_action(controller, FALSE, target_key)
				return
			if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_PRECISE_MOUTH))
				finish_action(controller, FALSE, target_key)
				return
			finish_action(controller, TRUE, target_key)
			return

	var/obj/item/armed_hand = target.get_active_held_item() || target.get_inactive_held_item()
	if(!armed_hand)
		finish_action(controller, TRUE, target_key)
		return
	if(pawn.pulling != target && !ataman_prepare_capture_hand(controller))
		finish_action(controller, FALSE, target_key)
		return

	var/grab_limb = target.get_active_held_item() ? BODY_ZONE_PRECISE_R_HAND : BODY_ZONE_PRECISE_L_HAND
	if(pawn.pulling != target && !pawn.start_pulling(target, GRAB_PASSIVE, item_override = grab_limb))
		finish_action(controller, FALSE, target_key)
		return
	pawn.update_a_intents()

	var/datum/intent/grab/disarm/disarm_intent
	for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
		if(istype(candidate, /datum/intent/grab/disarm))
			disarm_intent = candidate
			break

	if(!disarm_intent)
		finish_action(controller, FALSE, target_key)
		return

	var/obj/item/grabbing/grab_item
	if(istype(pawn.get_active_held_item(), /obj/item/grabbing))
		grab_item = pawn.get_active_held_item()
	else if(istype(pawn.get_inactive_held_item(), /obj/item/grabbing))
		grab_item = pawn.get_inactive_held_item()
		pawn.swap_hand()
	if(!grab_item)
		finish_action(controller, FALSE, target_key)
		return

	pawn.a_intent = disarm_intent
	pawn.used_intent = disarm_intent
	controller.ai_interact(target, TRUE, TRUE)
	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/ataman_hold
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_hold/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_hold/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target) || !pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return

	if(pawn.pulling != target)
		if(!ataman_prepare_capture_hand(controller))
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = BODY_ZONE_CHEST
		if(!pawn.start_pulling(target, GRAB_PASSIVE))
			finish_action(controller, FALSE, target_key)
			return

	var/obj/item/grabbing/grab_item
	if(istype(pawn.get_active_held_item(), /obj/item/grabbing))
		grab_item = pawn.get_active_held_item()
	else if(istype(pawn.get_inactive_held_item(), /obj/item/grabbing))
		grab_item = pawn.get_inactive_held_item()
		pawn.swap_hand()
	if(!grab_item)
		finish_action(controller, FALSE, target_key)
		return

	if(target.mobility_flags & MOBILITY_STAND)
		pawn.update_a_intents()
		var/datum/intent/grab/shove/shove_intent
		for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
			if(istype(candidate, /datum/intent/grab/shove))
				shove_intent = candidate
				break
		if(shove_intent)
			pawn.a_intent = shove_intent
			pawn.used_intent = shove_intent
			controller.ai_interact(target, TRUE, TRUE)
	finish_action(controller, TRUE, target_key)
