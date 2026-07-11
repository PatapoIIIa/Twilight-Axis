/datum/component/ataman_marked
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/weakref/marked_by_ref
	var/mutable_appearance/marker_overlay
	var/expire_timer

/datum/component/ataman_marked/Initialize(mob/living/carbon/human/marker, duration = 90 SECONDS)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(marker)
		marked_by_ref = WEAKREF(marker)

	var/mob/living/L = parent
	marker_overlay = mutable_appearance('icons/mob/mob_effects.dmi', "eff_exposed", ABOVE_MOB_LAYER)
	marker_overlay.pixel_y = 32
	marker_overlay.plane = ABOVE_LIGHTING_PLANE
	marker_overlay.alpha = 255
	marker_overlay.appearance_flags = RESET_ALPHA | RESET_COLOR
	L.add_overlay(marker_overlay)

	expire_timer = addtimer(CALLBACK(src, PROC_REF(expire)), duration, TIMER_STOPPABLE)

/datum/component/ataman_marked/proc/expire()
	qdel(src)

/datum/component/ataman_marked/proc/get_marker()
	if(!marked_by_ref)
		return null
	return marked_by_ref.resolve()

/datum/component/ataman_marked/Destroy()
	var/mob/living/L = parent
	if(L && marker_overlay)
		L.cut_overlay(marker_overlay)
	marker_overlay = null
	if(expire_timer)
		deltimer(expire_timer)
		expire_timer = null
	return ..()
