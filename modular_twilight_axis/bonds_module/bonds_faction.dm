/datum/bond_faction
	abstract_type = /datum/bond_faction
	var/id = ""
	var/name = ""
	var/accent = "#8a8a8a"
	var/positions_key = ""
	var/list/extra_positions

/datum/bond_faction/proc/titles() as /list
	var/list/collected = list()
	if(positions_key)
		var/list/from_glob = GLOB.vars[positions_key]
		if(islist(from_glob))
			collected += from_glob
	if(length(extra_positions))
		collected += extra_positions
	return collected

/datum/controller/subsystem/bonds/proc/build_faction_index()
	faction_prototypes = list()
	faction_index = list()
	var/list/collisions = list()
	for(var/datum/bond_faction/faction_type as anything in typesof(/datum/bond_faction))
		if(IS_ABSTRACT(faction_type))
			continue
		var/datum/bond_faction/faction = new faction_type()
		faction_prototypes[faction.id] = faction
		for(var/title in faction.titles())
			if(!istext(title))
				continue
			if(faction_index[title])
				collisions += "[title] (already [faction_index[title]:id], now [faction.id])"
				continue
			faction_index[title] = faction
	if(length(collisions))
		bondlog("faction index collisions: [collisions.Join("; ")]", BONDLOG_WARN)
	bondlog("faction index built: [faction_prototypes.len] factions, [faction_index.len] titles", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/get_faction(faction_id)
	if(!faction_id)
		return null
	return faction_prototypes[faction_id]

/datum/controller/subsystem/bonds/proc/faction_for_title(title)
	if(!title)
		return null
	return faction_index[title]

/datum/controller/subsystem/bonds/proc/faction_for(mob/living/carbon/human/person)
	if(!ishuman(person))
		return null
	return faction_for_title(person.job)

/datum/controller/subsystem/bonds/proc/faction_id_for(mob/living/carbon/human/person)
	var/datum/bond_faction/faction = faction_for(person)
	return faction?.id
