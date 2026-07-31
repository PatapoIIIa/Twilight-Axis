// The faction map is deliberately NOT drawn from the viewer's point of view.
//
// A character does not have a personal relationship with an institution - what they can know is
// how the institutions stand toward each other. So this returns the whole graph: every faction
// as a node, every pair that has an actual standing as an edge. The viewer's own faction is
// only flagged so the panel can highlight it.

/datum/controller/subsystem/bonds/proc/build_faction_map(mob/living/carbon/human/viewer) as /list
	var/own_id = faction_id_for(viewer)
	var/list/nodes = list()
	var/list/ordered = list()

	for(var/faction_id in faction_prototypes)
		var/datum/bond_faction/faction = faction_prototypes[faction_id]
		if(istype(faction, /datum/bond_faction/clan))
			continue
		ordered += faction_id
		nodes += list(list(
			"id" = faction.id,
			"name" = faction.name,
			"accent" = faction.accent,
			"own" = (faction.id == own_id),
		))

	var/list/edges = list()
	for(var/i in 1 to length(ordered))
		for(var/j in (i + 1) to length(ordered))
			var/id_a = ordered[i]
			var/id_b = ordered[j]
			var/datum/faction_stance/stance = get_stance(id_a, id_b)
			if(!stance)
				continue
			if(!stance.warmth && stance.weight < BOND_MAP_MIN_WEIGHT)
				continue
			edges += list(list(
				"a" = id_a,
				"b" = id_b,
				"label" = bonds_stance_label(stance.warmth),
				"accent" = bonds_stance_accent(stance.warmth),
				"warmth" = round(stance.warmth),
				"weight" = round(stance.weight),
			))

	return list("nodes" = nodes, "edges" = edges)
