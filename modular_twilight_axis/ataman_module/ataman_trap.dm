/datum/action/cooldown/spell/ataman_trap
	name = "Set a Snare"
	desc = "Set a completely invisible trap on the ground. Anyone caught is mauled, left bleeding badly, and marked for my Finishing Blow until the mark fades."
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
	return TRUE

/datum/action/cooldown/spell/ataman_trap/cast(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || ataman_turf_has_trap(target_turf))
		H.balloon_alert(H, "another trap is already here!")
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
	var/chosen_type = flavors[choice]
	if(!chosen_type)
		return FALSE
	. = ..()

	var/obj/structure/trap/ataman_snare/snare = new chosen_type(target_turf)
	snare.set_placer(H)
	to_chat(H, span_notice("I bury [snare] in the ground."))
	return TRUE
