/datum/action/cooldown/spell/ataman_ambush
	name = "Set an Ambush"
	desc = "Place a completely hidden ambush trigger. The first intruder to disturb it will be surrounded by my bandits. I can maintain no more than three ambushes at once."
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
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		owner.balloon_alert(owner, "three ambushes already set!")
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
	. = ..()

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
	var/list/picked = disguises[choice]
	. = ..()

	var/obj/structure/trap/ataman_ambush_stone/ambush = new(target_turf)
	ambush.disguise_as_prop(picked[1], picked[2], picked[3], picked[4])
	ambush.set_placer(H)
	to_chat(H, span_notice("I conceal [ambush] as [picked[1]]."))
	return TRUE
