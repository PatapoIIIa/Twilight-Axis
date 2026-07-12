#define ATAMAN_DEATH_MARK_WINDOW 15
#define ATAMAN_DEATH_MARK_MAX_WITNESSES 6
#define ATAMAN_DEATH_MARK_BOUNTY 300

SUBSYSTEM_DEF(ataman_deathmark)
	name = "Ataman Death Mark"
	flags = SS_NO_FIRE

/datum/controller/subsystem/ataman_deathmark/Initialize()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		register_human(H)
	return ..()

/datum/controller/subsystem/ataman_deathmark/proc/on_mob_created(datum/source, mob/new_mob)
	SIGNAL_HANDLER
	if(!ishuman(new_mob))
		return
	register_human(new_mob)

/datum/controller/subsystem/ataman_deathmark/proc/register_human(mob/living/carbon/human/H)
	if(!H || H.ataman_deathmark_bound)
		return
	H.ataman_deathmark_bound = TRUE
	RegisterSignal(H, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damaged))
	RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/controller/subsystem/ataman_deathmark/proc/on_damaged(mob/living/carbon/human/victim, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	var/mob/living/attacker = victim.lastattacker_weakref?.resolve()
	if(!attacker || attacker == victim)
		return
	victim.recent_attackers += WEAKREF(attacker)
	var/excess = length(victim.recent_attackers) - ATAMAN_DEATH_MARK_WINDOW
	if(excess > 0)
		victim.recent_attackers.Cut(1, excess + 1)

/datum/controller/subsystem/ataman_deathmark/proc/on_death(mob/living/carbon/human/victim, gibbed)
	SIGNAL_HANDLER
	check_ataman_death_mark(victim)
	victim.recent_attackers = list()

/proc/ataman_resolve_source(mob/living/attacker)
	if(!istype(attacker))
		return null
	if(istype(attacker, /mob/living/carbon/human/npc/ataman_bandit))
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = attacker
		return bandit.ataman_owner_ref?.resolve()
	return attacker

/proc/check_ataman_death_mark(mob/living/carbon/human/victim)
	if(!victim?.client || !length(victim.recent_attackers))
		return

	var/mob/living/carbon/human/culprit
	for(var/datum/weakref/ref as anything in victim.recent_attackers)
		var/mob/living/carbon/human/source = ataman_resolve_source(ref?.resolve())
		if(istype(source) && source.client && source.mind && source.advjob == "Атаман")
			culprit = source
			break

	if(!culprit?.client)
		return

	var/nearby_players = 0
	for(var/mob/living/witness in view(5, victim))
		if(!witness.client)
			continue
		nearby_players++
		if(nearby_players > ATAMAN_DEATH_MARK_MAX_WITNESSES)
			return

	var/list/d_list = culprit.get_mob_descriptors()
	var/descriptor_height = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_HEIGHT), "%DESC1%")
	var/descriptor_body = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_BODY), "%DESC1%")
	var/descriptor_voice = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_VOICE), "%DESC1%")

	var/datum/bounty/bounty = ataman_find_bounty(culprit, ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_MURDER)
	if(bounty)
		bounty.ataman_victim_names += victim.real_name
		bounty.amount += ATAMAN_DEATH_MARK_BOUNTY
		bounty.reason = "Murder: [jointext(bounty.ataman_victim_names, ", ")]"
		bounty.banner = null
		compose_bounty(bounty)
	else
		bounty = ataman_create_bounty(culprit, ATAMAN_DEATH_MARK_BOUNTY, "Murder: [victim.real_name]", ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_MURDER, culprit.dna.species, culprit.gender, descriptor_height, descriptor_body, descriptor_voice)
		bounty.ataman_victim_names = list(victim.real_name)

	to_chat(culprit, span_danger("За мою голову назначена награда. Кто-то узнал о том, что я убил [victim.real_name]!"))

#undef ATAMAN_DEATH_MARK_WINDOW
#undef ATAMAN_DEATH_MARK_MAX_WITNESSES
#undef ATAMAN_DEATH_MARK_BOUNTY
