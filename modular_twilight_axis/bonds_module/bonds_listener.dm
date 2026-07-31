/mob/living/carbon/human
	var/tmp/bonds_signals_bound = FALSE
	var/tmp/datum/mind/bonds_last_aggressor
	var/tmp/bonds_last_aggression_time = 0

/datum/controller/subsystem/bonds/proc/on_mob_created(datum/source, mob/new_mob)
	SIGNAL_HANDLER
	if(!ishuman(new_mob))
		return
	if(istype(new_mob, /mob/living/carbon/human/dummy))
		return
	register_human(new_mob)

/datum/controller/subsystem/bonds/proc/register_human(mob/living/carbon/human/person)
	if(!person || person.bonds_signals_bound)
		return FALSE
	person.bonds_signals_bound = TRUE
	RegisterSignal(person, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack), override = TRUE)
	RegisterSignal(person, COMSIG_MOB_ATTACKED_BY_HAND, PROC_REF(on_attacked_by_hand), override = TRUE)
	RegisterSignal(person, COMSIG_MOB_HUGGED, PROC_REF(on_hugged), override = TRUE)
	RegisterSignal(person, COMSIG_MOB_DEATH, PROC_REF(on_death), override = TRUE)
	RegisterSignal(person, COMSIG_PARENT_QDELETING, PROC_REF(on_human_qdeleting), override = TRUE)
	return TRUE

/datum/controller/subsystem/bonds/proc/unregister_human(mob/living/carbon/human/person)
	if(!person || !person.bonds_signals_bound)
		return FALSE
	person.bonds_signals_bound = FALSE
	person.bonds_last_aggressor = null
	UnregisterSignal(person, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_ATTACKED_BY_HAND,
		COMSIG_MOB_HUGGED,
		COMSIG_MOB_DEATH,
		COMSIG_PARENT_QDELETING,
	))
	return TRUE

/datum/controller/subsystem/bonds/proc/on_human_qdeleting(datum/source)
	SIGNAL_HANDLER
	unregister_human(source)

/datum/controller/subsystem/bonds/proc/on_item_attack(datum/source, mob/living/target, mob/living/attacker, obj/item/weapon)
	SIGNAL_HANDLER
	record_pair(attacker, target, /datum/bond_event/struck_them, /datum/bond_event/struck_by)
	mark_aggressor(attacker, target)

/datum/controller/subsystem/bonds/proc/on_attacked_by_hand(datum/source, mob/living/attacker, mob/living/target)
	SIGNAL_HANDLER
	record_pair(attacker, target, /datum/bond_event/beat_them, /datum/bond_event/beaten_by)
	mark_aggressor(attacker, target)

/datum/controller/subsystem/bonds/proc/on_hugged(datum/source, mob/living/target)
	SIGNAL_HANDLER
	record_pair(source, target, /datum/bond_event/embraced_them, /datum/bond_event/embraced_by)

/datum/controller/subsystem/bonds/proc/on_death(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/victim = source
	if(!ishuman(victim))
		return
	var/datum/mind/killer_mind = victim.bonds_last_aggressor
	victim.bonds_last_aggressor = null
	if(!killer_mind)
		return
	if((world.time - victim.bonds_last_aggression_time) > BOND_KILL_ATTRIBUTION_WINDOW)
		return
	var/mob/living/carbon/human/killer = killer_mind.current
	if(!ishuman(killer) || killer == victim)
		return
	record_pair(killer, victim, /datum/bond_event/killed_them, /datum/bond_event/killed_by)

/datum/controller/subsystem/bonds/proc/mark_aggressor(mob/living/carbon/human/attacker, mob/living/carbon/human/target)
	if(!ishuman(attacker) || !ishuman(target) || attacker == target)
		return
	if(!attacker.mind)
		return
	target.bonds_last_aggressor = attacker.mind
	target.bonds_last_aggression_time = world.time

/datum/controller/subsystem/bonds/proc/record_pair(mob/living/carbon/human/actor, mob/living/carbon/human/subject, actor_event, subject_event)
	if(!ishuman(actor) || !ishuman(subject) || actor == subject)
		return
	var/datum/mind/actor_mind = bonds_mind_of(actor)
	var/datum/mind/subject_mind = bonds_mind_of(subject)
	if(!actor_mind || !subject_mind)
		return
	var/datum/bond_event/prototype = get_event_prototype(subject_event)
	var/hostile = prototype && (prototype.category == BOND_CATEGORY_VIOLENCE || prototype.category == BOND_CATEGORY_DEATH)
	// A sanctioned duel is not an assault. It must not sour either side, nor move factions.
	if(hostile && is_sanctioned_duel(actor, subject))
		return

	var/subject_scale = disposition_scale(subject, subject_event)
	record(actor_mind, subject_mind, actor_event, subject)
	record(subject_mind, actor_mind, subject_event, actor, FALSE, subject_scale)
	social_impact(subject_mind, actor_mind, subject_event, subject_scale)
