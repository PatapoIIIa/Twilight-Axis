/datum/bonds_panel
	var/mob/living/carbon/human/viewer

/datum/bonds_panel/New(mob/living/carbon/human/new_viewer)
	viewer = new_viewer

/datum/bonds_panel/Destroy(force)
	viewer = null
	return ..()

/datum/bonds_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bonds_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != viewer)
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Bonds")
		ui.open()
	return TRUE

/datum/bonds_panel/ui_data(mob/user)
	if(user != viewer || !viewer?.mind)
		return list("groups" = list())
	return list("groups" = SSbonds.build_panel_groups(viewer))

/datum/bonds_panel/ui_close()
	QDEL_NULL(src)

/datum/controller/subsystem/bonds/proc/build_panel_groups(mob/living/carbon/human/viewer) as /list
	var/list/groups = list()
	var/list/family_entries = build_family_entries(viewer)
	var/list/kin = family_mind_set(viewer)
	if(length(family_entries))
		groups += list(list(
			"key" = BOND_GROUP_FAMILY,
			"entries" = family_entries,
		))

	var/list/buckets = list()
	for(var/datum/social_bond/bond as anything in get_bonds_for(viewer.mind))
		if(bond.weight < BOND_VISIBLE_WEIGHT)
			continue
		if(kin[bond.other])
			continue
		var/group = bond.stage_group()
		if(!buckets[group])
			buckets[group] = list()
		buckets[group] += list(build_panel_entry(bond))
	for(var/group_key in buckets)
		groups += list(list(
			"key" = group_key,
			"entries" = buckets[group_key],
		))
	return groups

/datum/controller/subsystem/bonds/proc/build_panel_entry(datum/social_bond/bond) as /list
	var/list/history = list()
	for(var/datum/bond_history/entry as anything in bond.history)
		history += list(list(
			"label" = entry.label,
			"story" = entry.story,
		))
	return list(
		"name" = bond.display_name(),
		"label" = bond.stage_label(),
		"desc" = bond.stage?.desc || "",
		"accent" = bond.stage?.accent || "#8a8a8a",
		"job" = bond.snapshot?["job"] || "",
		"species" = bond.snapshot?["species"] || "",
		"history" = history,
	)
