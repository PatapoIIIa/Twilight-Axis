/datum/social_bond
	/// FALSE for structural links that must never be dropped by the node cap.
	var/evictable = TRUE
	/// FALSE for links that carry no sentiment: axes and stages do not apply.
	var/scored = TRUE
	var/datum/bond_actor/holder
	var/datum/bond_actor/other
	var/warmth = 0
	var/weight = 0
	var/warmth_committed = 0
	var/weight_committed = 0
	var/tags = BOND_TAG_NONE
	var/list/active_events
	var/list/commit_times
	var/list/commit_counts
	var/list/history
	var/list/snapshot
	var/datum/bond_stage/stage
	var/created_at = 0
	var/updated_at = 0

/datum/social_bond/New(datum/bond_actor/new_holder, datum/bond_actor/new_other)
	holder = new_holder
	other = new_other
	created_at = world.time
	updated_at = world.time
	refresh_snapshot()
	recalculate()

/datum/social_bond/Destroy(force)
	if(active_events)
		for(var/category as anything in active_events)
			var/datum/bond_event/event = active_events[category]
			event.bond = null
		QDEL_LIST_ASSOC_VAL(active_events)
	if(history)
		QDEL_LIST(history)
	active_events = null
	commit_times = null
	commit_counts = null
	history = null
	snapshot = null
	holder = null
	other = null
	return ..()

/datum/social_bond/proc/refresh_snapshot()
	var/list/built = bonds_build_snapshot(other?.current_body())
	if(built)
		snapshot = built

/datum/social_bond/proc/display_name()
	return snapshot?["name"] || other?.name_of() || "someone"

/datum/social_bond/proc/recalculate()
	if(!scored)
		updated_at = world.time
		return
	var/new_warmth = warmth_committed
	var/new_weight = weight_committed
	for(var/category as anything in active_events)
		var/datum/bond_event/event = active_events[category]
		new_warmth += event.warmth_transient
		new_weight += event.weight_transient
	warmth = clamp(new_warmth, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	weight = clamp(new_weight, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	stage = SSbonds.resolve_stage(src)
	updated_at = world.time

/datum/social_bond/proc/stage_label()
	return stage?.label || "Незнакомец"

/datum/social_bond/proc/stage_group()
	return stage?.category || BOND_GROUP_KNOWN

// The cheapest stage strictly above the current one that lies in the same emotional direction.
// Null means this bond is already as far as it goes on its current course.
/datum/social_bond/proc/next_stage()
	var/current_priority = stage ? stage.priority : 0
	var/datum/bond_stage/best
	for(var/datum/bond_stage/candidate as anything in SSbonds.stage_prototypes)
		if(candidate.priority <= current_priority)
			continue
		if(warmth >= 0 && candidate.warmth_max < 0)
			continue
		if(warmth < 0 && candidate.warmth_min > 0)
			continue
		if(!best || candidate.priority < best.priority)
			best = candidate
	return best

/// 0..1 progress toward next_stage(), gated by whichever requirement is furthest away.
/datum/social_bond/proc/progress_to_next()
	var/datum/bond_stage/upcoming = next_stage()
	if(!upcoming)
		return 1
	var/warmth_progress = 1
	if(warmth >= 0 && upcoming.warmth_min > 0)
		warmth_progress = clamp(warmth / upcoming.warmth_min, 0, 1)
	else if(warmth < 0 && upcoming.warmth_max < 0)
		warmth_progress = clamp(warmth / upcoming.warmth_max, 0, 1)
	var/weight_progress = 1
	if(upcoming.weight_min > 0)
		weight_progress = clamp(weight / upcoming.weight_min, 0, 1)
	return min(warmth_progress, weight_progress)

/datum/social_bond/proc/can_commit(category)
	if(!commit_times)
		return TRUE
	var/last = commit_times[category]
	if(isnull(last))
		return TRUE
	return (world.time - last) >= BOND_COMMIT_COOLDOWN

/datum/social_bond/proc/commit_scale(category)
	if(!commit_counts)
		return 1
	var/count = commit_counts[category]
	if(!count)
		return 1
	return 1 / (1 + (count * BOND_COMMIT_FALLOFF))

/datum/social_bond/proc/commit(datum/bond_event/prototype)
	var/scale = commit_scale(prototype.category)
	warmth_committed = clamp(warmth_committed + (prototype.warmth_commit * scale), BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	weight_committed = clamp(weight_committed + (prototype.weight_commit * scale), BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	LAZYINITLIST(commit_times)
	LAZYINITLIST(commit_counts)
	commit_times[prototype.category] = world.time
	commit_counts[prototype.category] = (commit_counts[prototype.category] || 0) + 1
	return scale

/datum/social_bond/proc/add_history(datum/bond_event/prototype, scale = 0)
	var/datum/bond_history/entry = new()
	entry.label = prototype.history_label
	entry.story = prototype.build_story(src)
	entry.created_at = world.time
	entry.warmth_delta = round(prototype.warmth_commit * scale, 0.1)
	entry.weight_delta = round(prototype.weight_commit * scale, 0.1)
	entry.pinned = (prototype.tag_applied != BOND_TAG_NONE)
	LAZYADD(history, entry)
	trim_history()
	return entry

/datum/social_bond/proc/trim_history()
	if(LAZYLEN(history) <= BOND_MAX_HISTORY)
		return
	for(var/datum/bond_history/entry as anything in history.Copy())
		if(entry.pinned)
			continue
		history -= entry
		qdel(entry)
		if(LAZYLEN(history) <= BOND_MAX_HISTORY)
			return
	while(LAZYLEN(history) > BOND_MAX_HISTORY)
		var/datum/bond_history/oldest = history[1]
		history -= oldest
		qdel(oldest)

/datum/social_bond/proc/attach_event(event_type)
	if(!scored)
		return null
	var/datum/bond_event/prototype = SSbonds.get_event_prototype(event_type)
	if(!prototype)
		return null
	LAZYINITLIST(active_events)
	var/category = prototype.category
	var/datum/bond_event/existing = active_events[category]
	var/scale = 0
	if(existing && existing.type == event_type)
		existing.refresh()
	else
		if(existing)
			existing.bond = null
			qdel(existing)
		var/datum/bond_event/event = new event_type()
		event.bond = src
		active_events[category] = event
		event.start()
	if(can_commit(category))
		scale = commit(prototype)
	if(prototype.tag_applied != BOND_TAG_NONE)
		tags |= prototype.tag_applied
	add_history(prototype, scale)
	recalculate()
	return active_events[category]

/datum/social_bond/proc/detach_event(datum/bond_event/event)
	if(!active_events || !event)
		return FALSE
	if(active_events[event.category] != event)
		return FALSE
	active_events -= event.category
	recalculate()
	return TRUE
