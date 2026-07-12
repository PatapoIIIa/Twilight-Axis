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
	// If a mask blocks the mouth, batter the head instead until they go down, then just grab them.
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(squad?.is_target_caster(target) && !ataman_target_mouth_secured(target))
		if(!get_location_accessible(target, BODY_ZONE_PRECISE_MOUTH))
			if(target.mobility_flags & MOBILITY_STAND)
				ataman_ai_log(pawn, "DISARM: [target] is a masked caster, headhunting instead of grabbing")
				controller.set_blackboard_key(BB_HUMAN_NPC_WEAKPOINT, list(BODY_ZONE_HEAD, world.time + 2 SECONDS, target))
				finish_action(controller, FALSE, target_key)
				return
		else if(pawn.pulling == target)
			finish_action(controller, TRUE, target_key)
			return
		else if(squad.claim_mouth_grab())
			ataman_ai_log(pawn, "DISARM: [target] is a caster, going for the mouth")
			if(!ataman_prepare_capture_hand(controller))
				ataman_ai_log(pawn, "DISARM: couldn't free a hand for the mouth grab")
				finish_action(controller, FALSE, target_key)
				return
			if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_PRECISE_MOUTH))
				ataman_ai_log(pawn, "DISARM: mouth grab failed to start")
				finish_action(controller, FALSE, target_key)
				return
			ataman_ai_log(pawn, "DISARM: mouth secured on [target]")
			finish_action(controller, TRUE, target_key)
			return

	var/obj/item/armed_hand = target.get_active_held_item() || target.get_inactive_held_item()
	if(!armed_hand)
		ataman_ai_log(pawn, "DISARM: [target] already unarmed, nothing to do")
		finish_action(controller, TRUE, target_key)
		return
	if(pawn.pulling != target && !ataman_prepare_capture_hand(controller))
		ataman_ai_log(pawn, "DISARM: couldn't free a hand to grab [target]")
		finish_action(controller, FALSE, target_key)
		return

	var/grab_limb = target.get_active_held_item() ? BODY_ZONE_PRECISE_R_HAND : BODY_ZONE_PRECISE_L_HAND
	if(pawn.pulling != target && !pawn.start_pulling(target, GRAB_PASSIVE, item_override = grab_limb))
		ataman_ai_log(pawn, "DISARM: grab on [grab_limb] failed to start")
		finish_action(controller, FALSE, target_key)
		return

	// The grab item has to be the ACTIVE hand's item before update_a_intents() runs, or
	// it'll build possible_a_intents from whatever else (or nothing) is in that hand instead
	// of the grab - which is why the disarm intent kept silently failing to show up.
	var/obj/item/grabbing/grab_item
	if(istype(pawn.get_active_held_item(), /obj/item/grabbing))
		grab_item = pawn.get_active_held_item()
	else if(istype(pawn.get_inactive_held_item(), /obj/item/grabbing))
		pawn.swap_hand()
		grab_item = pawn.get_active_held_item()
	if(!grab_item)
		ataman_ai_log(pawn, "DISARM: grab on [target] was lost before it could be used")
		finish_action(controller, FALSE, target_key)
		return

	pawn.update_a_intents()

	var/datum/intent/grab/disarm/disarm_intent
	for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
		if(istype(candidate, /datum/intent/grab/disarm))
			disarm_intent = candidate
			break

	if(!disarm_intent)
		ataman_ai_log(pawn, "DISARM: no disarm intent even with grab active (active=[pawn.get_active_held_item()])")
		finish_action(controller, FALSE, target_key)
		return

	ataman_ai_log(pawn, "DISARM: attempting disarm on [target] ([armed_hand])")
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
			ataman_ai_log(pawn, "HOLD: couldn't free a hand to grab [target]")
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = BODY_ZONE_CHEST
		if(!pawn.start_pulling(target, GRAB_PASSIVE))
			ataman_ai_log(pawn, "HOLD: grab on [target] failed to start")
			finish_action(controller, FALSE, target_key)
			return
		ataman_ai_log(pawn, "HOLD: grabbed [target]")

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
			ataman_ai_log(pawn, "HOLD: shoving [target]")
			pawn.a_intent = shove_intent
			pawn.used_intent = shove_intent
			controller.ai_interact(target, TRUE, TRUE)
	finish_action(controller, TRUE, target_key)
