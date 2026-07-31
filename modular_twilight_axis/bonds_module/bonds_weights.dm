/datum/bond_weight_share
	abstract_type = /datum/bond_weight_share
	var/id = ""
	var/label = ""
	var/share = 0

/datum/bond_weight_share/role
	id = BOND_SHARE_ROLE
	label = "Положение"
	share = 0.40

/datum/bond_weight_share/lore
	id = BOND_SHARE_LORE
	label = "Происхождение"
	share = 0.20

/datum/bond_weight_share/storyteller
	id = BOND_SHARE_STORYTELLER
	label = "Сторителлер"
	share = 0.20

/datum/bond_weight_share/zone
	id = BOND_SHARE_ZONE
	label = "Место"
	share = 0.10

/datum/bond_weight_share/map
	id = BOND_SHARE_MAP
	label = "Карта"
	share = 0.10

/datum/controller/subsystem/bonds/proc/build_weight_shares()
	weight_shares = list()
	var/total = 0
	for(var/datum/bond_weight_share/share_type as anything in typesof(/datum/bond_weight_share))
		if(IS_ABSTRACT(share_type))
			continue
		var/datum/bond_weight_share/entry = new share_type()
		weight_shares[entry.id] = entry
		total += entry.share
	if(total < 0.999 || total > 1.001)
		bondlog("weight shares do not sum to 1 (got [total]) - the blend will not be neutral at rest", BONDLOG_ERROR)
	bondlog("weight shares built: [weight_shares.len], total [total]", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/blend_weights(list/modifiers)
	var/blended = 0
	var/covered = 0
	for(var/share_id in modifiers)
		var/datum/bond_weight_share/entry = weight_shares[share_id]
		if(!entry)
			continue
		var/value = modifiers[share_id]
		if(isnull(value))
			value = 1
		blended += entry.share * value
		covered += entry.share
	if(!covered)
		return 1
	if(covered < 0.999)
		blended += (1 - covered)
	return blended
