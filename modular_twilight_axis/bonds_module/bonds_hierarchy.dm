/datum/bond_rank
	abstract_type = /datum/bond_rank
	var/faction_id = ""
	var/level = 1
	var/label = ""
	var/list/titles

/datum/bond_rank/noble_duke
	faction_id = BOND_FACTION_NOBLE
	level = 1
	label = "Правитель"
	titles = list("Grand Duke", "Sultan")

/datum/bond_rank/noble_family
	faction_id = BOND_FACTION_NOBLE
	level = 2
	label = "Семья правителя"
	titles = list("Consort", "Prince", "Harem Favorite")

/datum/bond_rank/court_hand
	faction_id = BOND_FACTION_COURT
	level = 1
	label = "Десница"
	titles = list("Hand", "Vizier")

/datum/bond_rank/court_council
	faction_id = BOND_FACTION_COURT
	level = 2
	label = "Советники"
	titles = list("Steward", "Seneschal", "Councillor", "Sheikh")

/datum/bond_rank/court_household
	faction_id = BOND_FACTION_COURT
	level = 3
	label = "Двор"
	titles = list("Clerk", "Jester", "Archivist", "Court Magician", "Court Physician", "Suitor", "Head Slave", "Slave Master")

/datum/bond_rank/retinue_marshal
	faction_id = BOND_FACTION_RETINUE
	level = 1
	label = "Маршал"
	titles = list("Marshal")

/datum/bond_rank/retinue_royal
	faction_id = BOND_FACTION_RETINUE
	level = 2
	label = "Королевские рыцари"
	titles = list("Royal Knight")

/datum/bond_rank/retinue_knights
	faction_id = BOND_FACTION_RETINUE
	level = 3
	label = "Рыцари"
	titles = list("Knight", "Cataphract")

/datum/bond_rank/retinue_squires
	faction_id = BOND_FACTION_RETINUE
	level = 4
	label = "Оруженосцы"
	titles = list("Squire")

/datum/bond_rank/garrison_sergeant
	faction_id = BOND_FACTION_GARRISON
	level = 1
	label = "Сержант"
	titles = list("Sergeant", "Royal Guard Sergeant", "Janissary Sergeant", "Azeb Agha")

/datum/bond_rank/garrison_guards
	faction_id = BOND_FACTION_GARRISON
	level = 2
	label = "Гвардия"
	titles = list("Man at Arms", "Royal Guard", "Warden", "Janissary")

/datum/bond_rank/garrison_watch
	faction_id = BOND_FACTION_GARRISON
	level = 3
	label = "Дозор"
	titles = list("Watchman", "Azeb")

/datum/bond_rank/citywatch_sheriff
	faction_id = BOND_FACTION_CITYWATCH
	level = 1
	label = "Шериф"
	titles = list("Town Sheriff")

/datum/bond_rank/citywatch_watch
	faction_id = BOND_FACTION_CITYWATCH
	level = 2
	label = "Городская стража"
	titles = list("Town Watch")

/datum/bond_rank/vanguard_overseer
	faction_id = BOND_FACTION_VANGUARD
	level = 1
	label = "Надзиратель"
	titles = list("Overseer")

/datum/bond_rank/vanguard_ranks
	faction_id = BOND_FACTION_VANGUARD
	level = 2
	label = "Авангард"
	titles = list("Vanguard")

/datum/bond_rank/church_bishop
	faction_id = BOND_FACTION_CHURCH
	level = 1
	label = "Епископ"
	titles = list("Bishop")

/datum/bond_rank/church_ordained
	faction_id = BOND_FACTION_CHURCH
	level = 2
	label = "Служители"
	titles = list("Templar", "Martyr", "Keeper", "Druid")

/datum/bond_rank/church_acolytes
	faction_id = BOND_FACTION_CHURCH
	level = 3
	label = "Аколиты"
	titles = list("Acolyte")

/datum/bond_rank/church_sexton
	faction_id = BOND_FACTION_CHURCH
	level = 4
	label = "Алтарники"
	titles = list("Sexton")

/datum/bond_rank/inquisition_inquisitor
	faction_id = BOND_FACTION_INQUISITION
	level = 1
	label = "Инквизитор"
	titles = list("Inquisitor")

/datum/bond_rank/inquisition_absolver
	faction_id = BOND_FACTION_INQUISITION
	level = 2
	label = "Искупитель"
	titles = list("Absolver")

/datum/bond_rank/inquisition_orthodoxist
	faction_id = BOND_FACTION_INQUISITION
	level = 3
	label = "Ортодоксист"
	titles = list("Orthodoxist")

/datum/bond_rank/burgher_master
	faction_id = BOND_FACTION_BURGHER
	level = 1
	label = "Гильдмастер"
	titles = list("Guildmaster", "Mayor")

/datum/bond_rank/burgher_guild
	faction_id = BOND_FACTION_BURGHER
	level = 2
	label = "Гильдия"
	titles = list("Guildsman", "Tailor", "Apothecary", "Innkeeper", "Bathmaster", "Magicians Associate", "Head Physician", "Bailiff")

/datum/bond_rank/atc_merchant
	faction_id = BOND_FACTION_ATC
	level = 1
	label = "Купец"
	titles = list("Merchant")

/datum/bond_rank/atc_shophand
	faction_id = BOND_FACTION_ATC
	level = 2
	label = "Приказчики"
	titles = list("Shophand")

/datum/controller/subsystem/bonds/proc/build_hierarchy()
	hierarchy_by_faction = list()
	rank_by_title = list()
	for(var/datum/bond_rank/rank_type as anything in typesof(/datum/bond_rank))
		if(IS_ABSTRACT(rank_type))
			continue
		var/datum/bond_rank/rank = new rank_type()
		if(!rank.faction_id)
			qdel(rank)
			continue
		if(!hierarchy_by_faction[rank.faction_id])
			hierarchy_by_faction[rank.faction_id] = list()
		hierarchy_by_faction[rank.faction_id] += rank
		for(var/title in rank.titles)
			rank_by_title[title] = rank
	for(var/faction_id in hierarchy_by_faction)
		sortTim(hierarchy_by_faction[faction_id], GLOBAL_PROC_REF(cmp_bond_rank_level))
	bondlog("hierarchy built: [hierarchy_by_faction.len] factions, [rank_by_title.len] titles", BONDLOG_INFO)

/proc/cmp_bond_rank_level(datum/bond_rank/a, datum/bond_rank/b)
	return a.level - b.level

/datum/controller/subsystem/bonds/proc/rank_for_title(title)
	if(!title)
		return null
	return rank_by_title[title]

/datum/controller/subsystem/bonds/proc/faction_members(faction_id) as /list
	var/list/out = list()
	if(!faction_id)
		return out
	for(var/mob/living/carbon/human/person in GLOB.player_list)
		if(!person.client || !person.mind || istype(person, /mob/living/carbon/human/dummy))
			continue
		if(faction_id_for(person) != faction_id)
			continue
		out += person
	return out

/datum/controller/subsystem/bonds/proc/best_allied_faction(faction_id)
	if(!faction_id)
		return null
	var/best_id
	var/best_warmth = 0
	for(var/other_id in faction_prototypes)
		if(other_id == faction_id)
			continue
		var/datum/bond_faction/other = faction_prototypes[other_id]
		if(istype(other, /datum/bond_faction/clan))
			continue
		var/warmth = stance_warmth(faction_id, other_id)
		if(warmth <= best_warmth)
			continue
		best_warmth = warmth
		best_id = other_id
	return best_id
