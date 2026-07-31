/datum/bonds_tree_panel
	var/mob/living/carbon/human/viewer

/datum/bonds_tree_panel/New(mob/living/carbon/human/new_viewer)
	viewer = new_viewer

/datum/bonds_tree_panel/Destroy(force)
	viewer = null
	return ..()

/datum/bonds_tree_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bonds_tree_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != viewer)
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BondsTree")
		ui.open()
	return TRUE

/datum/bonds_tree_panel/ui_data(mob/user)
	if(user != viewer || !viewer?.mind)
		return list("self" = null, "edges" = list())
	return SSbonds.build_bonds_tree(viewer)

/datum/bonds_tree_panel/ui_close()
	QDEL_NULL(src)

/datum/controller/subsystem/bonds/proc/build_bonds_tree(mob/living/carbon/human/person) as /list
	var/list/edges = list()
	for(var/datum/social_bond/bond as anything in get_bonds_for(person.mind))
		if(bond.weight < BOND_VISIBLE_WEIGHT)
			continue
		var/datum/social_bond/mirror = get_bond(bond.other, person.mind)
		edges += list(list(
			"name" = bond.display_name(),
			"accent" = bond.stage?.accent || "#8a8a8a",
			"outLabel" = bond.stage_label(),
			"outProgress" = round(bond.progress_to_next(), 0.01),
			"inLabel" = mirror ? mirror.stage_label() : null,
			"inProgress" = mirror ? round(mirror.progress_to_next(), 0.01) : 0,
			"inAccent" = mirror?.stage?.accent || "#5a5a5a",
		))
	return list(
		"self" = list(
			"name" = person.real_name,
			"accent" = "#d0c090",
		),
		"edges" = edges,
	)

/mob/living/carbon/human/verb/bonds_tree()
	set name = "Bonds Tree"
	set category = "Bonds"

	if(!mind)
		to_chat(src, span_warning("Вам некого вспоминать."))
		return
	var/datum/bonds_tree_panel/panel = new(src)
	panel.ui_interact(src)
