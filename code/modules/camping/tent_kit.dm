/obj/item/tent_kit
	name = "tent kit"
	desc = "A bundled kit of poles and fabric meant for quick shelter."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "bedroll_r"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK
	grid_width = 32
	grid_height = 64
	max_integrity = 100
	var/build_time = 15 SECONDS
	var/blueprint_id = "small"

/obj/item/tent_kit/attack_self(mob/user, params)
	. = ..()
	if(item_flags & IN_STORAGE)
		to_chat(user, span_warning("I need to set [src] down before deploying it."))
		return
	var/datum/tent_blueprint/blueprint = GLOB.tent_blueprints[blueprint_id]
	if(!blueprint)
		to_chat(user, span_warning("[src] lacks any usable tent plans."))
		return
	var/cardinal_dir = get_cardinal_dir(user.dir)
	var/turf/center = get_step(user, cardinal_dir)
	if(!center)
		return
	var/door_dir = turn(cardinal_dir, 180)
	if(!can_deploy_tent(center, door_dir, user, blueprint))
		return
	user.visible_message(span_notice("[user] begins setting up [src]."))
	if(!do_after(user, build_time, TRUE, src))
		return
	if(QDELETED(src) || QDELETED(user))
		return
	if(!can_deploy_tent(center, door_dir, user, blueprint))
		to_chat(user, span_warning("The ground shifts, and there is no longer enough space for [src]."))
		return
	deploy_tent(center, door_dir, user, blueprint)
	qdel(src)

/obj/item/tent_kit/proc/get_cardinal_dir(dir)
	if(dir in GLOB.cardinals)
		return dir
	return SOUTH

/obj/item/tent_kit/proc/rotate_offset(dx, dy, dir)
	switch(dir)
		if(NORTH)
			return list(-dx, -dy)
		if(EAST)
			return list(-dy, dx)
		if(WEST)
			return list(dy, -dx)
	return list(dx, dy)

/obj/item/tent_kit/proc/get_rotated_offsets(list/offsets, dir)
	var/list/rotated = list()
	for(var/offset in offsets)
		var/list/entry = offset
		var/list/new_offset = rotate_offset(entry[1], entry[2], dir)
		rotated += list(new_offset)
	return rotated

/obj/item/tent_kit/proc/get_rotated_offset(list/offset, dir)
	return rotate_offset(offset[1], offset[2], dir)

/obj/item/tent_kit/proc/get_turf_from_offset(turf/center, list/offset)
	return locate(center.x + offset[1], center.y + offset[2], center.z)

/obj/item/tent_kit/proc/is_tent_floor(turf/T)
	return istype(T, /turf/open/floor/rogue)

/obj/item/tent_kit/proc/is_empty_turf(turf/T)
	for(var/atom/movable/A as anything in T)
		return FALSE
	return TRUE

/obj/item/tent_kit/proc/is_hazardous_turf(turf/T)
	if(istype(T, /turf/open/lava))
		return TRUE
	if(istype(T, /turf/open/water))
		return TRUE
	if(istype(T, /turf/open/transparent/openspace))
		return TRUE
	return FALSE

/obj/item/tent_kit/proc/turf_blocked(turf/T)
	for(var/atom/movable/A in T)
		if(ismob(A))
			return TRUE
		if(istype(A, /obj/structure) || istype(A, /obj/machinery) || istype(A, /obj/vehicle))
			return TRUE
		if(A.density && !(A.flags_1 & ON_BORDER_1))
			return TRUE
	return FALSE

/obj/item/tent_kit/proc/has_ceiling(turf/T)
	var/turf/above = get_step_multiz(T, UP)
	if(!above)
		return TRUE
	return !istype(above, /turf/open/transparent/openspace)

/obj/item/tent_kit/proc/has_foliage_above(turf/T)
	var/turf/above = get_step_multiz(T, UP)
	if(!above)
		return FALSE
	if(istype(above, /turf/closed/wall/shroud))
		return TRUE
	for(var/obj/structure/flora/newleaf/leaf as anything in above)
		return TRUE
	return FALSE

/obj/item/tent_kit/proc/can_deploy_tent(turf/center, door_dir, mob/user, datum/tent_blueprint/blueprint)
	var/list/floor_offsets = get_rotated_offsets(blueprint.floor_offsets, door_dir)
	for(var/offset in floor_offsets)
		var/turf/T = get_turf_from_offset(center, offset)
		if(!T)
			to_chat(user, span_warning("There's not enough space to deploy [src] here."))
			return FALSE
		if(!is_tent_floor(T) || T.is_blocked_turf(TRUE))
			to_chat(user, span_warning("I need solid, open ground to pitch [src]."))
			return FALSE
		if(is_hazardous_turf(T))
			to_chat(user, span_warning("The ground here is too hazardous to pitch [src]."))
			return FALSE
		if(!is_empty_turf(T) || turf_blocked(T))
			to_chat(user, span_warning("There is not enough empty space to set [src] up."))
			return FALSE
	var/list/door_offset = get_rotated_offset(blueprint.door_offset, door_dir)
	var/turf/door_turf = get_turf_from_offset(center, door_offset)
	if(!door_turf)
		to_chat(user, span_warning("There's not enough room to place a door here."))
		return FALSE
	if(!is_empty_turf(door_turf) || door_turf.is_blocked_turf(TRUE))
		to_chat(user, span_warning("There is not enough empty space to place the door."))
		return FALSE
	var/list/roof_offsets = get_rotated_offsets(blueprint.roof_offsets, door_dir)
	for(var/offset in roof_offsets)
		var/turf/T = get_turf_from_offset(center, offset)
		if(!T || has_ceiling(T))
			continue
		if(has_foliage_above(T))
			to_chat(user, span_warning("Leaves above make it impossible to raise the canopy."))
			return FALSE
	return TRUE

/obj/item/tent_kit/proc/deploy_tent(turf/center, door_dir, mob/user, datum/tent_blueprint/blueprint)
	var/list/wall_offsets = get_rotated_offsets(blueprint.wall_offsets, door_dir)
	var/list/roof_offsets = get_rotated_offsets(blueprint.roof_offsets, door_dir)
	var/list/door_offset = get_rotated_offset(blueprint.door_offset, door_dir)
	var/turf/door_turf = get_turf_from_offset(center, door_offset)

	var/list/original_turfs = list()
	var/list/created_parts = list()
	var/list/part_max_integrity = list()
	for(var/offset in wall_offsets)
		var/turf/T = get_turf_from_offset(center, offset)
		if(!T)
			continue
		original_turfs[T] = T.type
		T.ChangeTurf(/turf/closed/wall/mineral/rogue/tent, flags = CHANGETURF_INHERIT_AIR)
		created_parts += T
		part_max_integrity[T] = T.max_integrity

	var/obj/structure/roguetent/door = null
	if(door_turf)
		door = new /obj/structure/roguetent(door_turf)
		created_parts += door
		part_max_integrity[door] = door.max_integrity

	for(var/offset in roof_offsets)
		var/turf/T = get_turf_from_offset(center, offset)
		if(!T || has_ceiling(T))
			continue
		var/obj/structure/fluff/canopy/canopy = new /obj/structure/fluff/canopy(T)
		created_parts += canopy
		part_max_integrity[canopy] = canopy.max_integrity

	var/obj/structure/roguetent_controller/controller = new /obj/structure/roguetent_controller(center)
	controller.initialize_tent(user, src, created_parts, part_max_integrity, original_turfs)
	if(door)
		door.tent_controller = controller
