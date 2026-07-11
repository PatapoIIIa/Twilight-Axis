/datum/action/cooldown/spell/ataman_execute
	name = "Добивающий удар"
	desc = "Нанести один разящий удар или выстрел по цели, попавшей в мою ловушку, полностью минуя её броню. Требует владения текущим оружием на уровне эксперта."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_CANTRIP
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 4 SECONDS
	cast_range = 1
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_execute/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(cast_on) || cast_on == owner)
		return FALSE
	var/mob/living/L = cast_on
	var/datum/component/ataman_marked/mark = L.GetComponent(/datum/component/ataman_marked)
	if(!mark)
		owner.balloon_alert(owner, "Цель не помечена!")
		return FALSE
	if(mark.get_marker() != owner)
		owner.balloon_alert(owner, "Это не моя метка!")
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/obj/item/weapon = H.get_active_held_item()
	var/weapon_skill = weapon?.associated_skill
	if(!weapon_skill || H.get_skill_level(weapon_skill) < SKILL_LEVEL_EXPERT)
		owner.balloon_alert(owner, "Недостаточно мастерства с этим оружием!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_execute/cast(atom/target)
	. = ..()
	var/mob/living/L = target
	var/mob/living/carbon/human/H = owner
	if(!istype(L) || !istype(H))
		return FALSE
	var/datum/component/ataman_marked/mark = L.GetComponent(/datum/component/ataman_marked)
	if(!mark)
		return FALSE

	var/obj/item/weapon = H.get_active_held_item()
	var/dmg = weapon ? weapon.force : 20
	var/def_zone = H.zone_selected

	L.visible_message(span_danger("[H] находит брешь в защите [L] и разит без промаха!"), span_userdanger("[H] находит брешь в моей защите и разит без промаха!"))
	L.apply_damage(dmg, BRUTE, def_zone)
	qdel(mark)
	return TRUE
