/obj/structure/trap/ataman_ambush_stone
	name = "a stone"
	desc = "An unremarkable stone."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "basalt"
	alpha = 0
	charges = 1
	time_between_triggers = 0
	checks_antimagic = FALSE
	var/datum/weakref/placed_by_ref
	var/bandit_min = 3
	var/bandit_max = 6
	var/list/bandit_types = list(/mob/living/carbon/human/npc/ataman_bandit)

/obj/structure/trap/ataman_ambush_stone/proc/set_placer(mob/living/carbon/human/placer)
	if(!placer)
		return
	placed_by_ref = WEAKREF(placer)
	if(placer.mind)
		immune_minds += placer.mind

/obj/structure/trap/ataman_ambush_stone/proc/disguise_as(obj/item/model)
	if(!model)
		return
	icon = model.icon
	icon_state = model.icon_state
	name = model.name
	desc = model.desc

/obj/structure/trap/ataman_ambush_stone/flare()
	alpha = 200
	last_trigger = world.time
	charges--
	animate(src, alpha = 0, time = 2)
	QDEL_IN(src, 2)

/obj/structure/trap/ataman_ambush_stone/examine(mob/user)
	if(!isliving(user) || !armed)
		return
	var/mob/living/luser = user
	if(user.mind && (user.mind in immune_minds))
		return
	if(luser.STAPER > 16 && prob(50))
		to_chat(user, span_notice("Something about [src] feels wrong..."))
		flare()
		return
	var/tracking_level = luser.get_skill_level(/datum/skill/misc/tracking)
	if(tracking_level > 0 && prob(10 + 10 * tracking_level))
		to_chat(user, span_notice("My tracking instincts spot [src] for what it truly is!"))
		flare()

/obj/structure/trap/ataman_ambush_stone/trap_effect(mob/living/L)
	spring_ambush(L)

/obj/structure/trap/ataman_ambush_stone/proc/spring_ambush(mob/living/trigger)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	var/turf/spawn_center = get_turf(src)
	if(!spawn_center)
		return
	var/list/spawn_turfs = get_adjacent_ambush_turfs(spawn_center)
	if(!length(spawn_turfs))
		spawn_turfs = list(spawn_center)

	var/amount = rand(bandit_min, bandit_max)
	for(var/i in 1 to amount)
		var/turf/spawnloc = pick(spawn_turfs)
		var/mob_type = pick(bandit_types)
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = new mob_type(spawnloc)
		bandit.set_ataman(placer, spawn_center)

	if(placer)
		to_chat(placer, span_notice("My ambush springs on [trigger]!"))
