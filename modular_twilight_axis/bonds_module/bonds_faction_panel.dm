/proc/bonds_stance_label(warmth)
	if(warmth >= 60)
		return "союз"
	if(warmth >= 25)
		return "дружба"
	if(warmth >= 10)
		return "приязнь"
	if(warmth <= -60)
		return "вражда"
	if(warmth <= -25)
		return "неприязнь"
	if(warmth <= -10)
		return "трения"
	return "нейтралитет"

/proc/bonds_stance_accent(warmth)
	if(warmth >= 25)
		return "#4c9f70"
	if(warmth >= 10)
		return "#7fb069"
	if(warmth <= -25)
		return "#b4553f"
	if(warmth <= -10)
		return "#c08a3e"
	return "#8a8a8a"

/proc/bonds_stance_intensity(weight)
	if(weight >= 60)
		return "тесно переплетены"
	if(weight >= 30)
		return "считаются друг с другом"
	return "почти не пересекаются"

/datum/bonds_faction_panel
	var/mob/living/carbon/human/viewer

/datum/bonds_faction_panel/New(mob/living/carbon/human/new_viewer)
	viewer = new_viewer

/datum/bonds_faction_panel/Destroy(force)
	viewer = null
	return ..()

/datum/bonds_faction_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bonds_faction_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != viewer)
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BondsFactions")
		ui.open()
	return TRUE

/datum/bonds_faction_panel/ui_data(mob/user)
	if(user != viewer)
		return list("ownFaction" = null, "map" = list("nodes" = list(), "edges" = list()), "ownHouse" = null, "houses" = list(), "ownClan" = null, "clans" = list())
	return SSbonds.build_faction_panel(viewer)

/datum/bonds_faction_panel/ui_close()
	QDEL_NULL(src)

/datum/controller/subsystem/bonds/proc/build_faction_panel(mob/living/carbon/human/person) as /list
	var/datum/bond_faction/own = faction_for(person)
	return list(
		"ownFaction" = own ? list("name" = own.name, "accent" = own.accent) : null,
		"map" = build_faction_map(person),
		"ownHouse" = person.family_datum?.GetDisplayHouseTitle(),
		"houses" = build_house_panel(person),
		"ownClan" = clan_faction_for(person)?.name,
		"clans" = build_clan_panel(person),
	)

/datum/controller/subsystem/bonds/proc/build_house_panel(mob/living/carbon/human/person) as /list
	var/list/out = list()
	var/datum/heritage/own = person?.family_datum
	if(!own)
		return out
	for(var/datum/house_stance/stance as anything in house_stances_for(own))
		var/datum/heritage/other = other_house_in(stance, own)
		if(!other)
			continue
		out += list(list(
			"name" = other.GetDisplayHouseTitle() || other.housename || "безымянный дом",
			"label" = bonds_stance_label(stance.warmth),
			"labelAccent" = bonds_stance_accent(stance.warmth),
			"intensity" = bonds_stance_intensity(stance.weight),
			"incidents" = stance.incidents,
		))
	return out

/mob/living/carbon/human/verb/bonds_factions()
	set name = "Faction Standing"
	set category = "Bonds"

	if(!SSbonds.faction_for(src) && !family_datum && !SSbonds.clan_faction_for(src))
		to_chat(src, span_notice("Вы не представляете никого, кроме себя."))
		return
	var/datum/bonds_faction_panel/panel = new(src)
	panel.ui_interact(src)
