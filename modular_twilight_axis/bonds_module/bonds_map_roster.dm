/datum/bond_map_roster
	abstract_type = /datum/bond_map_roster
	var/map_name = ""
	var/list/absent_factions
	var/list/extra_factions

/datum/bond_map_roster/rockhill
	map_name = "Rockhill"
	absent_factions = list(BOND_FACTION_VANGUARD)

/datum/bond_map_roster/deserttown
	map_name = "Desert Town"
	absent_factions = list(BOND_FACTION_CITYWATCH, BOND_FACTION_VANGUARD, BOND_FACTION_INQUISITION)

/datum/controller/subsystem/bonds/proc/build_map_rosters()
	map_rosters = list()
	for(var/datum/bond_map_roster/roster_type as anything in typesof(/datum/bond_map_roster))
		if(IS_ABSTRACT(roster_type))
			continue
		var/datum/bond_map_roster/roster = new roster_type()
		if(!roster.map_name)
			qdel(roster)
			continue
		map_rosters[roster.map_name] = roster
	bondlog("map rosters built: [map_rosters.len]", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/current_map_roster()
	var/current = SSmapping?.config?.map_name
	if(!current)
		return null
	return map_rosters[current]

/datum/controller/subsystem/bonds/proc/faction_present(faction_id)
	if(!faction_id)
		return FALSE
	var/datum/bond_map_roster/roster = current_map_roster()
	if(!roster)
		return TRUE
	if(length(roster.extra_factions) && (faction_id in roster.extra_factions))
		return TRUE
	if(length(roster.absent_factions) && (faction_id in roster.absent_factions))
		return FALSE
	return TRUE

/datum/controller/subsystem/bonds/proc/present_faction_ids() as /list
	var/list/out = list()
	for(var/faction_id in faction_prototypes)
		var/datum/bond_faction/faction = faction_prototypes[faction_id]
		if(istype(faction, /datum/bond_faction/clan))
			continue
		if(!faction_present(faction_id))
			continue
		out += faction_id
	return out
