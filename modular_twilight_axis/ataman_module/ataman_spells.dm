/datum/action/cooldown/spell/ataman_ambush
	name = "Set an Ambush"
	desc = "Spend seven undisturbed seconds placing a hidden ambush trigger. The first intruder to disturb it will be surrounded by my bandits. I can maintain no more than three ambushes at once."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_MINOR_SUMMON
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 3 MINUTES
	cast_range = 1
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_ambush/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	if(ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		if(feedback)
			H.balloon_alert(H, "three ambushes already set!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_ambush/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf || target_turf.density)
		return FALSE
	if(istype(target_turf, /turf/open/transparent/openspace))
		return FALSE
	if(ataman_turf_has_trap(target_turf))
		owner.balloon_alert(owner, "another trap is already here!")
		return FALSE
	var/area/rogue/place = get_area(target_turf)
	if(istype(place) && (place.town_area || place.keep_area))
		owner.balloon_alert(owner, "I cannot set an ambush here!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(owner, target_turf)
	if(spot_error)
		owner.balloon_alert(owner, spot_error)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		owner.balloon_alert(owner, "three ambushes already set!")
		return FALSE
	if(ataman_too_close_to_own(H, target_turf, H.ataman_active_ambushes, ATAMAN_TRAP_MIN_SPACING))
		owner.balloon_alert(owner, "too close to my other ambush!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_ambush/cast(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || ataman_turf_has_trap(target_turf))
		H.balloon_alert(H, "another trap is already here!")
		return FALSE
	if(ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		H.balloon_alert(H, "three ambushes already set!")
		return FALSE

	var/list/disguises = list(
		"Stone" = list("stone", "A piece of rough ground stone.", 'icons/roguetown/items/natural.dmi', "stone1"),
		"Clod of Earth" = list("clod", "A handful of earth.", 'icons/roguetown/items/natural.dmi', "clod1"),
		"Stick" = list("stick", "A tree branch perhaps.", 'icons/roguetown/items/natural.dmi', "stick1"),
	)
	var/choice = input(H, "What should the ambush look like?", "Set an Ambush") as null|anything in disguises
	if(!choice)
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set an ambush there!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(H, target_turf)
	if(spot_error)
		H.balloon_alert(H, spot_error)
		return FALSE
	if(ataman_too_close_to_own(H, target_turf, H.ataman_active_ambushes, ATAMAN_TRAP_MIN_SPACING))
		H.balloon_alert(H, "too close to my other ambush!")
		return FALSE
	var/list/picked = disguises[choice]
	if(!ataman_trap_channel(H, target_turf))
		H.balloon_alert(H, "interrupted!")
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf) || ataman_trap_spot_error(H, target_turf) || ataman_too_close_to_own(H, target_turf, H.ataman_active_ambushes, ATAMAN_TRAP_MIN_SPACING))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set an ambush there!")
		return FALSE
	. = ..()

	var/obj/structure/trap/ataman_ambush_stone/ambush = new(target_turf)
	ambush.disguise_as_prop(picked[1], picked[2], picked[3], picked[4])
	ambush.set_placer(H)
	to_chat(H, span_notice("I conceal [ambush] as [picked[1]]."))
	return TRUE

/datum/action/cooldown/spell/ataman_trap
	name = "Set a Snare"
	desc = "Spend seven undisturbed seconds burying a disguised trap. Anyone caught is mauled, left bleeding badly, and marked for my Finishing Blow until the mark fades. I can maintain no more than three traps at once."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_MINOR_AOE
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 2 MINUTES
	cast_range = 1
	associated_skill = /datum/skill/craft/traps
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_trap/get_adjusted_cooldown()
	var/mob/living/carbon/human/H = owner
	if(istype(H) && H.ataman_loot_tier >= 5)
		return 15 MINUTES
	return ..()

/datum/action/cooldown/spell/ataman_trap/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	if(ataman_active_trap_count(H) >= ATAMAN_MAX_ACTIVE_TRAPS)
		if(feedback)
			H.balloon_alert(H, "three traps already set!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_trap/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf || target_turf.density)
		return FALSE
	if(istype(target_turf, /turf/open/transparent/openspace))
		return FALSE
	if(ataman_turf_has_trap(target_turf))
		owner.balloon_alert(owner, "another trap is already here!")
		return FALSE
	var/area/rogue/place = get_area(target_turf)
	if(istype(place) && (place.town_area || place.keep_area))
		owner.balloon_alert(owner, "I cannot set a trap here!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(owner, target_turf)
	if(spot_error)
		owner.balloon_alert(owner, spot_error)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || ataman_active_trap_count(H) >= ATAMAN_MAX_ACTIVE_TRAPS)
		owner.balloon_alert(owner, "three traps already set!")
		return FALSE
	if(ataman_too_close_to_own(H, target_turf, H.ataman_active_traps, ATAMAN_TRAP_MIN_SPACING))
		owner.balloon_alert(owner, "too close to my other trap!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_trap/cast(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || ataman_turf_has_trap(target_turf))
		H.balloon_alert(H, "another trap is already here!")
		return FALSE
	if(ataman_active_trap_count(H) >= ATAMAN_MAX_ACTIVE_TRAPS)
		H.balloon_alert(H, "three traps already set!")
		return FALSE

	var/list/flavors = list(
		"Mantrap" = /obj/structure/trap/ataman_snare/beartrap_type,
		"Buried charge" = /obj/structure/trap/ataman_snare/bomb_type,
		"Stake pit" = /obj/structure/trap/ataman_snare/stakes_type,
	)
	var/choice = input(H, "Which trap will I set?", "Set a Snare") as null|anything in flavors
	if(!choice)
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set a trap there!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(H, target_turf)
	if(spot_error)
		H.balloon_alert(H, spot_error)
		return FALSE
	if(ataman_too_close_to_own(H, target_turf, H.ataman_active_traps, ATAMAN_TRAP_MIN_SPACING))
		H.balloon_alert(H, "too close to my other trap!")
		return FALSE
	var/chosen_type = flavors[choice]
	if(!chosen_type)
		return FALSE
	if(!ataman_trap_channel(H, target_turf))
		H.balloon_alert(H, "interrupted!")
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf) || ataman_trap_spot_error(H, target_turf) || ataman_active_trap_count(H) >= ATAMAN_MAX_ACTIVE_TRAPS || ataman_too_close_to_own(H, target_turf, H.ataman_active_traps, ATAMAN_TRAP_MIN_SPACING))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set a trap there!")
		return FALSE
	. = ..()

	var/obj/structure/trap/ataman_snare/snare = new chosen_type(target_turf)
	snare.set_placer(H)
	to_chat(H, span_notice("I bury [snare] in the ground."))
	return TRUE

/proc/ataman_appraise_looted(atom/movable/container)
	var/total = 0
	for(var/obj/item/I in container.contents)
		if(length(I.contents))
			total += ataman_appraise_looted(I)
		if(I.looted)
			total += I.get_real_price()
	return total

/datum/action/cooldown/spell/ataman_exchange
	name = "Honest Exchange"
	desc = "Trade a bag of stolen goods to a nearby fence. I receive 60% of their appraised value, while the duchy treasury loses 40%. Only goods that once belonged to someone else count."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_CANTRIP
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 10 SECONDS
	cast_range = 1
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_exchange/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!istype(cast_on, /obj/item/storage))
		owner.balloon_alert(owner, "that is not a bag of goods!")
		return FALSE
	if(!locate(/obj/structure/roguemachine/blackmarket) in range(2, owner))
		owner.balloon_alert(owner, "there is no fence nearby!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_exchange/cast(atom/target)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/obj/item/storage/sack = target
	if(!istype(sack))
		return FALSE
	var/obj/structure/roguemachine/blackmarket/fence = locate(/obj/structure/roguemachine/blackmarket) in range(2, H)
	if(!fence)
		return FALSE

	var/appraised_value = round(ataman_appraise_looted(sack))
	if(appraised_value < ATAMAN_TRADE_MIN_VALUE)
		to_chat(H, span_warning("There are not enough stolen goods in [sack] for a real exchange."))
		return FALSE
	var/payout_value = round(appraised_value * ATAMAN_TRADE_PAYOUT_MULTIPLIER)

	sack.forceMove(fence)
	budget2change(payout_value, H)
	ataman_process_honest_trade(H, appraised_value)
	to_chat(H, span_notice("I hand [sack] to [fence] and receive [payout_value] mammons."))
	return TRUE
