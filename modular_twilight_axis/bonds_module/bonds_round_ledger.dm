/datum/bonds_ledger_entry
	var/ckey
	var/seeds_granted = 0
	var/list/seeded_with = list()

/datum/controller/subsystem/bonds/proc/get_ledger(target_ckey)
	if(!target_ckey)
		return null
	var/datum/bonds_ledger_entry/entry = round_ledger[target_ckey]
	if(entry)
		return entry
	entry = new()
	entry.ckey = target_ckey
	round_ledger[target_ckey] = entry
	return entry

/datum/controller/subsystem/bonds/proc/already_seeded(ckey_a, ckey_b)
	var/datum/bonds_ledger_entry/entry = round_ledger[ckey_a]
	if(!entry)
		return FALSE
	return !!entry.seeded_with[ckey_b]

/datum/controller/subsystem/bonds/proc/remaining_seeds(target_ckey)
	var/datum/bonds_round_prefs/prefs = get_round_prefs(target_ckey)
	if(!prefs)
		return 0
	var/datum/bonds_ledger_entry/entry = round_ledger[target_ckey]
	var/granted = entry ? entry.seeds_granted : 0
	return max(0, prefs.seed_count - granted)

/datum/controller/subsystem/bonds/proc/mark_seeded(ckey_a, ckey_b)
	var/datum/bonds_ledger_entry/entry_a = get_ledger(ckey_a)
	var/datum/bonds_ledger_entry/entry_b = get_ledger(ckey_b)
	entry_a.seeded_with[ckey_b] = TRUE
	entry_b.seeded_with[ckey_a] = TRUE
	entry_a.seeds_granted++
	entry_b.seeds_granted++
