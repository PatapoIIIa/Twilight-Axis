/proc/ataman_last_feint_landed(mob/living/target)
	if(!istype(target))
		return FALSE
	return target.has_status_effect(/datum/status_effect/debuff/vulnerable) || target.has_status_effect(/datum/status_effect/debuff/exposed)

/proc/ataman_target_mouth_secured(mob/living/carbon/target)
	if(!istype(target))
		return FALSE
	for(var/obj/item/grabbing/grab in target.grabbedby)
		if(grab.sublimb_grabbed == BODY_ZONE_PRECISE_MOUTH)
			return TRUE
	return FALSE

/proc/ataman_recover_target(datum/ai_controller/controller, mob/living/carbon/human/npc/ataman_bandit/pawn)
	if(!istype(pawn) || !controller)
		return
	if(istype(controller.blackboard[BB_ATAMAN_TARGET], /mob/living))
		return
	var/mob/living/restored = pawn.ataman_target_ref?.resolve()
	if(!istype(restored) || restored.stat == DEAD)
		return
	if(pawn.ataman_gave_up)
		var/turf/spawn_turf = controller.blackboard[BB_ATAMAN_SPAWN_TURF]
		if(!spawn_turf || get_dist(restored, spawn_turf) > ATAMAN_LEASH_RANGE)
			return
		pawn.ataman_gave_up = FALSE
	ataman_ai_log(pawn, "CAPTURE: lost track of [restored] on the blackboard, recovering")
	controller.set_blackboard_key(BB_ATAMAN_TARGET, restored)

/proc/ataman_disband(datum/ai_controller/controller, mob/living/carbon/human/npc/ataman_bandit/pawn)
	if(!istype(pawn) || pawn.ataman_disbanding || pawn.stat == DEAD)
		return
	pawn.ataman_disbanding = TRUE
	if(pawn.pulling)
		pawn.stop_pulling()
	pawn.cmode = FALSE
	controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
	ataman_ai_log(pawn, "DISBAND: job's done, heading home to scatter and fade")
	var/turf/home_turf = controller.blackboard[BB_ATAMAN_SPAWN_TURF] || get_turf(pawn)
	var/travel_time = 0
	if(home_turf)
		var/list/candidates = list()
		for(var/turf/candidate as anything in RANGE_TURFS(3, home_turf))
			if(isopenturf(candidate) && !candidate.is_blocked_turf(exclude_mobs = TRUE))
				candidates += candidate
		if(length(candidates))
			var/turf/flee_turf = pick(candidates)
			controller.set_blackboard_key(BB_ATAMAN_FLEE_TURF, flee_turf)
			controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_ATAMAN_FLEE_TURF)
			travel_time = clamp(get_dist(pawn, flee_turf) SECONDS, 2 SECONDS, 15 SECONDS)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ataman_finish_disband), pawn), travel_time + rand(2 SECONDS, 4 SECONDS))

/proc/ataman_finish_disband(mob/living/carbon/human/npc/ataman_bandit/pawn)
	if(QDELETED(pawn) || pawn.stat == DEAD)
		return
	pawn.visible_message(span_warning("[pawn] slips away and fades into nothing."))
	pawn.death(FALSE)

/proc/ataman_weapon_is_blunt(obj/item/weapon)
	return !weapon || weapon.d_type == "blunt"

/proc/ataman_zone_is_armored(mob/living/carbon/human/target, zone)
	return target.getarmor(zone, "blunt") > 0

/proc/ataman_chest_broken(mob/living/carbon/human/target)
	return target.has_wound(/datum/wound/fracture/chest)

/proc/ataman_pick_capture_zone(mob/living/carbon/human/pawn, mob/living/carbon/human/target)
	var/list/limbs = shuffle(list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	if(ataman_weapon_is_blunt(pawn.get_active_held_item()))
		for(var/zone in limbs)
			if(!ataman_zone_is_armored(target, zone))
				return zone
		if(!ataman_chest_broken(target) && !ataman_zone_is_armored(target, BODY_ZONE_CHEST))
			return BODY_ZONE_CHEST
		return limbs[1]
	for(var/zone in limbs)
		if(ataman_zone_is_armored(target, zone))
			return zone
	if(!ataman_chest_broken(target) && ataman_zone_is_armored(target, BODY_ZONE_CHEST))
		return BODY_ZONE_CHEST
	return null

/proc/ataman_target_is_walled(mob/living/pawn, mob/living/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE
	var/turf/behind_target = get_step(target_turf, get_dir(pawn, target))
	if(!behind_target || behind_target.density)
		return TRUE
	for(var/obj/structure/S in behind_target)
		if(S.density)
			return TRUE
	for(var/mob/living/M in behind_target)
		if(M == pawn || M == target)
			continue
		return TRUE
	return FALSE

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

/proc/ataman_try_mouth_grab(datum/ai_controller/controller, mob/living/carbon/human/pawn, mob/living/carbon/target, datum/ataman_squad/squad)
	if(!squad || pawn.pulling == target || ataman_target_mouth_secured(target))
		return FALSE
	if(!get_location_accessible(target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!squad.claim_mouth_grab(target))
		return FALSE
	if(!ataman_free_hands_for_grabbing(controller))
		return FALSE
	pawn.zone_selected = BODY_ZONE_PRECISE_MOUTH
	if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_PRECISE_MOUTH))
		ataman_ai_log(pawn, "MOUTH: grab on [target] failed to start")
		return FALSE
	ataman_ai_log(pawn, "MOUTH: secured [target]'s mouth")
	return TRUE

/datum/ataman_squad
	var/datum/weakref/target_ref
	var/feints_used = 0
	var/last_feint_at = 0
	var/mouth_claim_until = 0
	var/guard_claimed_until = 0
	var/bites_used = 0
	var/gear_tier = 1
	var/datum/weakref/holder_ref
	var/owner_took_custody = FALSE
	var/turf/last_target_turf
	var/last_target_check = 0
	var/intercept_dir = 0
	var/datum/weakref/interceptor_ref

/datum/ataman_squad/proc/get_target()
	return target_ref?.resolve()

/datum/ataman_squad/proc/is_target_caster(mob/living/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/H = target
	return H.get_skill_level(/datum/skill/magic/arcane) > SKILL_LEVEL_NONE || H.get_skill_level(/datum/skill/magic/holy) > SKILL_LEVEL_NONE

/datum/ataman_squad/proc/target_channeling_spell()
	var/mob/living/target = get_target()
	if(!istype(target))
		return FALSE
	var/datum/action/cooldown/spell/casting = target.channeling_spell
	return istype(casting) && (casting.currently_charging || casting.charged)

/datum/ataman_squad/proc/target_channeling_escape_spell()
	if(!target_channeling_spell())
		return FALSE
	var/mob/living/target = get_target()
	var/datum/action/cooldown/spell/casting = target.channeling_spell
	return casting.spell_color == GLOW_COLOR_DISPLACEMENT

/datum/ataman_squad/proc/claim_mouth_grab(mob/living/carbon/target)
	if(istype(target) && ataman_target_mouth_secured(target))
		return FALSE
	if(world.time < mouth_claim_until)
		return FALSE
	mouth_claim_until = world.time + 8 SECONDS
	return TRUE

/datum/ataman_squad/proc/claim_guard(duration = 2 SECONDS)
	if(world.time < guard_claimed_until)
		return FALSE
	guard_claimed_until = world.time + duration
	return TRUE

/datum/ataman_squad/proc/claim_holder(mob/living/bandit)
	var/mob/living/holder = holder_ref?.resolve()
	if(holder == bandit)
		return TRUE
	if(istype(holder) && !QDELETED(holder) && holder.stat != DEAD)
		return FALSE
	holder_ref = WEAKREF(bandit)
	return TRUE

/datum/ataman_squad/proc/consider_feint(mob/living/carbon/human/attacker, mob/living/target, emergency = FALSE)
	if(!istype(attacker) || attacker.has_status_effect(/datum/status_effect/debuff/feintcd))
		return FALSE
	if(!istype(attacker.rmb_intent, /datum/rmb_intent/feint))
		return FALSE
	if(emergency)
		return TRUE
	if(feints_used == 0)
		return TRUE
	if(feints_used == 1)
		return world.time >= last_feint_at + 1 SECONDS
	return is_target_caster(target) || !ataman_last_feint_landed(target)

/datum/ataman_squad/proc/register_feint()
	feints_used++
	last_feint_at = world.time

/datum/ataman_squad/proc/claim_interceptor(mob/living/bandit)
	var/mob/living/current = interceptor_ref?.resolve()
	if(current == bandit)
		return TRUE
	if(istype(current) && !QDELETED(current) && current.stat != DEAD)
		return FALSE
	interceptor_ref = WEAKREF(bandit)
	return TRUE

/datum/ataman_squad/proc/release_interceptor(mob/living/bandit)
	if(interceptor_ref?.resolve() == bandit)
		interceptor_ref = null

/datum/ataman_squad/proc/get_intercept_point()
	var/mob/living/target = get_target()
	if(!istype(target))
		return null
	var/turf/current_turf = get_turf(target)
	if(!current_turf)
		return null
	if(world.time >= last_target_check + 2 SECONDS)
		if(last_target_turf && last_target_turf != current_turf)
			intercept_dir = get_dir(last_target_turf, current_turf)
		last_target_turf = current_turf
		last_target_check = world.time
	if(!intercept_dir)
		return null
	var/turf/ahead = current_turf
	for(var/i in 1 to 6)
		var/turf/next_turf = get_step(ahead, intercept_dir)
		if(!next_turf || next_turf.density)
			break
		ahead = next_turf
	if(ahead == current_turf)
		return null
	return ahead
