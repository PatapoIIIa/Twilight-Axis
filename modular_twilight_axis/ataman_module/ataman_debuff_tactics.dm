/proc/ataman_target_sees(mob/living/pawn, mob/living/target)
	if(!istype(target) || !target.mind)
		return TRUE
	if(!target.get_tempo_bonus(TEMPO_TAG_FEINTBAIT_FOV))
		return TRUE
	return target.can_see_cone(pawn)

/proc/ataman_target_baited(mob/living/target)
	return istype(target) && target.has_status_effect(/datum/status_effect/debuff/baited)

/proc/ataman_target_under_debuff(mob/living/target)
	return ataman_last_feint_landed(target) || ataman_target_baited(target)

/proc/ataman_try_bait(datum/ai_controller/controller, mob/living/carbon/human/pawn, mob/living/carbon/human/target, datum/ataman_squad/squad)
	if(!ishuman(pawn) || !ishuman(target) || !squad)
		return FALSE
	if(pawn.has_status_effect(/datum/status_effect/debuff/baitcd) || ataman_target_baited(target))
		return FALSE
	var/zone = squad.get_aim_zone()
	if(!zone)
		return FALSE
	if(!squad.claim_aim(pawn))
		return FALSE
	pawn.swap_rmb_intent(type = /datum/rmb_intent/aimed)
	if(!istype(pawn.rmb_intent, /datum/rmb_intent/aimed))
		return FALSE
	pawn.zone_selected = zone
	ataman_ai_log(pawn, "AIM: baiting [target] on [zone]")
	if(!controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE)))
		return FALSE
	if(QDELETED(pawn) || QDELETED(target))
		return TRUE
	if(ataman_target_baited(target))
		ataman_ai_log(pawn, "AIM: bait landed on [target] - they are exposed")
		return TRUE
	ataman_ai_log(pawn, "AIM: bait missed on [target] - dropping the whole debuff chain until they commit to a hit")
	squad.hold_aim_chain()
	return TRUE

/proc/ataman_try_feint(datum/ai_controller/controller, mob/living/carbon/human/pawn, mob/living/target, datum/ataman_squad/squad, emergency = FALSE)
	if(!istype(pawn) || !istype(target) || !squad)
		return FALSE
	if(!emergency && target.has_status_effect(/datum/status_effect/debuff/feinted))
		return FALSE
	if(!ataman_target_sees(pawn, target))
		ataman_ai_log(pawn, "FEINT: [target] cannot see me, a feint would be wasted")
		return FALSE
	if(!squad.consider_feint(pawn, target, emergency))
		return FALSE
	pawn.swap_rmb_intent(type = /datum/rmb_intent/feint)
	if(!istype(pawn.rmb_intent, /datum/rmb_intent/feint))
		return FALSE
	if(!controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE)))
		return FALSE
	squad.register_feint()
	ataman_ai_log(pawn, "FEINT: staged feint #[squad.feints_used] on [target][emergency ? " (emergency, they are casting an escape)" : ""]")
	return TRUE

/proc/ataman_try_bite(datum/ai_controller/controller, mob/living/carbon/human/pawn, mob/living/carbon/target, datum/ataman_squad/squad)
	if(!istype(pawn) || !istype(target) || !squad)
		return FALSE
	if(pawn.pulling == target || squad.bites_used >= 2)
		return FALSE
	if(!ataman_last_feint_landed(target))
		return FALSE
	var/zone = squad.get_aim_zone()
	if(!zone || !check_face_subzone(zone))
		zone = BODY_ZONE_PRECISE_L_EYE
	if(!get_location_accessible(target, zone))
		return FALSE
	squad.bites_used++
	pawn.zone_selected = zone
	ataman_ai_log(pawn, "BITE: [target] is debuffed and open - taking bite #[squad.bites_used] at [zone]")
	target.onbite(pawn)
	return TRUE

/datum/ai_planning_subtree/ataman_squad_tactics/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/npc/ataman_bandit/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(!squad)
		return
	ataman_recover_target(controller, pawn)
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(target) || target.stat == DEAD || ataman_target_is_secured(target))
		return
	squad.refresh_aim_intel(target)
	if(!pawn.Adjacent(target))
		return

	var/role = controller.blackboard[BB_ATAMAN_ROLE]
	if(role != ATAMAN_ROLE_GRABBER && ishuman(target) && target.stat == CONSCIOUS)
		var/capture_zone = ataman_pick_capture_zone(pawn, target)
		if(capture_zone)
			controller.set_blackboard_key(BB_HUMAN_NPC_WEAKPOINT, list(capture_zone, world.time + 3 SECONDS, target))

	if(world.time < (controller.blackboard[BB_ATAMAN_TACTICS_COOLDOWN] || 0))
		return

	if(squad.target_channeling_escape_spell())
		if(ataman_try_feint(controller, pawn, target, squad, TRUE))
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(role == ATAMAN_ROLE_ENFORCER && pawn.pulling != target && (pawn.mobility_flags & MOBILITY_STAND) && !pawn.IsOffBalanced() && pawn.get_num_legs() >= 2 && (target.mobility_flags & MOBILITY_STAND))
		var/walled_kick = length(target.grabbedby) >= 2 && ataman_target_is_walled(pawn, target)
		if(walled_kick || target.IsOffBalanced())
			ataman_ai_log(pawn, "TACTICS: kicking [target] ([walled_kick ? "held and walled" : "off balance"])")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			controller.queue_behavior(/datum/ai_behavior/npc_kick_attack/ataman_low, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

	if(role == ATAMAN_ROLE_BINDER && squad.is_target_caster(target) && ataman_try_mouth_grab(controller, pawn, target, squad))
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(squad.target_channeling_spell())
		if(!pawn.has_status_effect(/datum/status_effect/buff/clash) && squad.claim_guard())
			ataman_ai_log(pawn, "TACTICS: [target] is casting - guarding")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			pawn.try_guard()
		return SUBTREE_RETURN_FINISH_PLANNING

	if(role == ATAMAN_ROLE_ENFORCER && ataman_try_bite(controller, pawn, target, squad))
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(ataman_target_under_debuff(target))
		return

	if(ataman_try_bait(controller, pawn, target, squad))
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(ataman_try_feint(controller, pawn, target, squad))
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	return
