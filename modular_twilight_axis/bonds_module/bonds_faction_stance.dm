/datum/faction_stance
	var/faction_a
	var/faction_b
	var/warmth = 0
	var/weight = 0
	var/list/history
	var/created_at = 0
	var/updated_at = 0

/datum/faction_stance/New(id_a, id_b)
	faction_a = id_a
	faction_b = id_b
	created_at = world.time
	updated_at = world.time

/datum/faction_stance/Destroy(force)
	QDEL_LIST(history)
	history = null
	return ..()

/proc/bonds_stance_key(id_a, id_b)
	if(!id_a || !id_b)
		return null
	return (id_a < id_b) ? "[id_a]|[id_b]" : "[id_b]|[id_a]"

/datum/controller/subsystem/bonds/proc/get_stance(id_a, id_b)
	var/key = bonds_stance_key(id_a, id_b)
	if(!key)
		return null
	return faction_stances[key]

/datum/controller/subsystem/bonds/proc/get_or_create_stance(id_a, id_b)
	var/key = bonds_stance_key(id_a, id_b)
	if(!key || id_a == id_b)
		return null
	var/datum/faction_stance/stance = faction_stances[key]
	if(stance)
		return stance
	stance = new(id_a, id_b)
	faction_stances[key] = stance
	return stance

/datum/controller/subsystem/bonds/proc/stance_warmth(id_a, id_b)
	if(!id_a || !id_b)
		return 0
	if(id_a == id_b)
		return BOND_STANCE_SAME_FACTION_WARMTH
	var/datum/faction_stance/stance = get_stance(id_a, id_b)
	return stance ? stance.warmth : 0

/datum/controller/subsystem/bonds/proc/nudge_stance(id_a, id_b, warmth_delta = 0, weight_delta = 0, reason = "")
	var/datum/faction_stance/stance = get_or_create_stance(id_a, id_b)
	if(!stance)
		return null
	var/lens = storyteller_weight(id_a, id_b)
	warmth_delta *= lens
	weight_delta *= lens
	stance.warmth = clamp(stance.warmth + warmth_delta, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	stance.weight = clamp(stance.weight + weight_delta, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	stance.updated_at = world.time
	if(reason)
		var/datum/bond_history/entry = new()
		entry.label = "Фракции"
		entry.story = reason
		entry.created_at = world.time
		entry.warmth_delta = warmth_delta
		entry.weight_delta = weight_delta
		LAZYADD(stance.history, entry)
	return stance

/datum/controller/subsystem/bonds/proc/faction_affinity(mob/living/carbon/human/person_a, mob/living/carbon/human/person_b)
	var/id_a = faction_id_for(person_a)
	var/id_b = faction_id_for(person_b)
	if(!id_a || !id_b)
		return 0
	return stance_warmth(id_a, id_b)

/datum/controller/subsystem/bonds/proc/build_faction_stances()
	faction_stances = list()
	for(var/datum/faction_baseline/baseline_type as anything in typesof(/datum/faction_baseline))
		if(IS_ABSTRACT(baseline_type))
			continue
		var/datum/faction_baseline/baseline = new baseline_type()
		var/datum/faction_stance/stance = get_or_create_stance(baseline.faction_a, baseline.faction_b)
		if(!stance)
			bondlog("baseline [baseline_type] references an unknown faction pair", BONDLOG_WARN)
			qdel(baseline)
			continue
		stance.warmth = baseline.warmth
		stance.weight = baseline.weight
		qdel(baseline)
	bondlog("faction stances seeded: [faction_stances.len] pairs", BONDLOG_INFO)

// Baselines are laid down at Initialize, but the storyteller is only known once the round
// starts, so the lens is applied separately on the first post-roundstart pass.
/datum/controller/subsystem/bonds/proc/apply_storyteller_lens()
	if(storyteller_lens_applied)
		return FALSE
	storyteller_lens_applied = TRUE
	var/datum/storyteller/teller = active_storyteller()
	if(!teller)
		bondlog("no storyteller at lens time; faction stances left as declared", BONDLOG_INFO)
		return FALSE
	for(var/key in faction_stances)
		var/datum/faction_stance/stance = faction_stances[key]
		var/lens = storyteller_weight(stance.faction_a, stance.faction_b)
		if(lens == 1)
			continue
		stance.warmth = clamp(stance.warmth * lens, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
		stance.weight = clamp(stance.weight * lens, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	bondlog("storyteller lens applied: [teller.type]", BONDLOG_INFO)
	return TRUE
