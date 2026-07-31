/datum/controller/subsystem/bonds/proc/get_node(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	if(!actor)
		return null
	return nodes[actor]

/datum/controller/subsystem/bonds/proc/get_or_create_node(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	if(!actor)
		return null
	var/datum/bond_node/node = nodes[actor]
	if(node)
		return node
	node = new(actor)
	nodes[actor] = node
	return node

/datum/controller/subsystem/bonds/proc/drop_node(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	var/datum/bond_node/node = actor ? nodes[actor] : null
	if(!node)
		return FALSE
	nodes -= actor
	qdel(node)
	return TRUE

/datum/controller/subsystem/bonds/proc/get_bond(subject, object)
	var/datum/bond_node/node = get_node(subject)
	if(!node)
		return null
	return node.get_bond(resolve_actor(object))

/datum/controller/subsystem/bonds/proc/get_or_create_bond(subject, object)
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor || subject_actor == object_actor)
		return null
	var/datum/bond_node/node = get_or_create_node(subject_actor)
	if(!node)
		return null
	var/datum/social_bond/bond = node.get_bond(object_actor)
	if(bond)
		return bond
	bond = new(subject_actor, object_actor)
	return node.add_bond(bond)

/datum/controller/subsystem/bonds/proc/record(subject, object, event_type, mob/living/carbon/human/object_mob, force = FALSE, applied_scale = 1)
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor || subject_actor == object_actor)
		return null
	if(!force && !bonds_identity_visible(object_mob) && !get_bond(subject_actor, object_actor))
		return null
	var/datum/bond_event/prototype = get_event_prototype(event_type)
	if(!prototype)
		bondlog("record() unknown event type [event_type]", BONDLOG_ERROR)
		return null
	if(!prototype.can_apply(subject_actor, object_actor))
		return null
	var/datum/social_bond/bond = get_or_create_bond(subject_actor, object_actor)
	if(!bond)
		return null
	bondlog("record [subject_actor.name_of()] -> [object_actor.name_of()] [event_type]")
	return bond.attach_event(event_type, applied_scale)

/datum/controller/subsystem/bonds/proc/get_bonds_for(participant)
	var/datum/bond_node/node = get_node(participant)
	if(!node)
		return list()
	return node.sorted_bonds()
