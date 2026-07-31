/datum/bonds_roster_panel
	var/mob/living/carbon/human/viewer

/datum/bonds_roster_panel/New(mob/living/carbon/human/new_viewer)
	viewer = new_viewer

/datum/bonds_roster_panel/Destroy(force)
	viewer = null
	return ..()

/datum/bonds_roster_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bonds_roster_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != viewer)
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BondsRoster")
		ui.open()
	return TRUE

/datum/bonds_roster_panel/ui_data(mob/user)
	if(user != viewer)
		return list("own" = null, "ally" = null)
	return SSbonds.build_roster_data(viewer)

/datum/bonds_roster_panel/ui_close()
	QDEL_NULL(src)

/datum/controller/subsystem/bonds/proc/build_roster_block(faction_id, mob/living/carbon/human/viewer, members_only_top = FALSE) as /list
	var/datum/bond_faction/faction = get_faction(faction_id)
	if(!faction)
		return null
	var/list/members = faction_members(faction_id)
	var/list/ranks = list()
	var/list/seen = list()

	for(var/datum/bond_rank/rank as anything in hierarchy_by_faction[faction_id])
		var/list/people = list()
		for(var/mob/living/carbon/human/person as anything in members)
			if(seen[person] || !(person.job in rank.titles))
				continue
			seen[person] = TRUE
			people += list(list(
				"name" = person.real_name,
				"job" = person.job,
				"self" = (person == viewer),
			))
		if(!length(people))
			continue
		ranks += list(list(
			"label" = rank.label,
			"level" = rank.level,
			"people" = people,
		))
		if(members_only_top && length(ranks) >= 2)
			break

	if(!members_only_top)
		var/list/unranked = list()
		for(var/mob/living/carbon/human/person as anything in members)
			if(seen[person])
				continue
			unranked += list(list(
				"name" = person.real_name,
				"job" = person.job,
				"self" = (person == viewer),
			))
		if(length(unranked))
			ranks += list(list(
				"label" = "Прочие",
				"level" = 99,
				"people" = unranked,
			))

	return list(
		"id" = faction.id,
		"name" = faction.name,
		"accent" = faction.accent,
		"ranks" = ranks,
		"total" = length(members),
	)

/datum/controller/subsystem/bonds/proc/build_roster_data(mob/living/carbon/human/viewer) as /list
	var/own_id = faction_id_for(viewer)
	if(!own_id)
		return list("own" = null, "ally" = null)
	var/ally_id = best_allied_faction(own_id)
	return list(
		"own" = build_roster_block(own_id, viewer, FALSE),
		"ally" = ally_id ? build_roster_block(ally_id, viewer, TRUE) : null,
		"allyWarmth" = ally_id ? round(stance_warmth(own_id, ally_id)) : 0,
	)

/mob/living/carbon/human/verb/bonds_roster()
	set name = "Faction Roster"
	set category = "Bonds"

	if(!SSbonds.faction_for(src))
		to_chat(src, span_notice("Вы никому не подчиняетесь и никем не командуете."))
		return
	var/datum/bonds_roster_panel/panel = new(src)
	panel.ui_interact(src)
