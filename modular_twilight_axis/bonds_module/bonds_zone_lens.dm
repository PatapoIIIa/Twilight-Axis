/datum/bond_zone_lens
	abstract_type = /datum/bond_zone_lens
	var/area_type
	var/weight = 1
	var/public_zone = FALSE
	var/priority = 0

/datum/bond_zone_lens/town_outdoors
	area_type = /area/rogue/outdoors/town
	weight = 1
	public_zone = TRUE
	priority = 10

/datum/bond_zone_lens/indoors
	area_type = /area/rogue/indoors
	weight = 1
	priority = 5

/datum/bond_zone_lens/outdoors
	area_type = /area/rogue/outdoors
	weight = 1
	priority = 5

/datum/bond_zone_lens/underground
	area_type = /area/rogue/under
	weight = 1
	priority = 10

/datum/bond_zone_lens/wilds
	area_type = /area/rogue/outdoors/mountains
	weight = 1
	priority = 10

/datum/bond_zone_lens/arena
	area_type = /area/rogue/indoors/ravoxarena
	weight = 0
	priority = 100

/datum/controller/subsystem/bonds/proc/build_zone_lenses()
	var/list/collected = list()
	for(var/datum/bond_zone_lens/lens_type as anything in typesof(/datum/bond_zone_lens))
		if(IS_ABSTRACT(lens_type))
			continue
		var/datum/bond_zone_lens/lens = new lens_type()
		if(!lens.area_type)
			qdel(lens)
			continue
		collected += lens
	sortTim(collected, GLOBAL_PROC_REF(cmp_bond_zone_priority))
	zone_lenses = collected
	bondlog("zone lenses built: [zone_lenses.len]", BONDLOG_INFO)

/proc/cmp_bond_zone_priority(datum/bond_zone_lens/a, datum/bond_zone_lens/b)
	return b.priority - a.priority

/datum/controller/subsystem/bonds/proc/zone_lens_for(atom/where)
	var/area/spot = get_area(where)
	if(!spot)
		return null
	for(var/datum/bond_zone_lens/lens as anything in zone_lenses)
		if(istype(spot, lens.area_type))
			return lens
	return null

/datum/controller/subsystem/bonds/proc/is_public_zone(atom/where)
	var/datum/bond_zone_lens/lens = zone_lens_for(where)
	return lens ? lens.public_zone : FALSE

/datum/controller/subsystem/bonds/proc/zone_weight(atom/where)
	var/area/spot = get_area(where)
	if(!spot)
		return 1
	for(var/datum/bond_zone_lens/lens as anything in zone_lenses)
		if(istype(spot, lens.area_type))
			return lens.weight
	return 1
