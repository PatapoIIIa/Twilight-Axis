/datum/bonds_round_prefs
	var/ckey
	var/seed_count = 0
	var/list/seed_flavors

/datum/controller/subsystem/bonds/proc/capture_round_prefs(mob/living/carbon/human/person)
	if(!person?.ckey)
		return null
	var/datum/bonds_round_prefs/captured = round_prefs_by_ckey[person.ckey]
	if(captured)
		return captured
	var/datum/preferences/prefs = person.client?.prefs
	if(!prefs)
		return null
	prefs.bonds_module_load_character()
	captured = new()
	captured.ckey = person.ckey
	captured.seed_count = clamp(prefs.bonds_seed_count, 0, BOND_MAX_SEEDS)
	captured.seed_flavors = prefs.bonds_seed_flavors ? prefs.bonds_seed_flavors.Copy() : list()
	round_prefs_by_ckey[person.ckey] = captured
	bondlog("captured round prefs for [person.ckey]: seeds=[captured.seed_count]", BONDLOG_INFO)
	return captured

/datum/controller/subsystem/bonds/proc/get_round_prefs(target_ckey)
	if(!target_ckey)
		return null
	return round_prefs_by_ckey[target_ckey]
