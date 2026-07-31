// House-to-house standing.
//
// Unlike faction stances, nothing here is declared up front: two houses start at nothing and
// only acquire a standing because their members did things to each other. Every scored bond
// event between members of two different houses bleeds a fraction of its permanent commit
// into the house pair, so a feud is the accumulated residue of individual grudges rather than
// a switch somebody flipped.

/datum/house_stance
	var/datum/heritage/house_a
	var/datum/heritage/house_b
	var/warmth = 0
	var/weight = 0
	var/incidents = 0
	var/list/history
	var/created_at = 0
	var/updated_at = 0

/datum/house_stance/New(datum/heritage/first, datum/heritage/second)
	house_a = first
	house_b = second
	created_at = world.time
	updated_at = world.time

/datum/house_stance/Destroy(force)
	QDEL_LIST(history)
	history = null
	house_a = null
	house_b = null
	return ..()

/proc/bonds_house_key(datum/heritage/first, datum/heritage/second)
	if(!first || !second || first == second)
		return null
	var/ref_a = REF(first)
	var/ref_b = REF(second)
	return (ref_a < ref_b) ? "[ref_a]|[ref_b]" : "[ref_b]|[ref_a]"

/datum/controller/subsystem/bonds/proc/get_house_stance(datum/heritage/first, datum/heritage/second)
	var/key = bonds_house_key(first, second)
	if(!key)
		return null
	return house_stances[key]

/datum/controller/subsystem/bonds/proc/get_or_create_house_stance(datum/heritage/first, datum/heritage/second)
	var/key = bonds_house_key(first, second)
	if(!key)
		return null
	var/datum/house_stance/stance = house_stances[key]
	if(stance)
		return stance
	stance = new(first, second)
	house_stances[key] = stance
	return stance

/datum/controller/subsystem/bonds/proc/nudge_house_stance(datum/heritage/first, datum/heritage/second, warmth_delta = 0, weight_delta = 0, reason = "")
	var/datum/house_stance/stance = get_or_create_house_stance(first, second)
	if(!stance)
		return null
	stance.warmth = clamp(stance.warmth + warmth_delta, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	stance.weight = clamp(stance.weight + weight_delta, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	stance.incidents++
	stance.updated_at = world.time
	if(reason)
		var/datum/bond_history/entry = new()
		entry.label = "Между домами"
		entry.story = reason
		entry.created_at = world.time
		entry.warmth_delta = warmth_delta
		entry.weight_delta = weight_delta
		LAZYADD(stance.history, entry)
		if(LAZYLEN(stance.history) > BOND_MAX_HISTORY)
			var/datum/bond_history/oldest = stance.history[1]
			stance.history -= oldest
			qdel(oldest)
	return stance

/datum/controller/subsystem/bonds/proc/house_of_mind(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	var/mob/living/carbon/human/body = actor?.current_body()
	if(!ishuman(body))
		return null
	return body.family_datum

/datum/controller/subsystem/bonds/proc/propagate_house_stance(subject, object, event_type)
	var/datum/bond_event/prototype = get_event_prototype(event_type)
	if(!prototype || !prototype.scored_propagation)
		return FALSE
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor)
		return FALSE
	var/datum/heritage/subject_house = house_of_mind(subject_actor)
	var/datum/heritage/object_house = house_of_mind(object_actor)
	if(!subject_house || !object_house || subject_house == object_house)
		return FALSE
	var/warmth_delta = prototype.warmth_commit * BOND_HOUSE_PROPAGATION
	var/weight_delta = abs(prototype.weight_commit) * BOND_HOUSE_PROPAGATION
	if(!warmth_delta && !weight_delta)
		return FALSE
	var/reason = "[subject_actor.name_of()] и [object_actor.name_of()]: [lowertext(prototype.history_label)]"
	nudge_house_stance(subject_house, object_house, warmth_delta, weight_delta, reason)
	bondlog("house stance [subject_house.housename] <-> [object_house.housename] moved by [warmth_delta]", BONDLOG_INFO)
	return TRUE

/datum/controller/subsystem/bonds/proc/house_stances_for(datum/heritage/house) as /list
	var/list/out = list()
	if(!house)
		return out
	for(var/key in house_stances)
		var/datum/house_stance/stance = house_stances[key]
		if(stance.house_a != house && stance.house_b != house)
			continue
		if(QDELETED(stance.house_a) || QDELETED(stance.house_b))
			continue
		out += stance
	return out

/datum/controller/subsystem/bonds/proc/other_house_in(datum/house_stance/stance, datum/heritage/house)
	if(!stance)
		return null
	return (stance.house_a == house) ? stance.house_b : stance.house_a
