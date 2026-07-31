/datum/preferences
	var/bonds_seed_count = 0
	var/list/bonds_seed_flavors = list()
	var/tmp/bonds_module_loaded_slot
	var/tmp/bonds_module_loaded_path

/datum/preferences/proc/bonds_module_save_key_map() as /list
	var/static/list/key_map
	if(!key_map)
		key_map = list(
			"bonds_seed_count" = "bonds_seed_count",
			"bonds_seed_flavors" = "bonds_seed_flavors",
		)
	return key_map

/datum/preferences/proc/bonds_module_read_savefile(savefile/S)
	if(!S)
		return FALSE
	var/list/key_map = bonds_module_save_key_map()
	for(var/save_key in key_map)
		var/var_name = key_map[save_key]
		S[save_key] >> vars[var_name]
	return TRUE

/datum/preferences/proc/bonds_module_write_savefile(savefile/S)
	if(!S)
		return FALSE
	var/list/key_map = bonds_module_save_key_map()
	for(var/save_key in key_map)
		var/var_name = key_map[save_key]
		WRITE_FILE(S[save_key], vars[var_name])
	return TRUE

/datum/preferences/proc/bonds_module_sanitize_character()
	if(!isnum(bonds_seed_count))
		bonds_seed_count = 0
	bonds_seed_count = clamp(round(bonds_seed_count), 0, BOND_MAX_SEEDS)
	if(!islist(bonds_seed_flavors))
		bonds_seed_flavors = list()
	var/list/valid = SSbonds.valid_seed_flavors()
	for(var/flavor in bonds_seed_flavors.Copy())
		if(!(flavor in valid))
			bonds_seed_flavors -= flavor

/datum/preferences/proc/bonds_module_reset_character()
	bonds_seed_count = initial(bonds_seed_count)
	bonds_seed_flavors = list()

/datum/preferences/proc/bonds_module_load_character_from_savefile(savefile/S, slot, force = FALSE)
	if(!S)
		return FALSE
	if(!force && (bonds_module_loaded_path == path) && (bonds_module_loaded_slot == slot))
		return TRUE
	bonds_module_reset_character()
	bonds_module_read_savefile(S)
	bonds_module_sanitize_character()
	bonds_module_loaded_slot = slot
	bonds_module_loaded_path = path
	return TRUE

/datum/preferences/proc/bonds_module_load_character(slot)
	if(!path)
		return FALSE
	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE
	S.cd = "/character[slot || default_slot]"
	return bonds_module_load_character_from_savefile(S, slot || default_slot, TRUE)

/datum/preferences/proc/bonds_module_save_character_to_savefile(savefile/S, slot)
	if(!S)
		return FALSE
	bonds_module_sanitize_character()
	bonds_module_write_savefile(S)
	bonds_module_loaded_slot = slot
	bonds_module_loaded_path = path
	return TRUE
