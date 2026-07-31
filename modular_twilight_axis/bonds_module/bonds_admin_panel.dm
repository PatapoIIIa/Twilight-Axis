/datum/bonds_admin_panel
	var/client/holder

/datum/bonds_admin_panel/New(client/new_holder)
	holder = new_holder

/datum/bonds_admin_panel/Destroy(force)
	holder = null
	return ..()

/datum/bonds_admin_panel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/bonds_admin_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BondsAdmin")
		ui.open()
	return TRUE

/datum/bonds_admin_panel/ui_data(mob/user)
	return SSbonds.build_admin_data()

/datum/bonds_admin_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights_for(ui.user.client, R_ADMIN))
		return FALSE

	switch(action)
		if("set_stance")
			var/id_a = params["a"]
			var/id_b = params["b"]
			var/warmth = params["warmth"]
			var/weight = params["weight"]
			if(!istext(id_a) || !istext(id_b) || !isnum(warmth) || !isnum(weight))
				return FALSE
			if(!SSbonds.get_faction(id_a) || !SSbonds.get_faction(id_b))
				return FALSE
			var/datum/faction_stance/stance = SSbonds.get_or_create_stance(id_a, id_b)
			if(!stance)
				return FALSE
			stance.warmth = clamp(round(warmth), BOND_WARMTH_MIN, BOND_WARMTH_MAX)
			stance.weight = clamp(round(weight), BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
			stance.updated_at = world.time
			log_admin("[key_name(ui.user)] set bond stance [id_a]/[id_b] to warmth [stance.warmth] weight [stance.weight]")
			SSbonds.bondlog("admin [key_name(ui.user)] set [id_a]/[id_b] warmth=[stance.warmth] weight=[stance.weight]", BONDLOG_WARN)
			return TRUE

		if("reset_stance")
			var/id_a = params["a"]
			var/id_b = params["b"]
			var/key = bonds_stance_key(id_a, id_b)
			if(!key || !SSbonds.faction_stances[key])
				return FALSE
			var/datum/faction_stance/stance = SSbonds.faction_stances[key]
			SSbonds.faction_stances -= key
			qdel(stance)
			log_admin("[key_name(ui.user)] cleared bond stance [id_a]/[id_b]")
			return TRUE

	return FALSE

/datum/bonds_admin_panel/ui_close()
	QDEL_NULL(src)

/datum/controller/subsystem/bonds/proc/build_admin_data() as /list
	var/list/factions = list()
	for(var/faction_id in faction_prototypes)
		var/datum/bond_faction/faction = faction_prototypes[faction_id]
		factions += list(list(
			"id" = faction.id,
			"name" = faction.name,
			"accent" = faction.accent,
			"clan" = istype(faction, /datum/bond_faction/clan),
		))

	var/list/stances = list()
	for(var/key in faction_stances)
		var/datum/faction_stance/stance = faction_stances[key]
		var/datum/bond_faction/faction_a = faction_prototypes[stance.faction_a]
		var/datum/bond_faction/faction_b = faction_prototypes[stance.faction_b]
		if(!faction_a || !faction_b)
			continue
		stances += list(list(
			"a" = stance.faction_a,
			"b" = stance.faction_b,
			"nameA" = faction_a.name,
			"nameB" = faction_b.name,
			"warmth" = round(stance.warmth),
			"weight" = round(stance.weight),
			"label" = bonds_stance_label(stance.warmth),
			"labelAccent" = bonds_stance_accent(stance.warmth),
			"history" = LAZYLEN(stance.history),
		))

	var/list/houses = list()
	for(var/key in house_stances)
		var/datum/house_stance/stance = house_stances[key]
		if(QDELETED(stance.house_a) || QDELETED(stance.house_b))
			continue
		houses += list(list(
			"nameA" = stance.house_a.housename || "безымянный",
			"nameB" = stance.house_b.housename || "безымянный",
			"warmth" = round(stance.warmth),
			"weight" = round(stance.weight),
			"incidents" = stance.incidents,
			"label" = bonds_stance_label(stance.warmth),
			"labelAccent" = bonds_stance_accent(stance.warmth),
		))

	var/datum/storyteller/teller = active_storyteller()
	return list(
		"factions" = factions,
		"stances" = stances,
		"houses" = houses,
		"storyteller" = teller ? "[teller.type]" : null,
		"mapName" = SSmapping?.config?.map_name,
		"warmthMin" = BOND_WARMTH_MIN,
		"warmthMax" = BOND_WARMTH_MAX,
		"weightMax" = BOND_WEIGHT_MAX,
	)

/client/proc/bonds_admin_panel()
	set name = "Bonds: Faction Relations"
	set category = "Admin.Game"

	if(!check_rights(R_ADMIN))
		return
	var/datum/bonds_admin_panel/panel = new(src)
	panel.ui_interact(mob)
