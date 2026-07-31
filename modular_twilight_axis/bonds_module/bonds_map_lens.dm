/datum/bond_map_lens
	abstract_type = /datum/bond_map_lens
	var/map_name = ""
	var/weight = 0

/datum/bond_map_lens/rockhill
	map_name = "Rockhill"

/datum/bond_map_lens/dun_world
	map_name = "Dun World"

/datum/bond_map_lens/deserttown
	map_name = "Desert Town"

/datum/controller/subsystem/bonds/proc/build_map_lenses()
	map_lenses = list()
	for(var/datum/bond_map_lens/lens_type as anything in typesof(/datum/bond_map_lens))
		if(IS_ABSTRACT(lens_type))
			continue
		var/datum/bond_map_lens/lens = new lens_type()
		if(!lens.map_name)
			qdel(lens)
			continue
		map_lenses[lens.map_name] = lens
	bondlog("map lenses built: [map_lenses.len]", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/map_weight()
	var/current = SSmapping?.config?.map_name
	if(!current)
		return 1
	var/datum/bond_map_lens/lens = map_lenses[current]
	if(!lens || !lens.weight)
		return 1
	return lens.weight
