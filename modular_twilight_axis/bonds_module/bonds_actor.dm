/datum/bond_actor
	var/datum/mind/mind
	var/datum/family_member/phantom_member
	var/cached_name = "someone"
	var/cached_origin_id

/datum/bond_actor/Destroy(force)
	mind = null
	phantom_member = null
	return ..()

/datum/bond_actor/proc/name_of()
	if(mind?.name)
		return mind.name
	var/mob/living/carbon/human/body = current_body()
	if(body?.real_name)
		return body.real_name
	return cached_name

/datum/bond_actor/proc/current_body()
	if(mind?.current)
		return mind.current
	return phantom_member?.person

/datum/bond_actor/proc/family_member_of()
	if(phantom_member)
		return phantom_member
	var/mob/living/carbon/human/body = current_body()
	return body?.family_member_datum

/datum/bond_actor/proc/is_phantom()
	return !isnull(phantom_member)

/datum/controller/subsystem/bonds/proc/actor_for_mind(datum/mind/subject)
	if(!subject)
		return null
	var/datum/bond_actor/actor = actors_by_mind[subject]
	if(actor)
		return actor
	actor = new()
	actor.mind = subject
	actor.cached_name = subject.name || "someone"
	actors_by_mind[subject] = actor
	return actor

/datum/controller/subsystem/bonds/proc/actor_for_phantom(datum/family_member/member)
	if(!member)
		return null
	var/datum/bond_actor/actor = actors_by_phantom[member]
	if(actor)
		return actor
	actor = new()
	actor.phantom_member = member
	actor.cached_name = member.person?.real_name || "родич"
	actors_by_phantom[member] = actor
	return actor

/datum/controller/subsystem/bonds/proc/resolve_actor(thing)
	if(!thing)
		return null
	if(istype(thing, /datum/bond_actor))
		return thing
	if(istype(thing, /datum/mind))
		return actor_for_mind(thing)
	if(istype(thing, /datum/family_member))
		var/datum/family_member/member = thing
		if(member.phantom || member.cosmetic || !member.person?.mind)
			return actor_for_phantom(member)
		return actor_for_mind(member.person.mind)
	if(ishuman(thing))
		var/mob/living/carbon/human/body = thing
		if(!body.mind)
			return null
		return actor_for_mind(body.mind)
	return null

/datum/controller/subsystem/bonds/proc/drop_actor(datum/bond_actor/actor)
	if(!actor)
		return FALSE
	if(actor.mind)
		actors_by_mind -= actor.mind
	if(actor.phantom_member)
		actors_by_phantom -= actor.phantom_member
	drop_node(actor)
	qdel(actor)
	return TRUE
