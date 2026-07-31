/datum/bonds_prefs_panel
	var/mob/living/carbon/human/viewer

/datum/bonds_prefs_panel/New(mob/living/carbon/human/new_viewer)
	viewer = new_viewer

/datum/bonds_prefs_panel/Destroy(force)
	viewer = null
	return ..()

/datum/bonds_prefs_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bonds_prefs_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != viewer)
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BondsPrefs")
		ui.open()
	return TRUE

/datum/bonds_prefs_panel/ui_data(mob/user)
	var/datum/preferences/prefs = viewer?.client?.prefs
	if(user != viewer || !prefs)
		return list("seedCount" = 0, "maxSeeds" = BOND_MAX_SEEDS, "flavors" = list(), "locked" = TRUE)
	var/list/labels = SSbonds.seed_flavor_labels()
	var/list/flavors = list()
	for(var/flavor_key in labels)
		flavors += list(list(
			"key" = flavor_key,
			"label" = labels[flavor_key],
			"enabled" = (flavor_key in prefs.bonds_seed_flavors),
		))
	return list(
		"seedCount" = prefs.bonds_seed_count,
		"maxSeeds" = BOND_MAX_SEEDS,
		"flavors" = flavors,
		"locked" = !isnull(SSbonds.get_round_prefs(viewer.ckey)),
	)

/datum/bonds_prefs_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/datum/preferences/prefs = viewer?.client?.prefs
	if(!prefs || ui.user != viewer)
		return FALSE

	switch(action)
		if("set_seed_count")
			var/value = params["value"]
			if(!isnum(value))
				return FALSE
			prefs.bonds_seed_count = clamp(round(value), 0, BOND_MAX_SEEDS)
			prefs.bonds_module_sanitize_character()
			return TRUE

		if("toggle_flavor")
			var/flavor_key = params["key"]
			if(!istext(flavor_key))
				return FALSE
			if(!(flavor_key in SSbonds.valid_seed_flavors()))
				return FALSE
			if(flavor_key in prefs.bonds_seed_flavors)
				prefs.bonds_seed_flavors -= flavor_key
			else
				prefs.bonds_seed_flavors += flavor_key
			return TRUE

	return FALSE

/datum/bonds_prefs_panel/ui_close()
	QDEL_NULL(src)
