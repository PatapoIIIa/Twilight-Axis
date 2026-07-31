// Inherited opinion between origins.
//
// This is the "lore" layer: it does not describe what these two people did, it describes what
// their homelands already thought of each other before either of them was born. It MIXES with
// the faction layer rather than replacing it - a Zybantu guardsman striking a Grenzelhoft
// burgher lands harder between those factions than the same blow between two Azurians, because
// the old grudge colours how the incident is read.
//
// `bias` is a flat warmth offset applied on top of the incident. `weight_scale` multiplies how
// much the incident moves the faction pair at all.

/datum/origin_lore
	abstract_type = /datum/origin_lore
	var/origin_a = ""
	var/origin_b = ""
	var/bias = 0
	var/weight_scale = 1

/datum/origin_lore/zybantu_grenzelhoft
	origin_a = "zybantu"
	origin_b = "grenzelhoft"
	bias = -8
	weight_scale = 1.5

/datum/origin_lore/azuria_grenzelhoft
	origin_a = "azuria"
	origin_b = "grenzelhoft"
	bias = -5
	weight_scale = 1.3

/datum/origin_lore/azuria_heartfelt
	origin_a = "azuria"
	origin_b = "heartfelt"
	bias = 4
	weight_scale = 0.8

/datum/origin_lore/azuria_otava
	origin_a = "azuria"
	origin_b = "otava"
	bias = -3
	weight_scale = 1.2

/datum/origin_lore/valoria_etrusca
	origin_a = "valoria"
	origin_b = "etrusca"
	bias = -4
	weight_scale = 1.2

/datum/origin_lore/gronn_hammerhold
	origin_a = "gronn"
	origin_b = "hammerhold"
	bias = 5
	weight_scale = 0.8

/proc/bonds_origin_key(id_a, id_b)
	if(!id_a || !id_b)
		return null
	return (id_a < id_b) ? "[id_a]|[id_b]" : "[id_b]|[id_a]"

/datum/controller/subsystem/bonds/proc/build_origin_lore()
	origin_lore = list()
	for(var/datum/origin_lore/lore_type as anything in typesof(/datum/origin_lore))
		if(IS_ABSTRACT(lore_type))
			continue
		var/datum/origin_lore/lore = new lore_type()
		var/key = bonds_origin_key(lore.origin_a, lore.origin_b)
		if(!key)
			qdel(lore)
			continue
		origin_lore[key] = lore
	bondlog("origin lore built: [origin_lore.len] pairs", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/origin_lore_for(participant_a, participant_b)
	var/key = bonds_origin_key(origin_id_for(participant_a), origin_id_for(participant_b))
	if(!key)
		return null
	return origin_lore[key]
