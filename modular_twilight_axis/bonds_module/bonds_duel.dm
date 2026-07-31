/datum/controller/subsystem/bonds/proc/is_sanctioned_duel(mob/living/carbon/human/actor, mob/living/carbon/human/target)
	if(!ishuman(actor) || !ishuman(target))
		return FALSE
	if(actor.has_duelist_ring() && target.has_duelist_ring())
		return TRUE
	if(!zone_weight(actor))
		return TRUE
	return FALSE
