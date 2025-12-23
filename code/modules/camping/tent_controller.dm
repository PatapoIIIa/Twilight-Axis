/obj/structure/roguetent
	var/obj/structure/roguetent_controller/tent_controller

/obj/structure/roguetent/attack_right(mob/living/user)
	. = ..()
	if(.)
		return
	if(tent_controller)
		tent_controller.try_packup(user)

/obj/structure/roguetent_controller
	name = "tent controller"
	desc = ""
	icon = 'icons/obj/structures.dmi'
	icon_state = "invisible"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	invisibility = INVISIBILITY_MAXIMUM
	var/mob/owner
	var/list/created_parts
	var/list/part_max_integrity
	var/list/original_turfs
	var/kit_integrity = 0
	var/kit_max_integrity = 0

/obj/structure/roguetent_controller/proc/initialize_tent(mob/user, obj/item/tent_kit/kit, list/parts, list/part_max, list/originals)
	owner = user
	created_parts = parts
	part_max_integrity = part_max
	original_turfs = originals
	kit_integrity = kit?.obj_integrity || 0
	kit_max_integrity = kit?.max_integrity || 0

/obj/structure/roguetent_controller/proc/try_packup(mob/user)
	if(!user)
		return
	var/time_required = 2 MINUTES
	if(user == owner)
		time_required = 15 SECONDS
	user.visible_message(span_notice("[user] begins packing up the tent."))
	if(!do_after(user, time_required, TRUE, src))
		return
	if(QDELETED(src) || QDELETED(user))
		return
	packup(user)

/obj/structure/roguetent_controller/proc/packup(mob/user)
	var/total_max = 0
	var/total_current = 0
	for(var/atom/A as anything in part_max_integrity)
		var/part_max = part_max_integrity[A]
		if(isnull(part_max))
			continue
		total_max += part_max
		if(QDELETED(A))
			continue
		if(istype(A, /turf))
			if(istype(A, /turf/closed/wall/mineral/rogue/tent))
				total_current += A.obj_integrity
		else
			total_current += A.obj_integrity

	for(var/turf/T as anything in original_turfs)
		if(istype(T, /turf/closed/wall/mineral/rogue/tent))
			T.ChangeTurf(original_turfs[T], flags = CHANGETURF_INHERIT_AIR)

	for(var/atom/A as anything in created_parts)
		if(QDELETED(A))
			continue
		if(istype(A, /obj/structure/roguetent))
			var/obj/structure/roguetent/door = A
			door.tent_controller = null
		if(istype(A, /obj))
			qdel(A)

	var/obj/item/tent_kit/kit = new /obj/item/tent_kit(get_turf(src))
	if(total_max > 0 && kit_max_integrity > 0)
		var/ratio = total_current / total_max
		kit.obj_integrity = clamp(round(kit_integrity * ratio), 0, kit_max_integrity)
	qdel(src)
