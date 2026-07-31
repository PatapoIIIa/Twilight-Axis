/datum/controller/subsystem/bonds/proc/social_impact(subject, object, event_type, applied_scale = 1)
	var/datum/bond_event/prototype = get_event_prototype(event_type)
	if(!prototype || !prototype.scored_propagation)
		return FALSE
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor || subject_actor == object_actor)
		return FALSE
	var/mob/living/carbon/human/subject_body = subject_actor.current_body()
	var/mob/living/carbon/human/object_body = object_actor.current_body()
	if(!ishuman(subject_body) || !ishuman(object_body))
		return FALSE

	if(!applied_scale)
		return FALSE
	var/hostile = (prototype.category == BOND_CATEGORY_VIOLENCE) || (prototype.category == BOND_CATEGORY_DEATH)
	if(hostile && !is_public_zone(object_body))
		return FALSE

	if(!spend_influence(object_actor))
		return FALSE

	var/datum/origin_lore/lore = origin_lore_for(subject_actor, object_actor)
	var/id_a = faction_id_for(subject_body)
	var/id_b = faction_id_for(object_body)
	var/scale = applied_scale * blend_weights(list(
		BOND_SHARE_ROLE = role_impact_weight(object_body) * role_impact_weight(subject_body),
		BOND_SHARE_LORE = lore ? lore.weight_scale : 1,
		BOND_SHARE_STORYTELLER = storyteller_weight(id_a, id_b),
		BOND_SHARE_ZONE = zone_weight(object_body),
		BOND_SHARE_MAP = map_weight(),
	))
	var/bias = lore ? lore.bias : 0

	var/warmth_delta = (prototype.warmth_commit * scale) + bias
	var/weight_delta = abs(prototype.weight_commit) * scale
	if(!warmth_delta && !weight_delta)
		return FALSE

	var/reason = "[subject_actor.name_of()] и [object_actor.name_of()]: [lowertext(prototype.history_label)]"
	apply_faction_impact(subject_body, object_body, warmth_delta, weight_delta, reason)
	apply_house_impact(subject_body, object_body, warmth_delta, weight_delta, reason)
	apply_clan_impact(subject_body, object_body, warmth_delta, weight_delta, reason)
	return TRUE

/datum/controller/subsystem/bonds/proc/apply_faction_impact(mob/living/carbon/human/subject_body, mob/living/carbon/human/object_body, warmth_delta, weight_delta, reason)
	var/id_a = faction_id_for(subject_body)
	var/id_b = faction_id_for(object_body)
	if(!id_a || !id_b || id_a == id_b)
		return FALSE
	nudge_stance(id_a, id_b, warmth_delta, weight_delta, reason)
	bondlog("faction impact [id_a] <-> [id_b] warmth [warmth_delta]", BONDLOG_INFO)
	return TRUE

/datum/controller/subsystem/bonds/proc/apply_house_impact(mob/living/carbon/human/subject_body, mob/living/carbon/human/object_body, warmth_delta, weight_delta, reason)
	var/datum/heritage/house_a = subject_body.family_datum
	var/datum/heritage/house_b = object_body.family_datum
	if(!house_a || !house_b || house_a == house_b)
		return FALSE
	nudge_house_stance(house_a, house_b, warmth_delta, weight_delta, reason)
	return TRUE

/datum/controller/subsystem/bonds/proc/apply_clan_impact(mob/living/carbon/human/subject_body, mob/living/carbon/human/object_body, warmth_delta, weight_delta, reason)
	var/id_a = clan_faction_id_for(subject_body)
	var/id_b = clan_faction_id_for(object_body)
	if(!id_a || !id_b || id_a == id_b)
		return FALSE
	nudge_stance(id_a, id_b, warmth_delta, weight_delta, reason)
	return TRUE
