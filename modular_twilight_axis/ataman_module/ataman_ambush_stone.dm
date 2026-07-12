/obj/structure/trap/ataman_ambush_stone
	name = "stone"
	desc = "A piece of rough ground stone."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "stone1"
	charges = 1
	time_between_triggers = 0
	checks_antimagic = FALSE
	var/datum/weakref/placed_by_ref
	var/list/bandit_types = list(/mob/living/carbon/human/npc/ataman_bandit)
	var/being_removed = FALSE

/obj/structure/trap/ataman_ambush_stone/proc/set_placer(mob/living/carbon/human/placer)
	if(!placer)
		return
	placed_by_ref = WEAKREF(placer)
	if(placer.mind)
		immune_minds += placer.mind
	ataman_register_ambush(placer, src)

/obj/structure/trap/ataman_ambush_stone/proc/disguise_as_prop(new_name, new_desc, new_icon, new_icon_state)
	name = new_name
	desc = new_desc
	icon = new_icon
	icon_state = new_icon_state

/obj/structure/trap/ataman_ambush_stone/flare()
	alpha = 200
	last_trigger = world.time
	charges--
	animate(src, alpha = 0, time = 2)
	QDEL_IN(src, 2)

// Ataman traps are found by mob/living/look_around(); examining them never reveals them.
/obj/structure/trap/ataman_ambush_stone/examine(mob/user)
	return

/obj/structure/trap/ataman_ambush_stone/attack_hand(mob/user)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(user == placer)
		begin_owner_removal(placer)
		return TRUE
	return ..()

/obj/structure/trap/ataman_ambush_stone/attackby(obj/item/I, mob/user, params)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(user == placer)
		begin_owner_removal(placer)
		return TRUE
	return ..()

/obj/structure/trap/ataman_ambush_stone/proc/begin_owner_removal(mob/living/carbon/human/placer)
	if(being_removed || QDELETED(src))
		return
	being_removed = TRUE
	placer.visible_message(
		span_notice("[placer] begins dismantling something hidden on the ground."),
		span_notice("I begin dismantling my ambush."),
	)
	if(do_after(placer, 5 SECONDS, target = src) && !QDELETED(src))
		to_chat(placer, span_notice("I dismantle my ambush."))
		qdel(src)
		return
	being_removed = FALSE

/obj/structure/trap/ataman_ambush_stone/trap_effect(mob/living/L)
	spring_ambush(L)

/obj/structure/trap/ataman_ambush_stone/proc/is_valid_ambush_spawn(turf/candidate, turf/spawn_center, list/used_turfs, exact_distance)
	if(!isopenturf(candidate) || candidate == spawn_center || candidate in used_turfs)
		return FALSE
	if(istype(candidate, /turf/open/transparent/openspace) || candidate.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	if(exact_distance && get_dist(candidate, spawn_center) != exact_distance)
		return FALSE
	var/distance = get_dist(candidate, spawn_center)
	return distance >= 1 && distance <= 5

/obj/structure/trap/ataman_ambush_stone/proc/pick_ambush_spawn(turf/spawn_center, list/used_turfs)
	var/desired_distance = rand(1, 5)
	var/list/candidates = list()
	for(var/turf/candidate as anything in RANGE_TURFS(5, spawn_center))
		if(is_valid_ambush_spawn(candidate, spawn_center, used_turfs, desired_distance))
			candidates += candidate
	if(!length(candidates))
		for(var/turf/candidate as anything in RANGE_TURFS(5, spawn_center))
			if(is_valid_ambush_spawn(candidate, spawn_center, used_turfs, 0))
				candidates += candidate
	if(!length(candidates))
		return null
	return pick(candidates)

/obj/structure/trap/ataman_ambush_stone/proc/spring_ambush(mob/living/trigger)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	var/turf/spawn_center = get_turf(src)
	if(!spawn_center || !isliving(trigger))
		return

	var/datum/ataman_squad/squad = new
	squad.target_ref = WEAKREF(trigger)
	squad.gear_tier = placer ? clamp(max(placer.ataman_loot_tier, 1), 1, 5) : 1

	var/list/squad_size_range = ataman_squad_size_for_tier(placer?.ataman_loot_tier || 0)
	var/list/used_spawn_turfs = list()
	var/amount = rand(squad_size_range[1], squad_size_range[2])
	var/grabber_count = amount >= 4 ? 2 : 1
	ataman_ai_log(placer, "AMBUSH: springing on [trigger] at [spawn_center] - size=[amount] (range [squad_size_range[1]]-[squad_size_range[2]]) gear_tier=[squad.gear_tier] grabbers=[grabber_count]")
	for(var/i in 1 to amount)
		var/turf/spawn_location = pick_ambush_spawn(spawn_center, used_spawn_turfs)
		if(!spawn_location)
			break
		used_spawn_turfs += spawn_location
		var/mob_type = pick(bandit_types)
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = new mob_type(spawn_location)
		var/role = i <= grabber_count ? ATAMAN_ROLE_GRABBER : (i == grabber_count + 1 ? ATAMAN_ROLE_BINDER : ATAMAN_ROLE_ENFORCER)
		bandit.set_ataman(placer, spawn_center, trigger, role, squad)

	if(placer)
		to_chat(placer, span_notice("My ambush springs on [trigger]!"))
