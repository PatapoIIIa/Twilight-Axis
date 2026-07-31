/datum/social_bond/kin
	evictable = FALSE
	scored = FALSE
	var/kind = BOND_KIN_PARENT
	var/adopted = FALSE
	var/datum/heritage/house
	/// Only used by BOND_KIN_PRESERVED: the kinship term this side keeps calling the other,
	/// after the member who connected them left the house.
	var/preserved_label

/datum/social_bond/kin/Destroy(force)
	house = null
	return ..()

/datum/social_bond/kin/display_name()
	return snapshot?["name"] || other?.name_of() || "родич"

/proc/bonds_kin_reciprocal(kind)
	switch(kind)
		if(BOND_KIN_PARENT)
			return BOND_KIN_CHILD
		if(BOND_KIN_CHILD)
			return BOND_KIN_PARENT
	return kind

/proc/bonds_kin_is_parental(kind)
	return (kind == BOND_KIN_PARENT) || (kind == BOND_KIN_CHILD)

/datum/controller/subsystem/bonds/proc/find_kin(subject, object, kind)
	var/datum/bond_node/node = get_node(subject)
	var/datum/bond_actor/target = resolve_actor(object)
	if(!node || !target)
		return null
	for(var/datum/social_bond/kin/link as anything in node.kin)
		if(link.other != target)
			continue
		if(kind && link.kind != kind)
			continue
		return link
	return null

/datum/controller/subsystem/bonds/proc/kin_of_kind(subject, kind) as /list
	var/list/out = list()
	var/datum/bond_node/node = get_node(subject)
	if(!node)
		return out
	for(var/datum/social_bond/kin/link as anything in node.kin)
		if(kind && link.kind != kind)
			continue
		if(link.other && !(link.other in out))
			out += link.other
	return out

/datum/controller/subsystem/bonds/proc/kin_links_of_kind(subject, kind) as /list
	var/list/out = list()
	var/datum/bond_node/node = get_node(subject)
	if(!node)
		return out
	for(var/datum/social_bond/kin/link as anything in node.kin)
		if(kind && link.kind != kind)
			continue
		out += link
	return out

/datum/controller/subsystem/bonds/proc/add_kin_link(subject, object, kind, adopted = FALSE, datum/heritage/house)
	var/datum/bond_actor/subject_actor = resolve_actor(subject)
	var/datum/bond_actor/object_actor = resolve_actor(object)
	if(!subject_actor || !object_actor || subject_actor == object_actor)
		return null
	var/datum/social_bond/kin/existing = find_kin(subject_actor, object_actor, kind)
	if(existing)
		existing.adopted = adopted
		if(house)
			existing.house = house
		return existing
	var/datum/bond_node/node = get_or_create_node(subject_actor)
	if(!node)
		return null
	var/datum/social_bond/kin/link = new(subject_actor, object_actor)
	link.kind = kind
	link.adopted = adopted
	link.house = house
	node.add_kin(link)
	return link

/datum/controller/subsystem/bonds/proc/add_kin(subject, object, kind, adopted = FALSE, datum/heritage/house)
	if(!resolve_actor(subject) || !resolve_actor(object) || resolve_actor(subject) == resolve_actor(object))
		return null
	var/datum/social_bond/kin/forward = add_kin_link(subject, object, kind, adopted, house)
	add_kin_link(object, subject, bonds_kin_reciprocal(kind), adopted, house)
	return forward

/datum/controller/subsystem/bonds/proc/remove_kin(subject, object, kind)
	var/removed = FALSE
	var/datum/bond_node/subject_node = get_node(subject)
	if(subject_node && subject_node.remove_kin_to(resolve_actor(object), kind))
		removed = TRUE
	var/datum/bond_node/object_node = get_node(object)
	if(object_node && object_node.remove_kin_to(resolve_actor(subject), kind ? bonds_kin_reciprocal(kind) : null))
		removed = TRUE
	return removed

/datum/controller/subsystem/bonds/proc/set_kin_adopted(subject, object, kind, adopted)
	var/datum/social_bond/kin/forward = find_kin(subject, object, kind)
	var/datum/social_bond/kin/backward = find_kin(object, subject, bonds_kin_reciprocal(kind))
	if(!forward && !backward)
		return FALSE
	if(forward)
		forward.adopted = adopted
	if(backward)
		backward.adopted = adopted
	return TRUE

/datum/controller/subsystem/bonds/proc/retype_kin(subject, object, from_kind, to_kind, adopted)
	var/datum/social_bond/kin/link = find_kin(subject, object, from_kind)
	if(!link)
		return FALSE
	var/datum/heritage/kept_house = link.house
	remove_kin(subject, object, from_kind)
	add_kin(subject, object, to_kind, adopted, kept_house)
	return TRUE

/datum/controller/subsystem/bonds/proc/drop_kin_for_house(subject, datum/heritage/house)
	var/datum/bond_node/node = get_node(subject)
	if(!node || !house)
		return FALSE
	var/dropped = FALSE
	for(var/datum/social_bond/kin/link as anything in node.kin.Copy())
		if(link.house != house)
			continue
		remove_kin(subject, link.other, link.kind)
		dropped = TRUE
	return dropped

// spouse_mob predates the kin graph and is still read in ~30 places, but DM has no property
// getters, so it cannot simply become a proc. Instead the kin SPOUSE link is authoritative and
// spouse_mob is an explicit cache refreshed from it. Anything that changes a marriage should
// call this rather than assigning the var, so the two can no longer disagree.
/mob/living/carbon/human/proc/bonds_refresh_spouse_cache()
	if(!mind)
		return null
	var/list/spouses = SSbonds.kin_of_kind(mind, BOND_KIN_SPOUSE)
	if(!length(spouses))
		spouse_mob = null
		return null
	var/datum/bond_actor/first = spouses[1]
	spouse_mob = first.current_body()
	return spouse_mob

/// Breadth-first walk from `start` following one kin kind, looking for `target`.
/// Every ancestry question in the codebase is this walk with a different kind:
/// descendant-of is PARENT, ancestor-of is CHILD, and a parent cycle is "would the
/// candidate parent's ancestry already reach the child".
/datum/controller/subsystem/bonds/proc/kin_reaches(start, target, kind)
	var/datum/bond_actor/start_actor = resolve_actor(start)
	var/datum/bond_actor/target_actor = resolve_actor(target)
	if(!start_actor || !target_actor || start_actor == target_actor)
		return FALSE
	var/list/frontier = kin_of_kind(start_actor, kind)
	var/list/seen = list()
	seen[start_actor] = TRUE
	while(length(frontier))
		var/datum/bond_actor/current = frontier[1]
		frontier.Cut(1, 2)
		if(!current || seen[current])
			continue
		seen[current] = TRUE
		if(current == target_actor)
			return TRUE
		for(var/datum/bond_actor/next as anything in kin_of_kind(current, kind))
			if(!seen[next])
				frontier += next
	return FALSE

/datum/controller/subsystem/bonds/proc/kin_would_cycle(child, candidate_parent)
	var/datum/bond_actor/child_actor = resolve_actor(child)
	var/datum/bond_actor/parent_actor = resolve_actor(candidate_parent)
	if(!child_actor || !parent_actor)
		return FALSE
	if(child_actor == parent_actor)
		return TRUE
	return kin_reaches(parent_actor, child_actor, BOND_KIN_PARENT)
