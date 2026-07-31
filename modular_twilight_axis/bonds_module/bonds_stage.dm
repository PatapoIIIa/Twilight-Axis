/datum/bond_stage
	abstract_type = /datum/bond_stage
	var/label = "Незнакомец"
	var/desc = ""
	var/category = BOND_GROUP_KNOWN
	var/accent = "#8a8a8a"
	var/priority = 0
	var/warmth_min = BOND_WARMTH_MIN
	var/warmth_max = BOND_WARMTH_MAX
	var/weight_min = BOND_WEIGHT_MIN
	var/weight_max = BOND_WEIGHT_MAX
	var/required_tags = BOND_TAG_NONE
	var/forbidden_tags = BOND_TAG_NONE

/datum/bond_stage/proc/matches(datum/social_bond/bond)
	if(bond.warmth < warmth_min || bond.warmth > warmth_max)
		return FALSE
	if(bond.weight < weight_min || bond.weight > weight_max)
		return FALSE
	if(required_tags && ((bond.tags & required_tags) != required_tags))
		return FALSE
	if(forbidden_tags && (bond.tags & forbidden_tags))
		return FALSE
	return TRUE

/datum/controller/subsystem/bonds/proc/build_stage_prototypes()
	var/list/collected = list()
	for(var/datum/bond_stage/stage_type as anything in typesof(/datum/bond_stage))
		if(IS_ABSTRACT(stage_type))
			continue
		collected += new stage_type()
	sortTim(collected, GLOBAL_PROC_REF(cmp_bond_stage_priority))
	stage_prototypes = collected

/proc/cmp_bond_stage_priority(datum/bond_stage/a, datum/bond_stage/b)
	return b.priority - a.priority

/datum/controller/subsystem/bonds/proc/resolve_stage(datum/social_bond/bond)
	if(!bond)
		return null
	for(var/datum/bond_stage/stage as anything in stage_prototypes)
		if(stage.matches(bond))
			return stage
	return null
