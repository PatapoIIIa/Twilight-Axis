/datum/controller/subsystem/bonds/proc/valid_seed_flavors() as /list
	var/list/flavors = list()
	for(var/event_type in event_prototypes)
		var/datum/bond_event/seed/prototype = event_prototypes[event_type]
		if(!istype(prototype) || !prototype.pickable)
			continue
		if(!(prototype.flavor_key in flavors))
			flavors += prototype.flavor_key
	return flavors

/datum/controller/subsystem/bonds/proc/seed_flavor_labels() as /list
	var/list/labels = list()
	for(var/event_type in event_prototypes)
		var/datum/bond_event/seed/prototype = event_prototypes[event_type]
		if(!istype(prototype) || !prototype.pickable)
			continue
		labels[prototype.flavor_key] = prototype.flavor_label
	return labels

/datum/controller/subsystem/bonds/proc/bonds_seed_phase_open()
	if(!SSticker?.round_start_time)
		return FALSE
	return (world.time - SSticker.round_start_time) >= BOND_SEED_DELAY

/datum/controller/subsystem/bonds/proc/schedule_seeding(delay = BOND_SEED_DELAY)
	addtimer(CALLBACK(src, PROC_REF(run_seeding)), delay, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/controller/subsystem/bonds/proc/run_seeding()
	if(!bonds_seed_phase_open())
		schedule_seeding(BOND_SEED_RETRY)
		return
	apply_storyteller_lens()
	var/list/pool = collect_seed_pool()
	if(length(pool) < 2)
		schedule_seeding(BOND_SEED_RETRY)
		return
	pool = shuffle(pool)
	var/paired = 0
	for(var/mob/living/carbon/human/seeker as anything in pool)
		if(remaining_seeds(seeker.ckey) <= 0)
			continue
		var/list/candidates = seed_candidates(seeker, pool)
		if(!length(candidates))
			continue
		var/mob/living/carbon/human/partner = pick(candidates)
		if(apply_seed(seeker, partner))
			paired++
	bondlog("run_seeding paired=[paired] pool=[pool.len]", BONDLOG_INFO)
	schedule_seeding(BOND_SEED_RETRY)

/datum/controller/subsystem/bonds/proc/collect_seed_pool() as /list
	var/list/pool = list()
	for(var/mob/living/carbon/human/person in GLOB.player_list)
		if(!person.client || !person.mind || !person.ckey)
			continue
		if(istype(person, /mob/living/carbon/human/dummy))
			continue
		if(!capture_round_prefs(person))
			continue
		if(remaining_seeds(person.ckey) <= 0)
			continue
		pool += person
	return pool

/datum/controller/subsystem/bonds/proc/seed_candidates(mob/living/carbon/human/seeker, list/pool) as /list
	var/list/weighted = list()
	var/datum/bond_faction/seeker_faction = faction_for(seeker)
	for(var/mob/living/carbon/human/candidate as anything in pool)
		if(candidate == seeker || !candidate.ckey)
			continue
		if(already_seeded(seeker.ckey, candidate.ckey))
			continue
		if(remaining_seeds(candidate.ckey) <= 0)
			continue
		if(!length(shared_seed_flavors(seeker.ckey, candidate.ckey)))
			continue
		var/datum/bond_faction/candidate_faction = faction_for(candidate)
		var/weight = 1
		if(seeker.job && candidate.job == seeker.job)
			weight = 8
		else if(seeker_faction && candidate_faction == seeker_faction)
			weight = 4
		else if(seeker_faction && candidate_faction && abs(stance_warmth(seeker_faction.id, candidate_faction.id)) >= BOND_STANCE_AFFINITY_THRESHOLD)
			weight = 2
		for(var/i in 1 to weight)
			weighted += candidate
	return weighted

/datum/controller/subsystem/bonds/proc/shared_seed_flavors(ckey_a, ckey_b) as /list
	var/datum/bonds_round_prefs/prefs_a = get_round_prefs(ckey_a)
	var/datum/bonds_round_prefs/prefs_b = get_round_prefs(ckey_b)
	if(!prefs_a || !prefs_b)
		return list()
	var/list/all_flavors = valid_seed_flavors()
	var/list/wanted_a = length(prefs_a.seed_flavors) ? prefs_a.seed_flavors : all_flavors
	var/list/wanted_b = length(prefs_b.seed_flavors) ? prefs_b.seed_flavors : all_flavors
	var/list/shared = list()
	for(var/flavor in wanted_a)
		if(flavor in wanted_b)
			shared += flavor
	return shared

/datum/controller/subsystem/bonds/proc/pick_seed_type(ckey_a, ckey_b)
	var/list/shared = shared_seed_flavors(ckey_a, ckey_b)
	if(!length(shared))
		return null
	var/chosen_flavor = pick(shared)
	var/list/matching = list()
	for(var/event_type in event_prototypes)
		var/datum/bond_event/seed/prototype = event_prototypes[event_type]
		if(!istype(prototype) || !prototype.pickable)
			continue
		if(prototype.flavor_key != chosen_flavor)
			continue
		matching += event_type
	if(!length(matching))
		return null
	return pick(matching)

/datum/controller/subsystem/bonds/proc/apply_seed(mob/living/carbon/human/person_a, mob/living/carbon/human/person_b)
	if(!person_a?.mind || !person_b?.mind || person_a == person_b)
		return FALSE
	var/seed_type = pick_seed_type(person_a.ckey, person_b.ckey)
	if(!seed_type)
		return FALSE
	var/datum/bond_event/seed/prototype = get_event_prototype(seed_type)
	if(!prototype)
		return FALSE
	var/other_type = prototype.opposite_type || seed_type
	record(person_a.mind, person_b.mind, seed_type, person_b, TRUE)
	record(person_b.mind, person_a.mind, other_type, person_a, TRUE)
	mark_seeded(person_a.ckey, person_b.ckey)
	notify_seed(person_a, person_b)
	notify_seed(person_b, person_a)
	bondlog("seeded [person_a.ckey] <-> [person_b.ckey] as [seed_type]", BONDLOG_INFO)
	return TRUE

/datum/controller/subsystem/bonds/proc/notify_seed(mob/living/carbon/human/person, mob/living/carbon/human/partner)
	var/datum/social_bond/bond = get_bond(person.mind, partner.mind)
	if(!bond)
		return
	var/datum/bond_history/latest = LAZYLEN(bond.history) ? bond.history[bond.history.len] : null
	if(!latest)
		return
	to_chat(person, span_notice("<b>Вы кое-кого припоминаете.</b> [latest.story]"))
