/datum/action/cooldown/spell/ataman_ambush
	name = "Устроить засаду"
	desc = "Установить замаскированный камень-ловушку. Тот, кто его потревожит, попадёт в засаду - горстка моих бандитов выскочит, чтобы окружить, обезоружить и связать его."
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

/datum/action/cooldown/spell/ataman_ambush/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf || target_turf.density)
		return FALSE
	if(istype(target_turf, /turf/open/transparent/openspace))
		return FALSE
	var/area/rogue/place = get_area(target_turf)
	if(istype(place) && (place.town_area || place.keep_area))
		owner.balloon_alert(owner, "Тут нельзя устраивать засады!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_ambush/cast(atom/target)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE

	var/obj/structure/trap/ataman_ambush_stone/S = new(target_turf)
	S.set_placer(H)
	var/obj/item/disguise = H.get_active_held_item()
	if(disguise)
		S.disguise_as(disguise)
		to_chat(H, span_notice("Я кладу [S] на землю, замаскировав под то, что держал в руке."))
		qdel(disguise)
	else
		to_chat(H, span_notice("Я кладу [S] среди окружения."))
	return TRUE
