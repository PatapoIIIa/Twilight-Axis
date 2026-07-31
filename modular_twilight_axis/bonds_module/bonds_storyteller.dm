/datum/bond_storyteller_lens
	abstract_type = /datum/bond_storyteller_lens
	var/storyteller_type
	var/list/pair_weights
	var/default_weight = 1

/datum/bond_storyteller_lens/proc/weight_for(id_a, id_b)
	if(!length(pair_weights))
		return default_weight
	var/key = bonds_stance_key(id_a, id_b)
	if(!key)
		return default_weight
	var/weight = pair_weights[key]
	return isnull(weight) ? default_weight : weight

/datum/controller/subsystem/bonds/proc/build_storyteller_lenses()
	storyteller_lenses = list()
	for(var/datum/bond_storyteller_lens/lens_type as anything in typesof(/datum/bond_storyteller_lens))
		if(IS_ABSTRACT(lens_type))
			continue
		var/datum/bond_storyteller_lens/lens = new lens_type()
		if(!lens.storyteller_type)
			qdel(lens)
			continue
		storyteller_lenses[lens.storyteller_type] = lens
	bondlog("storyteller lenses built: [storyteller_lenses.len]", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/active_storyteller()
	if(!SSgamemode)
		return null
	if(SSgamemode.current_storyteller)
		return SSgamemode.current_storyteller
	if(SSgamemode.roundstart_storyteller)
		return SSgamemode.storytellers?[SSgamemode.roundstart_storyteller]
	if(SSgamemode.selected_storyteller)
		return SSgamemode.storytellers?[SSgamemode.selected_storyteller]
	return null

/datum/controller/subsystem/bonds/proc/storyteller_weight(id_a, id_b)
	var/datum/storyteller/teller = active_storyteller()
	if(!teller)
		return 1
	var/datum/bond_storyteller_lens/lens = storyteller_lenses[teller.type]
	if(!lens)
		return 1
	return lens.weight_for(id_a, id_b)
