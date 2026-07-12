// Frees up any non-grab item from BOTH hands (unwielding a two-handed weapon first if
// needed) so a hand is open for a new grab. Existing /obj/item/grabbing items are left
// alone - start_pulling() on an already-pulled target adds a second, independent grab
// in the other hand rather than replacing the first (see grabbing.dm's dropped() proc,
// which explicitly keeps the pull alive "if another hand grabs the person").
/proc/ataman_free_hands_for_grabbing(datum/ai_controller/controller)
	var/mob/living/carbon/human/pawn = controller?.pawn
	if(!istype(pawn))
		return FALSE
	var/obj/item/active = pawn.get_active_held_item()
	if(active?.wielded)
		active.ungrip(pawn)
	var/datum/component/ai_inventory_manager/inventory = controller.get_inventory()
	for(var/obj/item/held in list(pawn.get_active_held_item(), pawn.get_inactive_held_item()))
		if(!held || istype(held, /obj/item/grabbing))
			continue
		if(!inventory?.stow_item(held))
			pawn.dropItemToGround(held)
	return TRUE

/proc/ataman_get_grab_on(mob/living/carbon/human/pawn, mob/living/target, sublimb)
	for(var/obj/item/grabbing/grab in list(pawn.get_active_held_item(), pawn.get_inactive_held_item()))
		if(grab.grabbed == target && grab.sublimb_grabbed == sublimb)
			return grab
	return null

/proc/ataman_make_grab_active(mob/living/carbon/human/pawn, obj/item/grabbing/grab)
	if(pawn.get_active_held_item() == grab)
		return TRUE
	if(pawn.get_inactive_held_item() != grab)
		return FALSE
	pawn.swap_hand()
	return pawn.get_active_held_item() == grab

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
			if(!ataman_free_hands_for_grabbing(controller))
				ataman_ai_log(pawn, "DISARM: couldn't free a hand for the mouth grab")
				finish_action(controller, FALSE, target_key)
				return
			pawn.zone_selected = BODY_ZONE_PRECISE_MOUTH
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

	var/grab_limb = target.get_active_held_item() ? BODY_ZONE_PRECISE_R_HAND : BODY_ZONE_PRECISE_L_HAND
	var/obj/item/grabbing/grab_item = ataman_get_grab_on(pawn, target, grab_limb)
	if(!grab_item)
		if(!ataman_free_hands_for_grabbing(controller))
			ataman_ai_log(pawn, "DISARM: couldn't free a hand to grab [target]")
			finish_action(controller, FALSE, target_key)
			return
		// find_used_grab_limb() (called inside start_pulling) reads OUR zone_selected, not
		// item_override, to decide which bodypart actually receives the grab and therefore
		// which intents (disarm included) become available - item_override alone only sets
		// the cosmetic sublimb_grabbed tag, so it silently grabbed whatever stale zone we'd
		// last aimed at (headhunting a masked caster, a prior melee swing, etc).
		pawn.zone_selected = grab_limb
		if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = grab_limb))
			ataman_ai_log(pawn, "DISARM: grab on [grab_limb] failed to start")
			finish_action(controller, FALSE, target_key)
			return
		grab_item = ataman_get_grab_on(pawn, target, grab_limb)

	// The grab item has to be the ACTIVE hand's item before update_a_intents() runs, or
	// it'll build possible_a_intents from whatever else (or nothing) is in that hand instead
	// of the grab - which is why the disarm intent kept silently failing to show up.
	if(!grab_item || !ataman_make_grab_active(pawn, grab_item))
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

	// A hand grip from disarming is kept, not released - it's a second, independent grab.
	// The free hand reinforces the hold with a torso grip alongside it (two hands, two
	// grabs on the same target), and it's the torso grip that offers the shove/takedown
	// intent, so once it exists we just keep trying the shove every tick until they fall.
	var/obj/item/grabbing/torso_grab = ataman_get_grab_on(pawn, target, BODY_ZONE_CHEST)
	if(!torso_grab)
		if(!ataman_free_hands_for_grabbing(controller))
			ataman_ai_log(pawn, "HOLD: couldn't free a hand to reinforce the grip on [target]")
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = BODY_ZONE_CHEST
		if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_CHEST))
			ataman_ai_log(pawn, "HOLD: torso grip on [target] failed to start")
			finish_action(controller, FALSE, target_key)
			return
		ataman_ai_log(pawn, "HOLD: reinforced the grip with a hold on [target]'s torso")
		torso_grab = ataman_get_grab_on(pawn, target, BODY_ZONE_CHEST)

	if(!torso_grab || !ataman_make_grab_active(pawn, torso_grab))
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
