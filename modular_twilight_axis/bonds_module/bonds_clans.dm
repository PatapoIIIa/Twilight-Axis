/datum/bond_faction/clan
	abstract_type = /datum/bond_faction/clan
	var/clan_type

/datum/bond_faction/clan/titles()
	return list()

/datum/bond_faction/clan/caitiff
	id = BOND_CLAN_CAITIFF
	name = "Каитифы"
	accent = "#6e6e6e"
	clan_type = /datum/clan

/datum/bond_faction/clan/abyss
	id = BOND_CLAN_ABYSS
	name = "Бездна"
	accent = "#4a3f6b"
	clan_type = /datum/clan/abyss

/datum/bond_faction/clan/crimson_fang
	id = BOND_CLAN_CRIMSON
	name = "Багряный клык"
	accent = "#8c2f3f"
	clan_type = /datum/clan/crimson_fang

/datum/bond_faction/clan/eoran
	id = BOND_CLAN_EORAN
	name = "Эоране"
	accent = "#b07f9a"
	clan_type = /datum/clan/eoran

/datum/bond_faction/clan/nosferatu
	id = BOND_CLAN_NOSFERATU
	name = "Носферату"
	accent = "#5f6b4a"
	clan_type = /datum/clan/nosferatu

/datum/bond_faction/clan/thronleer
	id = BOND_CLAN_THRONLEER
	name = "Тронлиры"
	accent = "#8a7f4a"
	clan_type = /datum/clan/thronleer

/datum/controller/subsystem/bonds/proc/build_clan_index()
	clan_index = list()
	for(var/faction_id in faction_prototypes)
		var/datum/bond_faction/clan/faction = faction_prototypes[faction_id]
		if(!istype(faction) || !faction.clan_type)
			continue
		clan_index[faction.clan_type] = faction
	bondlog("clan index built: [clan_index.len] clans", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/clan_faction_for(mob/living/carbon/human/person)
	if(!ishuman(person) || !person.clan)
		return null
	var/datum/bond_faction/clan/exact = clan_index[person.clan.type]
	if(exact)
		return exact
	return clan_index[/datum/clan]

/datum/controller/subsystem/bonds/proc/clan_faction_id_for(mob/living/carbon/human/person)
	var/datum/bond_faction/clan/faction = clan_faction_for(person)
	return faction?.id

/datum/controller/subsystem/bonds/proc/build_clan_panel(mob/living/carbon/human/person) as /list
	var/list/out = list()
	var/datum/bond_faction/clan/own = clan_faction_for(person)
	if(!own)
		return out
	for(var/faction_id in faction_prototypes)
		if(faction_id == own.id)
			continue
		var/datum/bond_faction/clan/other = faction_prototypes[faction_id]
		if(!istype(other))
			continue
		var/warmth = stance_warmth(own.id, other.id)
		var/datum/faction_stance/stance = get_stance(own.id, other.id)
		out += list(list(
			"name" = other.name,
			"accent" = other.accent,
			"label" = bonds_stance_label(warmth),
			"labelAccent" = bonds_stance_accent(warmth),
			"intensity" = bonds_stance_intensity(stance ? stance.weight : 0),
		))
	return out
