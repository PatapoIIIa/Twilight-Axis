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
	ataman_ai_log(pawn, "CAPTURE: lost track of [restored] on the blackboard, recovering")
	controller.set_blackboard_key(BB_ATAMAN_TARGET, restored)

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

/datum/ataman_squad
	var/datum/weakref/target_ref
	var/feints_used = 0
	var/last_feint_at = 0
	var/mouth_grab_claimed = FALSE
	var/guard_claimed_until = 0
	var/bites_used = 0
	var/gear_tier = 1

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

/datum/ataman_squad/proc/claim_mouth_grab()
	if(mouth_grab_claimed)
		return FALSE
	mouth_grab_claimed = TRUE
	return TRUE

/datum/ataman_squad/proc/claim_guard(duration = 2 SECONDS)
	if(world.time < guard_claimed_until)
		return FALSE
	guard_claimed_until = world.time + duration
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
