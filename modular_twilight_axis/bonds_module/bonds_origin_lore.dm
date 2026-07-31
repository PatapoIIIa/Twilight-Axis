/datum/origin_lore
	abstract_type = /datum/origin_lore
	var/origin_a = ""
	var/origin_b = ""
	var/bias = 0
	var/weight_scale = 1

/datum/origin_lore/grenzelhoft_zybantu
	origin_a = "grenzelhoft"
	origin_b = "zybantu"
	bias = -10
	weight_scale = 1.8

/datum/origin_lore/grenzelhoft_azuria
	origin_a = "grenzelhoft"
	origin_b = "azuria"
	bias = 6
	weight_scale = 0.8

/datum/origin_lore/grenzelhoft_otava
	origin_a = "grenzelhoft"
	origin_b = "otava"
	bias = 5
	weight_scale = 0.9

/datum/origin_lore/grenzelhoft_kazengun
	origin_a = "grenzelhoft"
	origin_b = "kazengun"
	bias = -4
	weight_scale = 1.2

/datum/origin_lore/azuria_valoria
	origin_a = "azuria"
	origin_b = "valoria"
	bias = 4
	weight_scale = 0.9

/datum/origin_lore/azuria_heartfelt
	origin_a = "azuria"
	origin_b = "heartfelt"
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
