GLOBAL_LIST_INIT(tent_blueprints, build_tent_blueprints())

/proc/build_tent_blueprints()
	var/list/blueprints = list()
	for(var/path in subtypesof(/datum/tent_blueprint))
		if(path == /datum/tent_blueprint)
			continue
		var/datum/tent_blueprint/blueprint = new path
		blueprints[blueprint.id] = blueprint
	return blueprints

/datum/tent_blueprint
	var/id = "base"
	var/name = "tent blueprint"
	var/list/floor_offsets
	var/list/wall_offsets
	var/list/roof_offsets
	var/list/door_offset

/datum/tent_blueprint/New()
	. = ..()
	if(!floor_offsets)
		floor_offsets = list()
	if(!wall_offsets)
		wall_offsets = list()
	if(!roof_offsets)
		roof_offsets = list()
	if(!door_offset)
		door_offset = list(0, -1)

/datum/tent_blueprint/small
	id = "small"
	name = "small tent"

/datum/tent_blueprint/small/New()
	. = ..()
	door_offset = list(0, -1)
	floor_offsets = list(
		list(-1, -1), list(0, -1), list(1, -1),
		list(-1, 0), list(0, 0), list(1, 0),
		list(-1, 1), list(0, 1), list(1, 1)
	)
	wall_offsets = list(
		list(-1, -1), list(1, -1),
		list(-1, 0), list(1, 0),
		list(-1, 1), list(0, 1), list(1, 1)
	)
	roof_offsets = list(
		list(-1, -1), list(0, -1), list(1, -1),
		list(-1, 0), list(0, 0), list(1, 0),
		list(-1, 1), list(0, 1), list(1, 1)
	)
