/datum/bond_role_tier
	abstract_type = /datum/bond_role_tier
	var/weight = 1
	var/list/titles

/datum/bond_role_tier/crown
	weight = 3
	titles = list("Grand Duke", "Sultan", "Consort", "Prince", "Harem Favorite")

/datum/bond_role_tier/regent
	weight = 2.8
	titles = list("Hand", "Vizier")

/datum/bond_role_tier/high_office
	weight = 2.5
	titles = list("Steward", "Seneschal", "Councillor", "Bishop", "Marshal", "Inquisitor", "Mayor")

/datum/bond_role_tier/notable
	weight = 1.8
	titles = list("Knight", "Royal Knight", "Cataphract", "Templar", "Martyr", "Absolver", "Orthodoxist", "Guildmaster", "Merchant", "Sergeant", "Royal Guard Sergeant", "Town Sheriff", "Overseer", "Court Magician", "Archivist", "Head Physician")

/datum/controller/subsystem/bonds/proc/build_role_weights()
	role_weights = list()
	for(var/datum/bond_role_tier/tier_type as anything in typesof(/datum/bond_role_tier))
		if(IS_ABSTRACT(tier_type))
			continue
		var/datum/bond_role_tier/tier = new tier_type()
		for(var/title in tier.titles)
			if(isnull(role_weights[title]) || role_weights[title] < tier.weight)
				role_weights[title] = tier.weight
		qdel(tier)
	bondlog("role weights built: [role_weights.len] titles", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/role_impact_weight(mob/living/carbon/human/person)
	if(!ishuman(person) || !person.job)
		return 1
	var/weight = role_weights[person.job]
	return isnull(weight) ? 1 : weight
