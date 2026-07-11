/datum/action/cooldown/spell/ataman_trap
	name = "Поставить силок"
	desc = "Установить полностью невидимую ловушку на земле. Всякий, кто в неё вступит, будет разорван и станет истекать кровью, попав под мою Метку до тех пор, пока рана не затянется."
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

/datum/action/cooldown/spell/ataman_trap/is_valid_target(atom/cast_on)
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
		owner.balloon_alert(owner, "Тут нельзя ставить ловушки!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_trap/cast(atom/target)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE

	var/list/flavors = list(
		"Капкан" = /obj/structure/trap/ataman_snare/beartrap_type,
		"Мина-ловушка" = /obj/structure/trap/ataman_snare/bomb_type,
		"Яма с кольями" = /obj/structure/trap/ataman_snare/stakes_type
	)
	var/choice = input(H, "Какую ловушку я ставлю?", "Поставить силок") as anything in flavors
	var/chosen_type = flavors[choice]
	var/obj/structure/trap/ataman_snare/S = new chosen_type(target_turf)
	S.set_placer(H)
	to_chat(H, span_notice("Я вкапываю [S] в землю."))
	return TRUE
