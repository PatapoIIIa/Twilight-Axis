// The faction-impact pipeline.
//
// One incident between two people can move three different standings: their factions, their
// houses and (if both are kindred) their clans. Everything that scales that movement lives
// here, in one ordered chain, so there is exactly one place to look when a number surprises you:
//
//   base commit -> role weight -> map lens -> storyteller lens -> origin lore -> influence gate
//
// The influence gate is last on purpose: it decides whether the act counts at all, and it is
// what stops a twenty-person brawl from rewriting every relationship in town (see
// bonds_influence.dm).

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

	// The actor is the one who spends influence; the victim never pays for being hit.
	// Checked after the free rejections so a no-op act does not burn a point.
	if(!spend_influence(object_actor))
		return FALSE

	var/scale = applied_scale
	scale *= role_impact_weight(object_body) * role_impact_weight(subject_body)
	scale *= map_weight()
	scale *= zone_weight(object_body)
	var/datum/origin_lore/lore = origin_lore_for(subject_actor, object_actor)
	if(lore)
		scale *= lore.weight_scale
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
	// nudge_stance applies the storyteller lens itself.
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
