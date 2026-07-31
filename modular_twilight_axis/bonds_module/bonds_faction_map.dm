/datum/controller/subsystem/bonds/proc/build_faction_map(mob/living/carbon/human/viewer) as /list
	var/own_id = faction_id_for(viewer)
	var/list/nodes = list()
	var/list/ordered = list()

	for(var/faction_id in present_faction_ids())
		var/datum/bond_faction/faction = faction_prototypes[faction_id]
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
			var/warmth = stance ? stance.warmth : 0
			var/weight = stance ? stance.weight : 0
			edges += list(list(
				"a" = id_a,
				"b" = id_b,
				"label" = bonds_stance_label(warmth),
				"accent" = bonds_stance_accent(warmth),
				"warmth" = round(warmth),
				"weight" = round(weight),
				"declared" = (!isnull(stance) && (warmth || weight >= BOND_MAP_MIN_WEIGHT)),
			))

	return list("nodes" = nodes, "edges" = edges)
