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

/proc/ataman_bandit_belongs_to(atom/movable/AM, mob/living/carbon/human/owner)
	if(!owner || !istype(AM, /mob/living/carbon/human/npc/ataman_bandit))
		return FALSE
	var/mob/living/carbon/human/npc/ataman_bandit/bandit = AM
	return bandit.ataman_owner_ref?.resolve() == owner
