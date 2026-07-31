/datum/bond_faction
	abstract_type = /datum/bond_faction
	var/id = ""
	var/name = ""
	var/accent = "#8a8a8a"
	var/positions_key = ""
	var/icon_glyph = "users"
	var/list/extra_positions

/datum/bond_faction/proc/titles() as /list
	var/list/collected = list()
	if(positions_key)
		var/list/from_glob = GLOB.vars[positions_key]
		if(islist(from_glob))
			collected += from_glob
	if(length(extra_positions))
		collected += extra_positions
	return collected

/datum/controller/subsystem/bonds/proc/build_faction_index()
	faction_prototypes = list()
	faction_index = list()
	var/list/collisions = list()
	for(var/datum/bond_faction/faction_type as anything in typesof(/datum/bond_faction))
		if(IS_ABSTRACT(faction_type))
			continue
		var/datum/bond_faction/faction = new faction_type()
		faction_prototypes[faction.id] = faction
		for(var/title in faction.titles())
			if(!istext(title))
				continue
			if(faction_index[title])
				collisions += "[title] (already [faction_index[title]:id], now [faction.id])"
				continue
			faction_index[title] = faction
	if(length(collisions))
		bondlog("faction index collisions: [collisions.Join("; ")]", BONDLOG_WARN)
	bondlog("faction index built: [faction_prototypes.len] factions, [faction_index.len] titles", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/get_faction(faction_id)
	if(!faction_id)
		return null
	return faction_prototypes[faction_id]

/datum/controller/subsystem/bonds/proc/faction_for_title(title)
	if(!title)
		return null
	return faction_index[title]

/datum/controller/subsystem/bonds/proc/faction_for(mob/living/carbon/human/person)
	if(!ishuman(person))
		return null
	return faction_for_title(person.job)

/datum/controller/subsystem/bonds/proc/faction_id_for(mob/living/carbon/human/person)
	var/datum/bond_faction/faction = faction_for(person)
	return faction?.id

/datum/bond_faction/noble
	id = BOND_FACTION_NOBLE
	name = "Правящий дом"
	icon_glyph = "crown"
	accent = "#b08d3f"
	positions_key = "noble_positions"

/datum/bond_faction/court
	id = BOND_FACTION_COURT
	name = "Двор"
	icon_glyph = "scroll"
	accent = "#9a7fb0"
	positions_key = "courtier_positions"

/datum/bond_faction/retinue
	id = BOND_FACTION_RETINUE
	name = "Свита"
	icon_glyph = "chess-knight"
	accent = "#8a95b8"
	positions_key = "retinue_positions"

/datum/bond_faction/garrison
	id = BOND_FACTION_GARRISON
	name = "Гарнизон"
	icon_glyph = "shield-halved"
	accent = "#6f8fb0"
	positions_key = "garrison_positions"

/datum/bond_faction/citywatch
	id = BOND_FACTION_CITYWATCH
	name = "Городская стража"
	icon_glyph = "tower-observation"
	accent = "#5f7f9f"
	positions_key = "citywatch_positions"

/datum/bond_faction/vanguard
	id = BOND_FACTION_VANGUARD
	name = "Авангард"
	icon_glyph = "flag"
	accent = "#7a8f7a"
	positions_key = "vanguard_positions"

/datum/bond_faction/church
	id = BOND_FACTION_CHURCH
	name = "Церковь Десяти"
	icon_glyph = "place-of-worship"
	accent = "#c8b070"
	positions_key = "church_positions"

/datum/bond_faction/inquisition
	id = BOND_FACTION_INQUISITION
	name = "Инквизиция"
	icon_glyph = "gavel"
	accent = "#a05050"
	positions_key = "inquisition_positions"

/datum/bond_faction/burgher
	id = BOND_FACTION_BURGHER
	name = "Ремесленная Гильдия Азурии"
	icon_glyph = "hammer"
	accent = "#7fa06f"
	positions_key = "burgher_positions"

/datum/bond_faction/atc
	id = BOND_FACTION_ATC
	name = "Торговая Гильдия Астинии"
	icon_glyph = "coins"
	accent = "#6fa090"
	positions_key = "atc_positions"

/datum/bond_faction/peasant
	id = BOND_FACTION_PEASANT
	name = "Простолюдины"
	icon_glyph = "wheat-awn"
	accent = "#9a8f7a"
	positions_key = "peasant_positions"

/datum/bond_faction/sidefolk
	id = BOND_FACTION_SIDEFOLK
	name = "Вольные люди"
	icon_glyph = "user-group"
	accent = "#8f8f8f"
	positions_key = "sidefolk_positions"

/datum/bond_faction/wanderer
	id = BOND_FACTION_WANDERER
	name = "Странники"
	icon_glyph = "route"
	accent = "#8a7f6f"
	positions_key = "wanderer_positions"

/datum/bond_faction/outlaw
	id = BOND_FACTION_OUTLAW
	name = "Вне закона"
	icon_glyph = "skull"
	accent = "#8c3f3f"
	positions_key = "antagonist_positions"

/datum/faction_baseline
	abstract_type = /datum/faction_baseline
	var/faction_a = ""
	var/faction_b = ""
	var/warmth = 0
	var/weight = 0

/datum/faction_baseline/noble_court
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_COURT
	warmth = 45
	weight = 60

/datum/faction_baseline/noble_retinue
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_RETINUE
	warmth = 40
	weight = 55

/datum/faction_baseline/noble_peasant
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_PEASANT
	warmth = -20
	weight = 35

/datum/faction_baseline/retinue_garrison
	faction_a = BOND_FACTION_RETINUE
	faction_b = BOND_FACTION_GARRISON
	warmth = 30
	weight = 45

/datum/faction_baseline/garrison_citywatch
	faction_a = BOND_FACTION_GARRISON
	faction_b = BOND_FACTION_CITYWATCH
	warmth = -15
	weight = 50

/datum/faction_baseline/church_inquisition
	faction_a = BOND_FACTION_CHURCH
	faction_b = BOND_FACTION_INQUISITION
	warmth = -30
	weight = 70

/datum/faction_baseline/burgher_atc
	faction_a = BOND_FACTION_BURGHER
	faction_b = BOND_FACTION_ATC
	warmth = -20
	weight = 55

/datum/faction_baseline/burgher_peasant
	faction_a = BOND_FACTION_BURGHER
	faction_b = BOND_FACTION_PEASANT
	warmth = 15
	weight = 40

/datum/faction_baseline/church_peasant
	faction_a = BOND_FACTION_CHURCH
	faction_b = BOND_FACTION_PEASANT
	warmth = 25
	weight = 45

/datum/faction_baseline/garrison_outlaw
	faction_a = BOND_FACTION_GARRISON
	faction_b = BOND_FACTION_OUTLAW
	warmth = -70
	weight = 80

/datum/faction_baseline/citywatch_outlaw
	faction_a = BOND_FACTION_CITYWATCH
	faction_b = BOND_FACTION_OUTLAW
	warmth = -70
	weight = 80

/datum/faction_baseline/inquisition_outlaw
	faction_a = BOND_FACTION_INQUISITION
	faction_b = BOND_FACTION_OUTLAW
	warmth = -80
	weight = 75

/datum/faction_baseline/sidefolk_outlaw
	faction_a = BOND_FACTION_SIDEFOLK
	faction_b = BOND_FACTION_OUTLAW
	warmth = 20
	weight = 35

/datum/faction_baseline/sidefolk_citywatch
	faction_a = BOND_FACTION_SIDEFOLK
	faction_b = BOND_FACTION_CITYWATCH
	warmth = -30
	weight = 45

/datum/faction_baseline/wanderer_sidefolk
	faction_a = BOND_FACTION_WANDERER
	faction_b = BOND_FACTION_SIDEFOLK
	warmth = 20
	weight = 30

/datum/faction_stance
	var/faction_a
	var/faction_b
	var/warmth = 0
	var/weight = 0
	var/list/history
	var/created_at = 0
	var/updated_at = 0

/datum/faction_stance/New(id_a, id_b)
	faction_a = id_a
	faction_b = id_b
	created_at = world.time
	updated_at = world.time

/datum/faction_stance/Destroy(force)
	QDEL_LIST(history)
	history = null
	return ..()

/proc/bonds_stance_key(id_a, id_b)
	if(!id_a || !id_b)
		return null
	return (id_a < id_b) ? "[id_a]|[id_b]" : "[id_b]|[id_a]"

/datum/controller/subsystem/bonds/proc/get_stance(id_a, id_b)
	var/key = bonds_stance_key(id_a, id_b)
	if(!key)
		return null
	return faction_stances[key]

/datum/controller/subsystem/bonds/proc/get_or_create_stance(id_a, id_b)
	var/key = bonds_stance_key(id_a, id_b)
	if(!key || id_a == id_b)
		return null
	var/datum/faction_stance/stance = faction_stances[key]
	if(stance)
		return stance
	stance = new(id_a, id_b)
	faction_stances[key] = stance
	return stance

/datum/controller/subsystem/bonds/proc/stance_warmth(id_a, id_b)
	if(!id_a || !id_b)
		return 0
	if(id_a == id_b)
		return BOND_STANCE_SAME_FACTION_WARMTH
	var/datum/faction_stance/stance = get_stance(id_a, id_b)
	return stance ? stance.warmth : 0

/datum/controller/subsystem/bonds/proc/nudge_stance(id_a, id_b, warmth_delta = 0, weight_delta = 0, reason = "")
	var/datum/faction_stance/stance = get_or_create_stance(id_a, id_b)
	if(!stance)
		return null
	stance.warmth = clamp(stance.warmth + warmth_delta, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	stance.weight = clamp(stance.weight + weight_delta, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	stance.updated_at = world.time
	if(reason)
		var/datum/bond_history/entry = new()
		entry.label = "Фракции"
		entry.story = reason
		entry.created_at = world.time
		entry.warmth_delta = warmth_delta
		entry.weight_delta = weight_delta
		LAZYADD(stance.history, entry)
	return stance

/datum/controller/subsystem/bonds/proc/faction_affinity(mob/living/carbon/human/person_a, mob/living/carbon/human/person_b)
	var/id_a = faction_id_for(person_a)
	var/id_b = faction_id_for(person_b)
	if(!id_a || !id_b)
		return 0
	return stance_warmth(id_a, id_b)

/datum/controller/subsystem/bonds/proc/build_faction_stances()
	faction_stances = list()
	for(var/datum/faction_baseline/baseline_type as anything in typesof(/datum/faction_baseline))
		if(IS_ABSTRACT(baseline_type))
			continue
		var/datum/faction_baseline/baseline = new baseline_type()
		var/datum/faction_stance/stance = get_or_create_stance(baseline.faction_a, baseline.faction_b)
		if(!stance)
			bondlog("baseline [baseline_type] references an unknown faction pair", BONDLOG_WARN)
			qdel(baseline)
			continue
		stance.warmth = baseline.warmth
		stance.weight = baseline.weight
		qdel(baseline)
	bondlog("faction stances seeded: [faction_stances.len] pairs", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/apply_storyteller_lens()
	if(storyteller_lens_applied)
		return FALSE
	storyteller_lens_applied = TRUE
	var/datum/storyteller/teller = active_storyteller()
	if(!teller)
		bondlog("no storyteller at lens time; faction stances left as declared", BONDLOG_INFO)
		return FALSE
	for(var/key in faction_stances)
		var/datum/faction_stance/stance = faction_stances[key]
		var/lens = storyteller_weight(stance.faction_a, stance.faction_b)
		if(lens == 1)
			continue
		stance.warmth = clamp(stance.warmth * lens, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
		stance.weight = clamp(stance.weight * lens, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	bondlog("storyteller lens applied: [teller.type]", BONDLOG_INFO)
	return TRUE

/datum/bond_faction/clan
	abstract_type = /datum/bond_faction/clan
	var/clan_type

/datum/bond_faction/clan/titles()
	return list()

/datum/bond_faction/clan/caitiff
	id = BOND_CLAN_CAITIFF
	name = "Каитифы"
	icon_glyph = "user-slash"
	accent = "#6e6e6e"
	clan_type = /datum/clan

/datum/bond_faction/clan/abyss
	id = BOND_CLAN_ABYSS
	name = "Бездна"
	icon_glyph = "water"
	accent = "#4a3f6b"
	clan_type = /datum/clan/abyss

/datum/bond_faction/clan/crimson_fang
	id = BOND_CLAN_CRIMSON
	name = "Багряный клык"
	icon_glyph = "droplet"
	accent = "#8c2f3f"
	clan_type = /datum/clan/crimson_fang

/datum/bond_faction/clan/eoran
	id = BOND_CLAN_EORAN
	name = "Эоране"
	icon_glyph = "heart"
	accent = "#b07f9a"
	clan_type = /datum/clan/eoran

/datum/bond_faction/clan/nosferatu
	id = BOND_CLAN_NOSFERATU
	name = "Носферату"
	icon_glyph = "mask"
	accent = "#5f6b4a"
	clan_type = /datum/clan/nosferatu

/datum/bond_faction/clan/thronleer
	id = BOND_CLAN_THRONLEER
	name = "Тронлиры"
	icon_glyph = "chess-rook"
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

/datum/house_stance
	var/datum/heritage/house_a
	var/datum/heritage/house_b
	var/warmth = 0
	var/weight = 0
	var/incidents = 0
	var/list/history
	var/created_at = 0
	var/updated_at = 0

/datum/house_stance/New(datum/heritage/first, datum/heritage/second)
	house_a = first
	house_b = second
	created_at = world.time
	updated_at = world.time

/datum/house_stance/Destroy(force)
	QDEL_LIST(history)
	history = null
	house_a = null
	house_b = null
	return ..()

/proc/bonds_house_key(datum/heritage/first, datum/heritage/second)
	if(!first || !second || first == second)
		return null
	var/ref_a = REF(first)
	var/ref_b = REF(second)
	return (ref_a < ref_b) ? "[ref_a]|[ref_b]" : "[ref_b]|[ref_a]"

/datum/controller/subsystem/bonds/proc/get_house_stance(datum/heritage/first, datum/heritage/second)
	var/key = bonds_house_key(first, second)
	if(!key)
		return null
	return house_stances[key]

/datum/controller/subsystem/bonds/proc/get_or_create_house_stance(datum/heritage/first, datum/heritage/second)
	var/key = bonds_house_key(first, second)
	if(!key)
		return null
	var/datum/house_stance/stance = house_stances[key]
	if(stance)
		return stance
	stance = new(first, second)
	house_stances[key] = stance
	return stance

/datum/controller/subsystem/bonds/proc/nudge_house_stance(datum/heritage/first, datum/heritage/second, warmth_delta = 0, weight_delta = 0, reason = "")
	var/datum/house_stance/stance = get_or_create_house_stance(first, second)
	if(!stance)
		return null
	stance.warmth = clamp(stance.warmth + warmth_delta, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	stance.weight = clamp(stance.weight + weight_delta, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	stance.incidents++
	stance.updated_at = world.time
	if(reason)
		var/datum/bond_history/entry = new()
		entry.label = "Между домами"
		entry.story = reason
		entry.created_at = world.time
		entry.warmth_delta = warmth_delta
		entry.weight_delta = weight_delta
		LAZYADD(stance.history, entry)
		if(LAZYLEN(stance.history) > BOND_MAX_HISTORY)
			var/datum/bond_history/oldest = stance.history[1]
			stance.history -= oldest
			qdel(oldest)
	return stance

/datum/controller/subsystem/bonds/proc/house_of_mind(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	var/mob/living/carbon/human/body = actor?.current_body()
	if(!ishuman(body))
		return null
	return body.family_datum

/datum/controller/subsystem/bonds/proc/propagate_house_stance(subject, object, event_type)
	var/datum/bond_event/prototype = get_event_prototype(event_type)
	if(!prototype || !prototype.scored_propagation)
		return FALSE
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor)
		return FALSE
	var/datum/heritage/subject_house = house_of_mind(subject_actor)
	var/datum/heritage/object_house = house_of_mind(object_actor)
	if(!subject_house || !object_house || subject_house == object_house)
		return FALSE
	var/warmth_delta = prototype.warmth_commit * BOND_HOUSE_PROPAGATION
	var/weight_delta = abs(prototype.weight_commit) * BOND_HOUSE_PROPAGATION
	if(!warmth_delta && !weight_delta)
		return FALSE
	var/reason = "[subject_actor.name_of()] и [object_actor.name_of()]: [lowertext(prototype.history_label)]"
	nudge_house_stance(subject_house, object_house, warmth_delta, weight_delta, reason)
	bondlog("house stance [subject_house.housename] <-> [object_house.housename] moved by [warmth_delta]", BONDLOG_INFO)
	return TRUE

/datum/controller/subsystem/bonds/proc/house_stances_for(datum/heritage/house) as /list
	var/list/out = list()
	if(!house)
		return out
	for(var/key in house_stances)
		var/datum/house_stance/stance = house_stances[key]
		if(stance.house_a != house && stance.house_b != house)
			continue
		if(QDELETED(stance.house_a) || QDELETED(stance.house_b))
			continue
		out += stance
	return out

/datum/controller/subsystem/bonds/proc/other_house_in(datum/house_stance/stance, datum/heritage/house)
	if(!stance)
		return null
	return (stance.house_a == house) ? stance.house_b : stance.house_a
