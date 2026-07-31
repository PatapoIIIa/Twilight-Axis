/datum/controller/subsystem/bonds/proc/build_family_entries(mob/living/carbon/human/viewer) as /list
	var/list/entries = list()
	var/datum/heritage/house = viewer?.family_datum
	var/datum/family_member/checker = viewer?.family_member_datum
	if(!house || !checker)
		return entries
	for(var/datum/family_member/member as anything in house.members)
		if(!member?.person || member == checker)
			continue
		if(member.cosmetic || member.phantom)
			continue
		var/relation = SSfamilytree.get_cached_relation(house, checker, member)
		if(!relation)
			continue
		entries += list(build_family_entry(viewer, house, member, relation))
	return entries

/datum/controller/subsystem/bonds/proc/build_family_entry(mob/living/carbon/human/viewer, datum/heritage/house, datum/family_member/member, relation) as /list
	var/list/history = list()
	var/sentiment = ""
	var/datum/social_bond/bond = get_bond(viewer.mind, member.person?.mind)
	if(bond && bond.weight >= BOND_VISIBLE_WEIGHT)
		sentiment = bond.stage_label()
		for(var/datum/bond_history/entry as anything in bond.history)
			history += list(list(
				"label" = entry.label,
				"story" = entry.story,
			))
	return list(
		"name" = member.person.real_name,
		"label" = uppertext(relation),
		"desc" = sentiment,
		"accent" = house.GetRelationColor(relation) || "#c0a060",
		"job" = member.person.job || "",
		"species" = member.person.dna?.species?.name || "",
		"history" = history,
	)

/datum/controller/subsystem/bonds/proc/family_mind_set(mob/living/carbon/human/viewer) as /list
	var/list/actors = list()
	var/datum/heritage/house = viewer?.family_datum
	if(!house)
		return actors
	for(var/datum/family_member/member as anything in house.members)
		var/datum/bond_actor/actor = resolve_actor(member)
		if(!actor)
			continue
		actors[actor] = TRUE
	return actors
