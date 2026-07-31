// Declared starting positions between vampire clans.
//
// All neutral at this stage on purpose: the pairs exist so the matrix, the panel and the
// nudge path are exercised, and so tuning later means editing numbers here rather than
// adding plumbing. Weight is small but nonzero - clans know of each other, they just have
// not taken a side yet.

/datum/faction_baseline/clan
	abstract_type = /datum/faction_baseline/clan
	warmth = 0
	weight = 10

/datum/faction_baseline/clan/abyss_crimson
	faction_a = BOND_CLAN_ABYSS
	faction_b = BOND_CLAN_CRIMSON

/datum/faction_baseline/clan/abyss_eoran
	faction_a = BOND_CLAN_ABYSS
	faction_b = BOND_CLAN_EORAN

/datum/faction_baseline/clan/abyss_nosferatu
	faction_a = BOND_CLAN_ABYSS
	faction_b = BOND_CLAN_NOSFERATU

/datum/faction_baseline/clan/abyss_thronleer
	faction_a = BOND_CLAN_ABYSS
	faction_b = BOND_CLAN_THRONLEER

/datum/faction_baseline/clan/crimson_eoran
	faction_a = BOND_CLAN_CRIMSON
	faction_b = BOND_CLAN_EORAN

/datum/faction_baseline/clan/crimson_nosferatu
	faction_a = BOND_CLAN_CRIMSON
	faction_b = BOND_CLAN_NOSFERATU

/datum/faction_baseline/clan/crimson_thronleer
	faction_a = BOND_CLAN_CRIMSON
	faction_b = BOND_CLAN_THRONLEER

/datum/faction_baseline/clan/eoran_nosferatu
	faction_a = BOND_CLAN_EORAN
	faction_b = BOND_CLAN_NOSFERATU

/datum/faction_baseline/clan/eoran_thronleer
	faction_a = BOND_CLAN_EORAN
	faction_b = BOND_CLAN_THRONLEER

/datum/faction_baseline/clan/nosferatu_thronleer
	faction_a = BOND_CLAN_NOSFERATU
	faction_b = BOND_CLAN_THRONLEER

/datum/faction_baseline/clan/caitiff_abyss
	faction_a = BOND_CLAN_CAITIFF
	faction_b = BOND_CLAN_ABYSS

/datum/faction_baseline/clan/caitiff_crimson
	faction_a = BOND_CLAN_CAITIFF
	faction_b = BOND_CLAN_CRIMSON

/datum/faction_baseline/clan/caitiff_eoran
	faction_a = BOND_CLAN_CAITIFF
	faction_b = BOND_CLAN_EORAN

/datum/faction_baseline/clan/caitiff_nosferatu
	faction_a = BOND_CLAN_CAITIFF
	faction_b = BOND_CLAN_NOSFERATU

/datum/faction_baseline/clan/caitiff_thronleer
	faction_a = BOND_CLAN_CAITIFF
	faction_b = BOND_CLAN_THRONLEER
