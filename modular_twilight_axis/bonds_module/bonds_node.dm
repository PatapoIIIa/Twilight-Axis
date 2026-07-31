/datum/bond_node
	var/datum/bond_actor/owner
	/// Sentiment: exactly one bond per other mind.
	var/list/bonds
	/// Kinship: several structural links to the same person are legal.
	var/list/kin

/datum/bond_node/New(datum/bond_actor/new_owner)
	owner = new_owner
	bonds = list()
	kin = list()

/datum/bond_node/Destroy(force)
	QDEL_LIST_ASSOC_VAL(bonds)
	QDEL_LIST(kin)
	bonds = null
	kin = null
	owner = null
	return ..()

/datum/bond_node/proc/get_bond(datum/bond_actor/target)
	if(!target || !bonds)
		return null
	return bonds[target]

/datum/bond_node/proc/add_bond(datum/social_bond/bond)
	if(!bond?.other)
		return null
	bonds[bond.other] = bond
	enforce_cap()
	return bond

/datum/bond_node/proc/remove_bond(datum/bond_actor/target)
	var/datum/social_bond/bond = bonds?[target]
	if(!bond)
		return FALSE
	bonds -= target
	qdel(bond)
	return TRUE

/datum/bond_node/proc/add_kin(datum/social_bond/kin/link)
	if(!link?.other)
		return null
	kin += link
	return link

/datum/bond_node/proc/remove_kin_to(datum/bond_actor/target, kind)
	if(!target || !kin)
		return FALSE
	var/removed = FALSE
	for(var/datum/social_bond/kin/link as anything in kin.Copy())
		if(link.other != target)
			continue
		if(kind && link.kind != kind)
			continue
		kin -= link
		qdel(link)
		removed = TRUE
	return removed

/datum/bond_node/proc/enforce_cap()
	if(length(bonds) <= BOND_MAX_PER_MIND)
		return
	var/datum/bond_actor/weakest
	var/weakest_weight = BOND_WEIGHT_MAX + 1
	for(var/datum/bond_actor/target as anything in bonds)
		var/datum/social_bond/bond = bonds[target]
		if(!bond.evictable || bond.tags != BOND_TAG_NONE)
			continue
		if(bond.weight >= weakest_weight)
			continue
		weakest_weight = bond.weight
		weakest = target
	if(weakest)
		remove_bond(weakest)

/datum/bond_node/proc/sorted_bonds()
	var/list/out = list()
	for(var/datum/bond_actor/target as anything in bonds)
		out += bonds[target]
	return out
