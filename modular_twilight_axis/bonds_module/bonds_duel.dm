// Sanctioned violence.
//
// Two warriors who agree to fight, beat each other bloody and then embrace over the result have
// not damaged their relationship - they have built one. Treating that as assault made the whole
// system read fighters as enemies of everyone they ever sparred with, which is exactly backwards.
//
// A fight is sanctioned when either both parties wear a duellist's ring (the codebase already
// uses this signal for "explicitly, hopefully non-lethally duelling" in rmb_intents.dm) or it
// happens on consecrated duelling ground.
//
// Sanctioned violence is not merely neutral for factions - it also must not sour the personal
// bond, so the check sits in front of both.

/datum/controller/subsystem/bonds/proc/is_sanctioned_duel(mob/living/carbon/human/actor, mob/living/carbon/human/target)
	if(!ishuman(actor) || !ishuman(target))
		return FALSE
	if(actor.has_duelist_ring() && target.has_duelist_ring())
		return TRUE
	if(!zone_weight(actor))
		return TRUE
	return FALSE
