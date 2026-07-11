#define ATAMAN_MAX_ACTIVE_AMBUSHES 3

/mob/living/carbon/human
	var/list/ataman_active_ambushes

/proc/ataman_turf_has_trap(turf/target_turf)
	if(!target_turf)
		return FALSE
	if(locate(/obj/structure/trap) in target_turf)
		return TRUE
	if(locate(/obj/item/restraints/legcuffs/beartrap) in target_turf)
		return TRUE
	return FALSE

/proc/ataman_active_ambush_count(mob/living/carbon/human/owner)
	if(!owner)
		return 0
	LAZYINITLIST(owner.ataman_active_ambushes)
	for(var/datum/weakref/ambush_ref as anything in owner.ataman_active_ambushes.Copy())
		var/obj/structure/trap/ataman_ambush_stone/ambush = ambush_ref.resolve()
		if(QDELETED(ambush))
			owner.ataman_active_ambushes -= ambush_ref
	return length(owner.ataman_active_ambushes)

/proc/ataman_register_ambush(mob/living/carbon/human/owner, obj/structure/trap/ataman_ambush_stone/ambush)
	if(!owner || !ambush)
		return
	LAZYINITLIST(owner.ataman_active_ambushes)
	owner.ataman_active_ambushes += WEAKREF(ambush)

/// Keeps the real trap completely hidden while giving its owner a normal, clickable image.
/datum/component/ataman_trap_owner_view
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/weakref/owner_ref
	var/image/owner_image
	var/client/viewing_client

/datum/component/ataman_trap_owner_view/Initialize(mob/living/carbon/human/trap_owner)
	if(!isobj(parent) || !istype(trap_owner))
		return COMPONENT_INCOMPATIBLE
	owner_ref = WEAKREF(trap_owner)
	RegisterSignal(trap_owner, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_owner_login))
	show_to_owner()

/datum/component/ataman_trap_owner_view/proc/on_owner_login(mob/living/source, client/new_client)
	SIGNAL_HANDLER
	show_to_owner()

/datum/component/ataman_trap_owner_view/proc/show_to_owner()
	hide_from_old_client()
	var/mob/living/carbon/human/trap_owner = owner_ref?.resolve()
	var/obj/trap = parent
	if(!trap_owner?.client || QDELETED(trap))
		return
	owner_image = image(icon = trap.icon, loc = trap, icon_state = trap.icon_state, layer = trap.layer, dir = trap.dir)
	owner_image.appearance = trap.appearance
	owner_image.alpha = 255
	owner_image.appearance_flags |= RESET_ALPHA
	owner_image.mouse_opacity = MOUSE_OPACITY_ICON
	viewing_client = trap_owner.client
	viewing_client.images += owner_image

/datum/component/ataman_trap_owner_view/proc/hide_from_old_client()
	if(viewing_client && owner_image)
		viewing_client.images -= owner_image
	viewing_client = null
	owner_image = null

/datum/component/ataman_trap_owner_view/Destroy()
	var/mob/living/carbon/human/trap_owner = owner_ref?.resolve()
	if(trap_owner)
		UnregisterSignal(trap_owner, COMSIG_MOB_CLIENT_LOGIN)
	hide_from_old_client()
	owner_ref = null
	return ..()

